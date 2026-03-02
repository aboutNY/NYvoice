# design.md

## 1. 方針
無音判定に使う観測レベルを、タイマー停止・状態リセットより前に確定する。

## 2. 実装
- `SessionController.stopAndProcessRecording()` で `observedLevel` を先に計算
- `stopAudioLevelTimer()` が内部で値をリセットしても判定に影響しないようにする
- テストに「開始時は音あり、停止時は無音」のケースを追加

## 3. 影響範囲
- `app/NYvoiceApp/Application/SessionController/SessionController.swift`
- `tests/Integration/SessionFlow/SessionControllerIntegrationTests.swift`

## 4. 検証
- `swift test`
- 実機確認
