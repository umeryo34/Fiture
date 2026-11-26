"""天使・悪魔キャラクターの3Dモデルとアニメーションを作る Blender スクリプト。

使い方:
  Blender -b --factory-startup --python build_character.py -- angel|devil 出力フォルダ [preview]

座標は元イラスト(1493x2000px)から P(x, y) で変換する。1000px = 1、正面は -Y。
"""
import bpy, sys, os, math
import numpy as np
from mathutils import Vector, Quaternion, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
KIND, OUT = argv[0], argv[1]
PREVIEW = "preview" in argv
ANGEL = KIND == "angel"
HERE = os.path.dirname(os.path.abspath(__file__))
NAME = "Angel" if ANGEL else "Devil"
ART = os.path.join(HERE, "art", f"Character{NAME}.png")
FPS = 30
OUTLINE = 0.0075

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = FPS
os.makedirs(OUT, exist_ok=True)


def X(x): return (x - 752) / 1000
def Z(y): return (1605 - y) / 1000
def P(x, y, d=0.0): return (X(x), d, Z(y))


# ---------- 色・テクスチャ ----------
def lin(c):
    out = []
    for v in c:
        v = v / 255
        out.append(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4)
    return (*out, 1)


def material(name, rgb=None, image=None, rough=0.7, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.use_backface_culling = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if image:
        t = m.node_tree.nodes.new("ShaderNodeTexImage")
        t.image = image
        m.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
    else:
        b.inputs["Base Color"].default_value = lin(rgb)
        m.diffuse_color = lin(rgb)
    return m


art = bpy.data.images.load(os.path.abspath(ART))
AW, AH = art.size
_buf = np.empty(AW * AH * 4, dtype=np.float32)
art.pixels.foreach_get(_buf)
ART_PX = _buf.reshape(AH, AW, 4)[::-1]          # 上が0行目
SC = AW / 1416


def sample(xs, ys):
    """元イラスト座標の配列を双線形で読む"""
    ix = np.clip((xs - 40) * SC, 0, AW - 1.001)
    iy = np.clip((ys - 255) * SC, 0, AH - 1.001)
    x0, y0 = ix.astype(int), iy.astype(int)
    fx, fy = (ix - x0)[..., None], (iy - y0)[..., None]
    a = ART_PX
    return (a[y0, x0] * (1 - fx) * (1 - fy) + a[y0, x0 + 1] * fx * (1 - fy)
            + a[y0 + 1, x0] * (1 - fx) * fy + a[y0 + 1, x0 + 1] * fx * fy)


def make_image(name, arr):
    h, w = arr.shape[:2]
    if arr.shape[2] == 3:
        arr = np.dstack([arr, np.ones((h, w))])
    img = bpy.data.images.new(name, w, h, alpha=False)
    img.pixels.foreach_set(arr[::-1].astype(np.float32).ravel())
    img.filepath_raw = os.path.join(OUT, f"{NAME}_{name}.png")
    img.file_format = "PNG"
    img.save()
    return img


HX0, HX1, HY0, HY1 = 400, 1104, 440, 1060        # 頭テクスチャの範囲


def head_images():
    n = 1024
    xs, ys = np.meshgrid(np.linspace(HX0, HX1, n), np.linspace(HY0, HY1, n))
    if ANGEL:
        top, bottom = np.array([255, 222, 212]) / 255, np.array([250, 186, 182]) / 255
    else:
        top, bottom = np.array([205, 146, 152]) / 255, np.array([236, 150, 152]) / 255
    t = np.clip((ys - 600) / 380, 0, 1)[..., None]
    base = top * (1 - t) + bottom * t
    src = sample(xs, ys)[..., :3]
    r = np.sqrt(((xs - 735) / 312) ** 2 + ((ys - 785) / 205) ** 2)
    mask = np.clip((1 - r) / 0.25, 0, 1)
    mask = (mask * mask * (3 - 2 * mask))[..., None]
    face = base * (1 - mask) + src * mask
    return make_image("face", face), make_image("skin", base[::8, ::8])


def crop_image(name, x0, x1, y0, y1, w, h):
    xs, ys = np.meshgrid(np.linspace(x0, x1, w), np.linspace(y0, y1, h))
    return make_image(name, sample(xs, ys)[..., :3])


SKIN_RGB = (251, 190, 183) if ANGEL else (222, 138, 143)
M = {
    "skin": material("Skin", SKIN_RGB),
    "line": material("Line", (74, 36, 30) if ANGEL else (44, 16, 18), rough=1.0),
}
face_img, skin_img = head_images()
M["face"] = material("Face", image=face_img)
M["headback"] = material("HeadBack", image=skin_img)
PARTS = []                                       # (object, bone)


# ---------- 形を作る関数 ----------
def new_obj(name, verts, faces, mats, face_mat=None, smooth=True):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    for m in mats:
        me.materials.append(m)
    for i, p in enumerate(me.polygons):
        p.use_smooth = smooth
        if face_mat:
            p.material_index = face_mat[i]
    me.uv_layers.new(name="UVMap")
    me.update()
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    return o


def recalc(o):
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(o.data)
    bm.free()
    o.data.update()


def add(o, bone, outline=OUTLINE):
    """輪郭線(反転した外殻)を付けて部品登録"""
    recalc(o)
    if outline:
        me = o.data
        n = len(me.vertices)
        # 同位置の頂点の法線で外側に膨らませる
        vs = [tuple(v.co + v.normal * outline) for v in me.vertices]
        fs = [tuple(reversed(p.vertices)) for p in me.polygons]
        h = new_obj(o.name + "_line", vs, fs, [M["line"]])
        PARTS.append((h, bone))
    PARTS.append((o, bone))
    return o


def smooth_path(pts, n):
    """Catmull-Rom。pts は任意次元"""
    p = np.array(pts, float)
    p = np.vstack([2 * p[0] - p[1], p, 2 * p[-1] - p[-2]])
    out = []
    seg = len(p) - 3
    for k in range(n):
        u = k / (n - 1) * seg
        i = min(int(u), seg - 1)
        t = u - i
        a, b, c, d = p[i], p[i + 1], p[i + 2], p[i + 3]
        out.append(0.5 * ((2 * b) + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t * t
                          + (3 * b - a - 3 * c + d) * t ** 3))
    return np.array(out)


def lathe(name, rows, depth, mats, cx=752, seg=32, n=22):
    """(y, 半幅) の輪郭から回転体"""
    ys = np.array([r[0] for r in rows], float)
    ws = np.array([r[1] for r in rows], float)
    # 極付近を細かく: 円弧状の補間
    q = smooth_path(list(zip(ys, ws)), n)
    verts, faces = [], []
    verts.append((X(cx), 0, Z(q[0][0])))
    for yy, ww in q[1:-1]:
        ww = max(ww, 4) / 1000
        for s in range(seg):
            a = 2 * math.pi * s / seg
            verts.append((X(cx) + ww * math.sin(a), -ww * depth * math.cos(a), Z(yy)))
    verts.append((X(cx), 0, Z(q[-1][0])))
    R = n - 2
    for s in range(seg):
        faces.append((0, 1 + s, 1 + (s + 1) % seg))
    for r in range(R - 1):
        for s in range(seg):
            a, b = 1 + r * seg + s, 1 + r * seg + (s + 1) % seg
            faces.append((a, a + seg, b + seg, b))
    last = len(verts) - 1
    for s in range(seg):
        faces.append((last, 1 + (R - 1) * seg + (s + 1) % seg, 1 + (R - 1) * seg + s))
    return new_obj(name, verts, faces, mats)


def tube(name, pts, radii, mat, n=12, seg=10, flat=1.0):
    """丸い端の管。flat<1 で前後に平たくする"""
    path = smooth_path([(*p, r) for p, r in zip(pts, radii)], n)
    centers = [Vector(p[:3]) for p in path]
    rs = [max(p[3], 0.0015) for p in path]
    tang = [(centers[min(i + 1, n - 1)] - centers[max(i - 1, 0)]).normalized() for i in range(n)]
    rings = []
    # 端を半球にする
    for k in range(4):
        a = math.pi / 2 * k / 4
        rings.append((centers[0] - tang[0] * rs[0] * math.cos(a), rs[0] * math.sin(a) + 1e-4, tang[0]))
    rings += list(zip(centers, rs, tang))
    for k in range(1, 5):
        a = math.pi / 2 * k / 4
        rings.append((centers[-1] + tang[-1] * rs[-1] * math.sin(a), rs[-1] * math.cos(a) + 1e-4, tang[-1]))
    verts, faces = [], []
    ref = Vector((0, 1, 0))
    if abs(tang[0].dot(ref)) > 0.9:
        ref = Vector((1, 0, 0))
    for c, r, t in rings:
        u = (ref - t * ref.dot(t)).normalized()
        ref = u
        v = t.cross(u)
        for s in range(seg):
            a = 2 * math.pi * s / seg
            verts.append(tuple(c + u * (r * flat * math.cos(a)) + v * (r * math.sin(a))))
    for i in range(len(rings) - 1):
        for s in range(seg):
            a, b = i * seg + s, i * seg + (s + 1) % seg
            faces.append((a, b, b + seg, a + seg))
    faces.append(tuple(reversed(range(seg))))
    faces.append(tuple(range((len(rings) - 1) * seg, len(rings) * seg)))
    return new_obj(name, verts, faces, [mat])


def puffy(name, poly, mat, d, thick, shear):
    """押し出した輪郭をボクセル化してなめらかにし、軽量化する（尖った凹みでも線が乱れない）"""
    n = len(poly)
    vs = [(a, d - thick / 2, b) for a, b in poly] + [(a, d + thick / 2, b) for a, b in poly]
    fs = [tuple(range(n)), tuple(reversed(range(n, 2 * n)))] + [(i, n + i, n + (i + 1) % n, (i + 1) % n) for i in range(n)]
    o = new_obj(name, vs, fs, [mat])
    recalc(o)
    bpy.context.view_layer.objects.active = o
    for m in bpy.data.objects:
        m.select_set(m == o)
    t = o.modifiers.new("t", "TRIANGULATE"); t.ngon_method = "CLIP"
    rm = o.modifiers.new("r", "REMESH"); rm.mode = "VOXEL"; rm.voxel_size = .006
    sm = o.modifiers.new("s", "SMOOTH"); sm.factor = .5; sm.iterations = 6
    dc = o.modifiers.new("d", "DECIMATE"); dc.ratio = .08
    for m in ("t", "r", "s", "d"):
        bpy.ops.object.modifier_apply(modifier=m)
    for v in o.data.vertices:
        v.co.y += shear * max(0, abs(v.co.x) - .2)
    for q in o.data.polygons:
        q.use_smooth = True
    o.data.materials.clear(); o.data.materials.append(mat)
    if not o.data.uv_layers:
        o.data.uv_layers.new(name="UVMap")
    return o


def slab(name, pts, mat, d, thick=0.02, bevel=0.012, smooth=True, shear=0.0, samples=None):
    """輪郭(px)を押し出した板。d は奥行き、shear は外側ほど後ろへ倒す量"""
    poly = [(X(x), Z(y)) for x, y in pts]
    if smooth:
        closed = [poly[-1]] + poly + [poly[0], poly[1]]
        m = samples or len(poly) * 5
        arr, seg = [], len(poly)
        p = np.array(closed)
        for k in range(m):
            u = k / m * seg
            i = int(u); t = u - i
            a, b, c, e = p[i], p[i + 1], p[i + 2], p[(i + 3) if i + 3 < len(p) else -1]
            arr.append(0.5 * ((2 * b) + (c - a) * t + (2 * a - 5 * b + 4 * c - e) * t * t
                              + (3 * b - a - 3 * c + e) * t ** 3))
        poly = [tuple(v) for v in arr]
    cu = bpy.data.curves.new(name, "CURVE")
    if smooth:
        return puffy(name, poly, mat, d, thick + 2 * bevel, shear)
    cu.dimensions = "2D"; cu.fill_mode = "BOTH"
    cu.extrude = thick / 2; cu.bevel_depth = bevel; cu.bevel_resolution = 1; cu.offset = -bevel * 0.8
    sp = cu.splines.new("POLY")
    sp.points.add(len(poly) - 1)
    for pt, (a, b) in zip(sp.points, poly):
        pt.co = (a, b, 0, 1)
    sp.use_cyclic_u = True
    tmp = bpy.data.objects.new(name, cu)
    scene.collection.objects.link(tmp)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
    bpy.data.objects.remove(tmp)
    verts = []
    for v in me.vertices:
        x, z, y = v.co.x, v.co.y, v.co.z
        verts.append((x, d - y + shear * max(0, abs(x) - 0.2), z))
    faces = [tuple(p.vertices) for p in me.polygons]
    return new_obj(name, verts, faces, [mat], smooth=True)


def ellipse_pts(cx, cy, rx, ry, deg, n=12):
    a = math.radians(deg)
    return [(cx + rx * math.cos(t) * math.cos(a) - ry * math.sin(t) * math.sin(a),
             cy + rx * math.cos(t) * math.sin(a) + ry * math.sin(t) * math.cos(a))
            for t in np.linspace(0, 2 * math.pi, n, endpoint=False)]


def torus(name, center, rx, ry, minor, mats, seg=40, ring=8, tilt=0.0, minor_z=None, pick=None):
    verts, faces, fm = [], [], []
    c = Vector(center)
    rot = Matrix.Rotation(tilt, 4, "X")
    for s in range(seg):
        a = 2 * math.pi * s / seg
        for k in range(ring):
            b = 2 * math.pi * k / ring
            p = Vector((math.cos(a) * (rx + minor * math.cos(b)), math.sin(a) * (ry + minor * math.cos(b)),
                        (minor_z or minor) * math.sin(b)))
            verts.append(tuple(c + rot @ p))
    for s in range(seg):
        for k in range(ring):
            s2, k2 = (s + 1) % seg, (k + 1) % ring
            faces.append((s * ring + k, s2 * ring + k, s2 * ring + k2, s * ring + k2))
            fm.append(pick(s / seg) if pick else 0)
    return new_obj(name, verts, faces, mats, fm)


def ball(name, c, r, mat, seg=16):
    sx, sy, sz = r if isinstance(r, tuple) else (r, r, r)
    verts, faces = [], []
    rows = seg // 2
    for i in range(rows + 1):
        t = math.pi * i / rows
        for s in range(seg):
            a = 2 * math.pi * s / seg
            verts.append((c[0] + sx * math.sin(t) * math.cos(a), c[1] + sy * math.sin(t) * math.sin(a), c[2] + sz * math.cos(t)))
    for i in range(rows):
        for s in range(seg):
            a, b = i * seg + s, i * seg + (s + 1) % seg
            faces.append((a, a + seg, b + seg, b))
    return new_obj(name, verts, faces, [mat])


def rounded_rect(cx, cy, w, h, r, deg=0, k=6):
    a0 = math.radians(deg)
    pts = []
    for (sx, sy, st) in [(1, -1, -90), (1, 1, 0), (-1, 1, 90), (-1, -1, 180)]:
        for i in range(k):
            t = math.radians(st + 90 * i / (k - 1))
            x = sx * (w / 2 - r) + r * math.cos(t)
            y = sy * (h / 2 - r) + r * math.sin(t)
            pts.append((cx + x * math.cos(a0) - y * math.sin(a0), cy + x * math.sin(a0) + y * math.cos(a0)))
    return pts


def decal(name, pts, mat, d, tex_rect, deg=0):
    """板の前に貼る絵。pts は輪郭(px)、tex_rect は (cx, cy, w, h)"""
    verts = [(X(x), d, Z(y)) for x, y in pts]
    back = [(X(x), d + 0.004, Z(y)) for x, y in pts]
    n = len(pts)
    faces = [tuple(range(n)), tuple(reversed(range(n, 2 * n)))]
    faces += [(i, (i + 1) % n + 0, n + (i + 1) % n, n + i) for i in range(n)]
    o = new_obj(name, verts + back, faces, [mat], smooth=False)
    recalc(o)
    cx, cy, w, h = tex_rect
    a0 = math.radians(deg)
    uv = o.data.uv_layers[0].data
    for lp in o.data.loops:
        v = o.data.vertices[lp.vertex_index].co
        dx, dy = v.x * 1000 + 752 - cx, 1605 - v.z * 1000 - cy
        u = (dx * math.cos(a0) + dy * math.sin(a0)) / w + 0.5
        t = (-dx * math.sin(a0) + dy * math.cos(a0)) / h + 0.5
        uv[lp.index].uv = (u, 1 - t)
    return o


# ---------- 頭・体 ----------
head = lathe("Head", [(466, 0), (474, 85), (500, 160), (550, 222), (600, 265), (650, 293), (700, 312),
                      (750, 323), (800, 329), (850, 330), (900, 318), (950, 283), (1000, 210), (1028, 110), (1036, 0)],
             0.86, [M["face"], M["headback"]], cx=750, seg=40, n=28)
recalc(head)
for p in head.data.polygons:
    p.material_index = 0 if p.center.y < 0 else 1
uv = head.data.uv_layers[0].data
for lp in head.data.loops:
    v = head.data.vertices[lp.vertex_index].co
    uv[lp.index].uv = ((v.x * 1000 + 752 - HX0) / (HX1 - HX0), 1 - (1605 - v.z * 1000 - HY0) / (HY1 - HY0))
add(head, "head")

add(lathe("Body", [(985, 0), (992, 90), (1010, 150), (1050, 200), (1100, 224), (1200, 246), (1300, 257), (1350, 258),
                   (1395, 250), (1435, 228), (1468, 185), (1490, 110), (1497, 0)],
          0.82, [M["skin"]], cx=756, n=22), "body")
for s, b in ((-1, "legR"), (1, "legL")):
    add(tube("Leg" + b, [(s * .135, .0, .27), (s * .125, -.005, .15), (s * .115, -.012, .062)],
             [.112, .098, .072], M["skin"]), b)

# 腕（画面右 = L、画面左 = R）。元イラストのポーズを基準姿勢にする
if ANGEL:
    armL = [P(965, 1115, -.02), P(1085, 1045, -.06), P(1150, 945, -.09)]
else:
    armL = [P(960, 1100, -.02), P(1060, 1105, -.08), P(1135, 1062, -.12)]
armR = [P(545, 1125, -.02), P(440, 1175, -.10), P(365, 1140, -.15)]
add(tube("ArmL", armL, [.062, .06, .052], M["skin"]), "armL")
add(ball("HandL", armL[-1], .062, M["skin"]), "armL")
add(tube("ArmR", armR, [.062, .06, .052], M["skin"]), "armR")
add(ball("HandR", armR[-1], .06, M["skin"]), "armR")

# ---------- 双葉 ----------
leaf_rgb = (138, 178, 58) if ANGEL else (176, 38, 42)
M["leaf"] = material("Leaf", leaf_rgb, rough=.45)
M["stem"] = material("Stem", (122, 142, 52) if ANGEL else (128, 26, 30))
add(tube("Stem", [P(760, 490), P(768, 440), P(770, 375)], [.017, .013, .011], M["stem"], n=10, seg=12), "sprout")
leafL = [(768, 385), (752, 330), (705, 285), (650, 270), (608, 275), (618, 325), (650, 372), (695, 400), (740, 398)]
leafR = [(772, 385), (810, 325), (865, 300), (915, 308), (952, 330), (928, 378), (880, 410), (828, 412), (792, 400)]
for i, pts in enumerate((leafL, leafR)):
    add(slab(f"Leaf{i}", pts, M["leaf"], 0.0, thick=.012, bevel=.016), "sprout")

# ---------- お腹の画面 ----------
TR = (728, 1277, 340, 224)
M["tabletframe"] = material("TabletFrame", (205, 92, 58) if ANGEL else (206, 34, 34), rough=.4)
M["screen"] = material("Screen", image=crop_image("screen", 574, 866, 1180, 1372, 768, 512), rough=.35)
add(slab("Tablet", rounded_rect(734, 1277, 352, 236, 26), M["tabletframe"], -.196, thick=.03, bevel=.012, smooth=False), "body")
d0 = -.196 - .015 - .012 - .004
add(decal("Screen", rounded_rect(716, 1277, 292, 192, 12), M["screen"], d0, (720, 1276, 292, 192)), "body", outline=0)
M["button"] = material("Button", (120, 44, 30) if ANGEL else (110, 10, 14))
add(ball("TabletButton", P(886, 1283, -.222), (.011, .006, .011), M["button"], 12), "body", outline=0)

# ---------- メモ帳（画面左手） ----------
def note_image():
    w, h = 384, 512
    if ANGEL:
        a = np.ones((h, w, 3)) * np.array([255, 252, 247]) / 255
    else:
        a = np.ones((h, w, 3)) * np.array([52, 50, 52]) / 255
    return a

def text_mesh(body, size, mat, cx, cy, d, deg, font=None):
    cu = bpy.data.curves.new("txt", "FONT")
    cu.body = body; cu.size = size; cu.align_x = "CENTER"; cu.align_y = "CENTER"
    cu.extrude = .0015; cu.offset = .0022; cu.resolution_u = 1
    if font and os.path.exists(font):
        cu.font = bpy.data.fonts.load(font)
    tmp = bpy.data.objects.new("txt", cu)
    scene.collection.objects.link(tmp)
    me = bpy.data.meshes.new_from_object(tmp.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    bpy.data.objects.remove(tmp)
    a = math.radians(-deg)
    vs = []
    for v in me.vertices:
        x, y = v.co.x, v.co.y
        vs.append((X(cx) + x * math.cos(a) - y * math.sin(a), d - v.co.z, Z(cy) + x * math.sin(a) + y * math.cos(a)))
    return new_obj("Text", vs, [tuple(p.vertices) for p in me.polygons], [mat], smooth=False)

FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"
ND, NDEG = -.225, -24
M["note"] = material("Note", (255, 252, 247) if ANGEL else (50, 47, 50))
M["notetext"] = material("NoteText", (140, 56, 46) if ANGEL else (240, 190, 192))
M["ring"] = material("Ring", (90, 36, 34) if ANGEL else (40, 12, 16))
NC = (398, 1062)
add(slab("Note", rounded_rect(*NC, 158, 212, 10, NDEG), M["note"], ND, thick=.026, bevel=.005, smooth=False), "armR")
ca, sa = math.cos(math.radians(NDEG)), math.sin(math.radians(NDEG))
def on_note(dx, dy): return (NC[0] + dx * ca - dy * sa, NC[1] + dx * sa + dy * ca)
tz = ND - .013 - .005 - .001
if ANGEL:
    add(text_mesh("Good\njob!", .050, M["notetext"], *on_note(4, -42), tz, NDEG, FONT), "armR", outline=0)
else:
    add(text_mesh("Oops...!", .041, M["notetext"], *on_note(2, -35), tz, NDEG, FONT), "armR", outline=0)
for i in range(4):
    x, y = on_note(-54 + 36 * i, -106)
    add(torus(f"Ring{i}", P(x, y, ND), .009, .024, .005, [M["ring"]], seg=20, ring=8), "armR", outline=0)
if ANGEL:
    M["pencil"] = material("Pencil", (222, 106, 58)); M["wood"] = material("Wood", (240, 200, 150))
    a, b, c = P(268, 1088, -.262), P(425, 1152, -.262), P(452, 1163, -.262)
    add(tube("Pencil", [a, tuple((np.array(a) + np.array(b)) / 2), b], [.017] * 3, M["pencil"], n=6, seg=12), "armR")
    add(tube("PencilTip", [b, tuple((np.array(b) + np.array(c)) / 2), c], [.016, .009, .002], M["wood"], n=6, seg=12), "armR", outline=.004)

# ---------- マフラー ----------
if ANGEL:
    M["scA"], M["scB"] = material("ScarfRed", (222, 48, 42), rough=.85), material("ScarfWhite", (255, 246, 240), rough=.85)
    add(torus("Scarf", (0, -.005, Z(1062)), .188, .158, .062, [M["scA"], M["scB"]], minor_z=.056, seg=70,
              pick=lambda t: int(t * 14) % 2), "body")
    add(slab("ScarfEnd1", [(950, 1045), (1010, 1000), (1060, 985), (1088, 1010), (1050, 1060), (985, 1085)], M["scA"], .14, thick=.02), "body")
    add(slab("ScarfEnd2", [(930, 1060), (990, 1070), (1060, 1105), (1075, 1150), (1010, 1155), (960, 1120)], M["scB"], .16, thick=.02), "body")
    M["badge"], M["badgeS"] = material("Badge", (226, 96, 58), rough=.4), material("BadgeScreen", (98, 44, 42), rough=.3)
    add(slab("Badge", rounded_rect(868, 1052, 72, 98, 18, -8), M["badge"], -.232, thick=.03, bevel=.008, smooth=False), "body")
    add(slab("BadgeS", rounded_rect(866, 1040, 44, 48, 6, -8), M["badgeS"], -.256, thick=.006, bevel=.002, smooth=False), "body", outline=.003)
else:
    M["scA"], M["scB"] = material("ScarfDark", (92, 24, 32), rough=.9), material("ScarfDark2", (58, 24, 32), rough=.9)
    add(torus("Scarf", (0, -.005, Z(1058)), .188, .158, .060, [M["scA"], M["scB"]], minor_z=.05, seg=70,
              pick=lambda t: int(t * 10) % 2), "body")
    for i, (x, w) in enumerate(((640, 44), (820, 40), (580, 30), (880, 30))):
        dd = -.205 + abs(x - 750) / 1000 * .35
        add(slab(f"Rag{i}", [(x - w, 1085), (x + w, 1085), (x + w * .3, 1112), (x, 1142), (x - w * .5, 1105)], M["scA"], dd,
                 thick=.012, bevel=.004, smooth=False), "body")
    M["buckle"] = material("Buckle", (58, 54, 58), rough=.45)
    add(slab("Buckle", rounded_rect(718, 1082, 106, 100, 14), M["buckle"], -.236, thick=.03, bevel=.008, smooth=False), "body")
    M["buckle2"] = material("Buckle2", (86, 80, 84), rough=.45)
    add(slab("Buckle2", rounded_rect(718, 1082, 44, 100, 8), M["buckle2"], -.252, thick=.012, bevel=.004, smooth=False), "body", outline=.004)

# ---------- 羽・輪・角・しっぽ・槍 ----------
def mirror(pts): return [(1504 - x, y) for x, y in pts]

if ANGEL:
    M["wing"], M["wing2"] = material("Wing", (255, 249, 247), rough=.8), material("Wing2", (244, 230, 238), rough=.8)
    wing = [(930, 930), (1000, 850), (1070, 815), (1150, 780), (1230, 745), (1310, 695), (1370, 640), (1402, 620), (1416, 650),
            (1402, 720), (1375, 770), (1352, 792), (1400, 778), (1420, 800), (1395, 855), (1345, 895), (1310, 912),
            (1360, 920), (1372, 942), (1325, 980), (1268, 1000), (1288, 1022), (1282, 1045), (1235, 1060), (1190, 1055),
            (1150, 1060), (1060, 1040), (960, 1010)]
    feathers = [(1215, 832, 88, 34, -32), (1200, 905, 78, 32, -20), (1165, 968, 66, 28, -8)]
    for b, f in (("wingL", lambda p: p), ("wingR", mirror)):
        add(slab("Wing" + b, f(wing), M["wing"], .17, thick=.02, bevel=.014, shear=.22), b)
        for i, (cx, cy, rx, ry, dg) in enumerate(feathers):
            add(slab(f"Feather{b}{i}", f(ellipse_pts(cx, cy, rx, ry, dg)), M["wing2"], .145 + .005 * i, thick=.014, bevel=.01, shear=.22), b, outline=.005)
    M["halo"] = material("Halo", (255, 206, 72), rough=.3)
    add(torus("Halo", (0, 0, Z(437)), .208, .200, .020, [M["halo"]], tilt=math.radians(17)), "halo")
    add(ball("Tail", (.05, .235, .30), .085, M["skin"]), "tail")
else:
    M["mem"] = material("Membrane", (126, 30, 36), rough=.8)
    M["bone"] = material("WingBone", (48, 34, 40), rough=.6)
    M["horn"] = material("Horn", (196, 30, 34), rough=.4)
    mem = [(610, 1000), (520, 900), (440, 760), (392, 640), (345, 625), (270, 660), (190, 740), (130, 835), (92, 950), (68, 1080),
           (58, 1180), (68, 1245), (88, 1175), (112, 1118), (158, 1078), (190, 1115), (222, 1180), (252, 1105), (296, 1058),
           (340, 1082), (395, 1040), (450, 1062), (540, 1050)]
    def sh(x, y, d=.17):
        p = P(x, y, d)
        return (p[0], d + .22 * max(0, abs(p[0]) - .2), p[2])
    for b, f in (("wingR", lambda p: p), ("wingL", mirror)):
        add(slab("Mem" + b, f(mem), M["mem"], .17, thick=.012, bevel=.005, smooth=False, shear=.22), b)
        for i, (pts, rs) in enumerate((
            ([(600, 960), (480, 830), (385, 640)], [.030, .028, .034]),
            ([(385, 640), (270, 662), (170, 775), (95, 950), (66, 1235)], [.032, .03, .024, .018, .004]),
            ([(380, 645), (290, 830), (222, 1170)], [.022, .016, .004]),
            ([(385, 650), (350, 850), (340, 1075)], [.020, .014, .004]),
        )):
            add(tube(f"WB{b}{i}", [sh(x, y, .165) for x, y in f(pts)], rs, M["bone"], n=10, seg=8), b)
        add(tube("Claw" + b, [sh(x, y, .16) for x, y in f([(378, 648), (402, 605), (440, 578)])], [.026, .018, .002], M["horn"], n=10, seg=12), b)
    for s in (-1, 1):
        add(tube(f"Horn{s}", [(s * .222, -.02, Z(570)), (s * .262, -.03, Z(490)), (s * .252, -.03, Z(415)), (s * .222, -.03, Z(345))],
                 [.070, .058, .036, .002], M["horn"], n=12, seg=14), "head")
    M["tail"] = material("Tail", (122, 22, 34), rough=.6)
    add(tube("Tail", [(.06, .17, .22), (.22, .22, .14), (.36, .22, .12), (.46, .20, .18), (.505, .19, .25)], [.03, .028, .026, .023, .018], M["tail"], n=14, seg=10), "tail")
    add(slab("TailTip", [(1185, 1372), (1292, 1292), (1280, 1438), (1252, 1400)], M["tail"], .19, thick=.02, bevel=.008, smooth=False), "tail")
    M["fork"], M["pole"] = material("Fork", (186, 30, 32), rough=.4), material("Pole", (64, 40, 44), rough=.6)
    top, bot = P(1152, 985, -.175), P(880, 1600, -.10)
    def on(t): return tuple(np.array(bot) + (np.array(top) - np.array(bot)) * t)
    add(tube("Pole", [on(0), on(.5), on(1)], [.015] * 3, M["pole"], n=8, seg=12), "armL")
    FD = -.178
    add(tube("ForkC", [P(1152, 985, FD), P(1180, 920, FD), P(1218, 800, FD)], [.014] * 3, M["fork"], n=8, seg=12), "armL")
    add(tube("ForkU", [P(1135, 775, FD), P(1108, 840, FD), P(1130, 905, FD), P(1182, 930, FD), P(1245, 905, FD), P(1285, 840, FD)],
             [.013] * 6, M["fork"], n=20, seg=8), "armL")
    for i, (tip, l, r) in enumerate((((1228, 748), (1194, 800), (1246, 812)), ((1158, 735), (1116, 772), (1160, 792)), ((1304, 792), (1262, 838), (1306, 852)))):
        add(slab(f"Tip{i}", [l, tip, r], M["fork"], FD, thick=.014, bevel=.004, smooth=False), "armL")

# ---------- 骨 ----------
arm_data = bpy.data.armatures.new("Rig")
rig = bpy.data.objects.new("Rig", arm_data)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
def bone(n, h, t, parent=None):
    b = arm_data.edit_bones.new(n); b.head = h; b.tail = t
    if parent: b.parent = arm_data.edit_bones[parent]
bone("root", (0, 0, 0), (0, 0, .15))
bone("body", (0, 0, .22), (0, 0, .55), "root")
bone("head", (0, 0, .57), (0, 0, 1.1), "body")
bone("sprout", (.01, 0, 1.12), (.015, 0, 1.28), "head")
bone("halo", (0, 0, 1.11), (0, 0, 1.2), "head")
bone("armL", armL[0], armL[-1], "body")
bone("armR", armR[0], armR[-1], "body")
bone("legL", (.13, 0, .25), (.115, -.012, 0), "root")
bone("legR", (-.13, 0, .25), (-.115, -.012, 0), "root")
bone("wingL", (.17, .17, Z(950)), (.5, .22, Z(850)), "body")
bone("wingR", (-.17, .17, Z(950)), (-.5, .22, Z(850)), "body")
bone("tail", (.05, .17, .25), (.2, .22, .2), "body")
bpy.ops.object.mode_set(mode="OBJECT")

# ---------- 1つのメッシュにまとめて骨に割り当て ----------
for o, b in PARTS:
    g = o.vertex_groups.new(name=b)
    g.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
bpy.ops.object.select_all(action="DESELECT")
for o, _ in PARTS:
    o.select_set(True)
bpy.context.view_layer.objects.active = PARTS[0][0]
bpy.ops.object.join()
char = bpy.context.view_layer.objects.active
char.name = NAME
tri = char.modifiers.new("Tri", "TRIANGULATE")
bpy.ops.object.modifier_apply(modifier="Tri")
# 原点を体の中心に
mid = Vector((0, 0, .64))
for v in char.data.vertices:
    v.co -= mid
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for b in arm_data.edit_bones:
    b.head = b.head - mid if not (b.use_connect) else b.head
    b.tail = b.tail - mid
bpy.ops.object.mode_set(mode="OBJECT")
char.parent = rig
md = char.modifiers.new("Armature", "ARMATURE"); md.object = rig
print("TRIS", len(char.data.polygons), "MATS", len(char.data.materials))

# ---------- アニメーション ----------
PB = rig.pose.bones
for b in PB:
    b.rotation_mode = "QUATERNION"
REST = {b.name: rig.data.bones[b.name].matrix_local.to_quaternion() for b in PB}

def euler(x=0, y=0, z=0):
    return (Quaternion((0, 0, 1), math.radians(z)) @ Quaternion((0, 1, 0), math.radians(y)) @ Quaternion((1, 0, 0), math.radians(x)))

def pose(frame, rots=None, root=(0, 0, 0), squash=1.0):
    rots = rots or {}
    for b in PB:
        q = rots.get(b.name, Quaternion())
        r = REST[b.name]
        b.rotation_quaternion = r.inverted() @ q @ r
        b.location = (0, 0, 0)
        b.scale = (1, 1, 1)
    PB["root"].location = REST["root"].inverted() @ Vector(root)
    PB["root"].scale = (1 / math.sqrt(squash), squash, 1 / math.sqrt(squash))
    for b in PB:
        b.keyframe_insert("rotation_quaternion", frame=frame)
        b.keyframe_insert("location", frame=frame)
        b.keyframe_insert("scale", frame=frame)

S = math.sin
TAU = 2 * math.pi
# 待機 0-60
for f in range(0, 61, 2):
    t = TAU * f / 60
    flap = S(2 * t) * (12 if ANGEL else 8)
    r = {
        "wingL": euler(z=flap, y=-flap * .4), "wingR": euler(z=-flap, y=flap * .4),
        "head": euler(y=S(t) * 3, x=S(t + 1) * 2), "sprout": euler(y=S(2 * t) * 7),
        "halo": euler(x=S(t) * 4, y=S(t + 1) * 3), "tail": euler(z=S(2 * t) * 12),
        "armR": euler(y=S(t) * 3),
        "armL": euler(y=S(3 * t) * 14) if ANGEL else euler(y=S(t) * 4),
        "legL": euler(x=S(t) * 4 if ANGEL else 0), "legR": euler(x=-S(t) * 4 if ANGEL else 0),
    }
    root = (0, 0, S(t) * .022) if ANGEL else (S(t) * .008, 0, 0)
    pose(f, r, root, 1.0 if ANGEL else 1 + S(2 * t) * .012)
# 走る 70-88 (1周 18 フレーム)
for f in range(0, 19):
    t = TAU * f / 18
    sw = S(t)
    up = abs(math.cos(t))
    fl = S(2 * t) * 14
    armL_base = euler(y=75) if ANGEL else euler()
    r = {
        "legL": euler(x=sw * 52), "legR": euler(x=-sw * 52),
        "armL": euler(x=-sw * (38 if ANGEL else 10)) @ armL_base, "armR": euler(x=sw * 22),
        "body": euler(x=9, z=sw * 6), "head": euler(x=-5, z=-sw * 5, y=sw * 2),
        "wingL": euler(z=18 + fl), "wingR": euler(z=-18 - fl),
        "sprout": euler(x=-14 + S(2 * t) * 8), "halo": euler(x=S(2 * t) * 4),
        "tail": euler(z=S(t) * 16, x=10),
    }
    pose(70 + f, r, (0, 0, .015 + up * .045), 1 + (up - .5) * .05)
# 歩く 100-130 (1周 30 フレーム)
for f in range(0, 31):
    t = TAU * f / 30
    sw = S(t)
    up = abs(math.cos(t))
    fl = S(2 * t) * 8
    armL_base = euler(y=70) if ANGEL else euler()
    r = {
        "legL": euler(x=sw * 32), "legR": euler(x=-sw * 32),
        "armL": euler(x=-sw * (24 if ANGEL else 7)) @ armL_base, "armR": euler(x=sw * 12),
        "body": euler(x=3, z=sw * 4), "head": euler(y=sw * 3, z=-sw * 3),
        "wingL": euler(z=fl), "wingR": euler(z=-fl),
        "sprout": euler(y=-sw * 6), "halo": euler(x=S(2 * t) * 3), "tail": euler(z=S(t) * 12),
    }
    pose(100 + f, r, (0, 0, up * .018), 1 + (up - .5) * .02)
for fc_holder in (rig.animation_data.action,):
    try:
        curves = fc_holder.fcurves
    except AttributeError:
        curves = [c for l in fc_holder.layers for s in l.strips for cb in s.channelbags for c in cb.fcurves]
    for c in curves:
        for k in c.keyframe_points:
            k.interpolation = "LINEAR" if k.co[0] >= 70 else "BEZIER"
scene.frame_start, scene.frame_end = 0, 130
scene.frame_set(0)

bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, f"{NAME}.blend"))

