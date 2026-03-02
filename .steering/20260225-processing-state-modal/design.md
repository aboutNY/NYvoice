# design.md

## 1. 方針
`SessionState` を唯一の表示制御ソースとして、`idle` 以外ではモーダルを表示する。

## 2. 実装
- `AppDelegate.bindSessionState`:
  - 旧: `recording` のときだけ表示
  - 新: `idle` 以外で表示
- `RecordingModalView`:
  - `recording`: 現在の波形 + 停止ボタン
  - `transcribing/correcting/inserting`: ProgressView + 処理中文言 + 現在ステータス

## 3. 影響範囲
- `app/NYvoiceApp/App/AppDelegate.swift`
- `app/NYvoiceApp/Presentation/RecordingModal/RecordingModalView.swift`

## 4. 検証
- `swift test`
- 実機で録音終了後の表示遷移確認
