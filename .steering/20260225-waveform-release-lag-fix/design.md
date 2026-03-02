# design.md

## 1. 方針
ピーク保持による遅延を避けるため、音量算出を `averagePower` ベースに単純化する。

## 2. 実装
- `AVAudioRecordingService.currentAudioLevel()` で `peakPower` を使わない
- dB正規化と低入力ブーストは維持し、感度は維持する

## 3. 影響範囲
- `app/NYvoiceApp/Infrastructure/Audio/AVAudioRecordingService.swift`

## 4. 検証
- `swift test`
- 実機で発話停止後の戻り速度を確認
