# design.md

## 1. 設計方針
既存の `SessionController` を録音中UIの単一状態ソースとして維持し、波形データも同コントローラから `RecordingModalView` へ公開する。

## 2. 変更対象
- `Domain/Services/ServiceProtocols.swift`
- `Infrastructure/Audio/AVAudioRecordingService.swift`
- `Application/SessionController/SessionController.swift`
- `Presentation/RecordingModal/RecordingModalView.swift`
- 関連テストモック

## 3. 設計詳細
### 3.1 RecordingService拡張
- `currentAudioLevel() -> Float` を追加
- 返却値は 0.0〜1.0 の正規化レベル

### 3.2 AVAudioRecordingService
- `AVAudioRecorder.isMeteringEnabled = true`
- `updateMeters()` + `averagePower(forChannel:)` から正規化レベルに変換
- 録音中以外は 0 を返す

### 3.3 SessionController
- `@Published recordingAudioLevel: Double` を追加
- 録音中のみ短周期タイマーで `currentAudioLevel()` を取得
- 停止/エラー時にタイマー停止とレベル初期化

### 3.4 RecordingModalView
- 既存のテキスト/時間/停止ボタンを維持
- 録音バッジ（赤点 + Recording）を追加
- `recordingAudioLevel` を使ってバー型波形を描画
- 無音時は最低高さを持たせて「動作中」を視認可能にする

## 4. テスト方針
- 既存の `SessionController` Unit/Integration テストのモックを新プロトコルに追従
- `swift test` で回帰確認

## 5. リスク
- タイマー更新が高すぎるとCPU負荷増大
- メーター値の変動が大きすぎると視認性低下

## 6. 対応策
- 更新間隔を 0.08秒に固定
- 表示時に最低値・最大値をクランプ
