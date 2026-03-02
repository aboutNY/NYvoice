# design.md

## 1. 方針
SessionController で録音中の最大音量レベルを追跡し、停止時に閾値判定して無音なら処理を早期終了する。

## 2. 実装
- `SessionController` に `maxRecordingAudioLevel` を追加
- 録音中サンプリングで `recordingAudioLevel` と最大値を更新
- 録音停止時に `maxRecordingAudioLevel` と停止直前値で無音判定
- 閾値未満の場合は `state = .idle` に戻し、文字起こし以降をスキップ

## 3. 影響範囲
- `app/NYvoiceApp/Application/SessionController/SessionController.swift`
- `tests/Unit/Application/SessionControllerTests.swift`
- `tests/Integration/SessionFlow/SessionControllerIntegrationTests.swift`

## 4. 検証
- `swift test`
- 実機で無音時に挿入されないことを確認
