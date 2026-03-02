# design.md

## 1. 変更方針
- `AppSettings` に `ollamaPromptTemplate` を追加し永続化対象を拡張する
- `SettingsView` に編集 UI（複数行入力）を追加する
- `OllamaCorrectionService` でテンプレートを解決して `prompt` を生成する

## 2. テンプレート仕様
- プレースホルダー: `{{transcript}}`
- `{{transcript}}` を含む場合は置換
- 含まない場合は末尾に文字起こし結果を追記して安全に処理

## 3. 互換性
- `AppSettings` の `Decodable` を手動実装し、新規フィールド欠落時はデフォルト値を採用
- 既存設定キー構造は維持する

## 4. UI設計
- 既存 `Form` に「Ollama prompt template」入力欄を追加
- テキストエディタ下部に `{{transcript}}` 利用ガイドを表示

## 5. 検証
- Unit/Integration テスト実行で回帰確認
- 追加仕様はコードレビュー時に `buildPrompt` ロジックと保存復元を重点確認
