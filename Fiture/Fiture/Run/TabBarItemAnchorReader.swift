//
//  TabBarItemAnchorReader.swift
//  Fiture
//

import SwiftUI
import UIKit

struct TabBarItemAnchor: Equatable {
    var centerX: CGFloat
    var iconTopY: CGFloat
}

struct TabBarItemAnchorObserver: View {
    let tabIndex: Int
    var layoutRevision: Int = 0
    @Binding var anchor: TabBarItemAnchor?

    var body: some View {
        TabBarItemAnchorReader(tabIndex: tabIndex, layoutRevision: layoutRevision, anchor: $anchor)
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
    }
}

private struct TabBarItemAnchorReader: UIViewRepresentable {
    let tabIndex: Int
    let layoutRevision: Int
    @Binding var anchor: TabBarItemAnchor?

    func makeUIView(context: Context) -> TabBarAnchorProbeView {
        let view = TabBarAnchorProbeView()
        view.tabIndex = tabIndex
        view.onUpdate = { anchor = $0 }
        return view
    }

    func updateUIView(_ uiView: TabBarAnchorProbeView, context: Context) {
        uiView.tabIndex = tabIndex
        _ = layoutRevision
        uiView.scheduleMeasurement()
    }
}

private final class TabBarAnchorProbeView: UIView {
    var tabIndex = 0
    var onUpdate: ((TabBarItemAnchor?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        scheduleMeasurement()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scheduleMeasurement()
    }

    func scheduleMeasurement() {
        DispatchQueue.main.async { [weak self] in
            self?.measure()
        }
    }

    private func measure() {
        guard let tabBar = resolveTabBar() else {
            onUpdate?(nil)
            return
        }
        guard let itemFrame = tabBar.sortedTabButtonFrame(at: tabIndex) else {
            onUpdate?(nil)
            return
        }

        let anchorPoint = CGPoint(x: itemFrame.midX, y: itemFrame.minY)
        let inScreen = tabBar.convert(anchorPoint, to: nil)
        onUpdate?(TabBarItemAnchor(centerX: inScreen.x, iconTopY: inScreen.y))
    }

    private func resolveTabBar() -> UITabBar? {
        var responder: UIResponder? = self
        while let current = responder {
            if let tabBarController = current as? UITabBarController {
                return tabBarController.tabBar
            }
            responder = current.next
        }

        guard let root = keyWindow?.rootViewController else { return nil }
        return findTabBarController(in: root)?.tabBar
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    private func findTabBarController(in viewController: UIViewController?) -> UITabBarController? {
        guard let viewController else { return nil }
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        for child in viewController.children {
            if let found = findTabBarController(in: child) {
                return found
            }
        }
        if let presented = viewController.presentedViewController {
            return findTabBarController(in: presented)
        }
        return nil
    }
}

private extension UITabBar {
    func sortedTabButtonFrame(at index: Int) -> CGRect? {
        let buttons = subviews
            .filter { String(describing: type(of: $0)).contains("UITabBarButton") }
            .sorted { $0.frame.minX < $1.frame.minX }
        guard index >= 0, index < buttons.count else { return nil }
        return buttons[index].frame
    }
}
