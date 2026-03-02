# design.md

## 1. 方針
- 音量メータ値を dB の実用レンジで再正規化し、低レベル帯を強調する
- UI側の無音ベース揺らぎを弱め、入力連動変化を見えやすくする

## 2. 実装
### 2.1 AVAudioRecordingService
- `averagePower` と `peakPower` を併用
- dBを `[-55, 0]` でクランプして 0〜1 へ正規化
- `pow(normalized, 0.55)` で低入力を持ち上げ

### 2.2 RecordingModalView
- `normalizedLevel` の最低値を下げる
- ベース揺らぎを `0.02〜0.04` 程度に抑える

## 3. 検証
- `swift test`
- 実機で無音/発話の見た目差分を確認
