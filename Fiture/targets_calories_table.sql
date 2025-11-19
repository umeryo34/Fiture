-- カロリー目標テーブル作成SQL
-- SupabaseのSQL Editorで実行してください

CREATE TABLE IF NOT EXISTS targets_calories (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    date DATE NOT NULL,
    target DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- インデックス作成（パフォーマンス向上のため）
CREATE INDEX IF NOT EXISTS idx_targets_calories_user_date ON targets_calories(user_id, date);

-- RLS (Row Level Security) ポリシー設定
ALTER TABLE targets_calories ENABLE ROW LEVEL SECURITY;

-- ユーザーは自分のデータのみ閲覧・編集可能
CREATE POLICY "Users can view their own calories targets"
    ON targets_calories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own calories targets"
    ON targets_calories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own calories targets"
    ON targets_calories FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own calories targets"
    ON targets_calories FOR DELETE
    USING (auth.uid() = user_id);

-- updated_atを自動更新するトリガー
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_targets_calories_updated_at
    BEFORE UPDATE ON targets_calories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