# ---------- プレビュー ----------
if PREVIEW:
    w = bpy.data.worlds.new("W"); scene.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = .75
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sun.data.energy = 2.0
    sun.rotation_euler = (math.radians(50), math.radians(15), math.radians(-25)); scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); scene.collection.objects.link(cam); scene.camera = cam
    cam.data.lens = 60
    scene.view_settings.view_transform = "Standard"
    for e in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try: scene.render.engine = e; break
        except TypeError: pass
    scene.render.resolution_x = scene.render.resolution_y = 560
    for nm, fr, ang in (("front", 0, 0), ("q", 0, 38), ("side", 0, 90), ("back", 0, 180), ("run1", 74, 38), ("run2", 83, 38), ("walk1", 107, 60), ("walk2", 122, 60)):
        scene.frame_set(fr)
        a = math.radians(ang)
        cam.location = (3.1 * math.sin(a), -3.1 * math.cos(a), .12)
        cam.rotation_euler = (Vector((0, 0, 0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(OUT, f"pv_{NAME}_{nm}.png")
        bpy.ops.render.render(write_still=True)
    scene.frame_set(0)
    # アプリの読み込み中に出す静止画（CharacterView のカメラと同じ構図・正方形・透過）
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(30)
    cam.location = (0, -3.15, .14)
    cam.rotation_euler = (Vector((0, 0, .04)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_x = scene.render.resolution_y = 840
    sun.data.energy = 2.6
    w.node_tree.nodes["Background"].inputs[1].default_value = .95
    sun.rotation_euler = (math.radians(55), 0, math.radians(12))
    scene.frame_set(0)
    scene.render.filepath = os.path.join(OUT, f"Character{NAME}.png")
    bpy.ops.render.render(write_still=True)
    for o in (sun, cam):
        bpy.data.objects.remove(o)

# ---------- USDZ ----------
bpy.ops.wm.usd_export(
    filepath=os.path.join(OUT, f"{NAME}.usdz"), export_animation=True, export_armatures=True, export_materials=True,
    generate_preview_surface=True, convert_orientation=True, export_global_up_selection="Y",
    export_global_forward_selection="NEGATIVE_Z", usdz_downscale_size="1024",
    convert_world_material=False)
