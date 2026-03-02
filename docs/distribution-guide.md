# Distribution Guide

## 1. 目的
本書は、NYvoice をチームメイトへ配布するための最小手順を定義する。

## 2. 配布方針（MVP）
- 配布物は単一の macOS アプリ（`.app`）とする
- 初回起動時に権限・依存チェックを実行し、不足を案内する
- 対象OSは macOS のみ

## 3. 依存要件
- マイク権限
- アクセシビリティ権限
- Whisper 実行バイナリ
- Whisper モデルファイル
- Ollama（`http://127.0.0.1:11434`）

## 4. ビルドとパッケージ
### 4.1 リリース反映手順（必須・直列実行）
以下は **順番どおりに1つずつ** 実行する。

1. `swift build -c release`
2. `cp "$PWD/.build/release/NYvoiceApp" "$PWD/dist/NYvoiceApp.app/Contents/MacOS/NYvoiceApp"`
3. `cp "$PWD/.build/release/NYvoiceApp" "/Applications/NYvoiceApp.app/Contents/MacOS/NYvoiceApp"`
4. `codesign --force --deep --sign - /Applications/NYvoiceApp.app`
5. `open -a /Applications/NYvoiceApp.app`

### 4.2 配布形式
- 社内配布（Zip）
- DMG配布

## 5. 署名と公証（推奨）
- Developer ID で署名する
- 可能であれば Notarization を実施する
- 社内限定の一時配布では未署名配布も可能だが、Gatekeeper 警告の説明が必要

## 6. 受け手向け初回セットアップ
1. アプリ起動
2. Environment Check の結果を確認
3. 不足項目があれば以下を実施
- マイク権限付与
- アクセシビリティ権限付与
- Settings で Whisper binary / model path 設定
- `ollama serve` 起動
4. 再度 `Run Environment Check` を実行

## 7. トラブルシュート
- 録音開始できない: マイク権限確認
- 挿入できない: アクセシビリティ権限確認
- 文字起こし失敗: Whisper binary/model path の設定確認
- 補正失敗: Ollama 起動とモデル名確認

## 8. リリースチェックリスト
- `swift test` が成功している
- 正常系と主要異常系が確認済み
- 設定画面でショートカットが保存可能
- 初回 Environment Check が期待通りに表示される
- 配布手順を実施者以外が再現できる

## 9. 反映確認チェック（漏れ防止）
1. 実行実体確認
- `ps ax -o pid=,command= | rg "NYvoiceApp.app/Contents/MacOS/NYvoiceApp"`
2. 署名検証
- `codesign --verify --deep --strict --verbose=2 /Applications/NYvoiceApp.app`
3. 反映時刻確認
- `stat -f '%Sm %N' -t '%Y-%m-%d %H:%M:%S' .build/release/NYvoiceApp dist/NYvoiceApp.app/Contents/MacOS/NYvoiceApp /Applications/NYvoiceApp.app/Contents/MacOS/NYvoiceApp`
4. 変更内容確認
- `strings /Applications/NYvoiceApp.app/Contents/MacOS/NYvoiceApp | rg "<変更した表示文言>"`

補足:
- `codesign` 後は `/Applications/NYvoiceApp.app` 内の実行ファイルハッシュが `.build/release` と一致しない場合がある（署名情報更新のため）。
- 一致判定はハッシュではなく、上記の署名検証・実行実体・変更内容確認を優先する。
