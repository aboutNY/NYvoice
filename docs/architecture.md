# Architecture

## 1. 目的
本書は、macOS音声入力文字起こしアプリの技術アーキテクチャを定義する。
対象はMVPであり、実装言語はSwiftを前提とする。

## 2. システム構成
アプリは単一のmacOSネイティブアプリ（.app）として構成する。
主要処理は以下のパイプラインで連結される。

1. Trigger（グローバルショートカット）
2. Audio Capture（録音）
3. STT（Whisper.cpp）
4. Text Correction（Ollama）
5. Text Insert（カーソル位置挿入）

## 3. コンポーネント設計
### 3.1 App Shell
- 役割: アプリライフサイクル、メニューバー常駐、設定画面起動
- 主な責務
- 起動時初期化
- 権限チェック導線
- コンポーネント組み立て

### 3.2 Shortcut Manager
- 役割: グローバルショートカット登録・監視
- 入力: ユーザー設定のキー定義
- 出力: `startRecording` / `stopRecording` イベント

### 3.3 Session Controller
- 役割: 音声入力セッション全体の状態管理
- 状態: Idle / Recording / Transcribing / Correcting / Inserting / Error
- 主な責務
- セッション開始・停止
- 状態遷移の一元管理
- 各サービス連携のオーケストレーション

### 3.4 Recording UI (Modal)
- 役割: 録音中の視覚フィードバックと停止操作
- 主な責務
- 録音状態表示
- 経過時間表示
- 停止ボタン提供

### 3.5 Audio Capture Service
- 役割: マイク入力の収録と一時ファイル化
- 主な責務
- マイクデバイス初期化
- 録音開始/停止
- 音声フォーマット統一（Whisper入力互換）

### 3.6 Transcription Service (Whisper.cpp Adapter)
- 役割: whisper.cpp実行を抽象化
- 主な責務
- 実行コマンド組み立て
- 一時音声ファイルを入力してテキストを取得
- タイムアウト・実行失敗をドメインエラーへ変換

### 3.7 Correction Service (Ollama Adapter)
- 役割: ローカルLLM補正の抽象化
- 主な責務
- プロンプト組み立て
- ユーザー設定のプロンプトテンプレート（`{{transcript}}`）解決
- Ollama API呼び出し
- 補正方針（意味維持）に沿った結果整形

### 3.8 Text Insertion Service
- 役割: 文字列をアクティブアプリへ反映
- 主な責務
- 直接挿入の試行
- 失敗時クリップボードフォールバック
- ユーザー通知

### 3.9 Settings Store
- 役割: ユーザー設定の永続化
- 保存対象
- ショートカット
- Whisperモデル設定
- Ollamaモデル設定
- Ollama補正プロンプトテンプレート
- 補正ON/OFF

### 3.10 Logging Service
- 役割: デバッグ・障害解析用ログ出力
- 単位: セッションID
- 記録項目: 開始/停止、各処理開始/終了、エラー詳細

## 4. データフロー
### 4.1 成功時
1. Shortcut Managerが開始イベントを発行
2. Session ControllerがRecordingへ遷移
3. Audio Capture Serviceが録音ファイルを生成
4. Session ControllerがTranscribingへ遷移
5. Transcription Serviceが生テキストを返却
6. Session ControllerがCorrectingへ遷移
7. Correction Serviceが補正テキストを返却
8. Session ControllerがInsertingへ遷移
9. Text Insertion Serviceが挿入完了
10. Session ControllerがIdleへ復帰

### 4.2 失敗時
- 各段階の失敗はドメインエラーとしてSession Controllerに返す
- Session ControllerはError状態に遷移し、ユーザー通知後にIdleへ戻す

## 5. 状態遷移ルール
- Idle -> Recording: 開始操作
- Recording -> Transcribing: 停止操作
- Transcribing -> Correcting: 文字起こし成功
- Transcribing -> Error: 文字起こし失敗
- Correcting -> Inserting: 補正成功
- Correcting -> Inserting: 補正失敗だが生テキスト採用
- Correcting -> Error: 補正失敗かつ継続不可
- Inserting -> Idle: 挿入成功またはフォールバック完了
- Error -> Idle: エラー表示完了

## 6. 外部依存
- Whisper.cpp（ローカル実行バイナリ）
- Ollama（ローカルLLMランタイム）
- macOS権限
- Microphone
- Accessibility

## 7. 配布アーキテクチャ方針
- 単一のmacOSアプリ（.app）として配布する
- アプリ本体に必要コンポーネントを同梱可能な構成を優先する
- 外部依存が必要な場合は初回起動時に検出・案内する

## 8. エラー設計方針
- エラー分類
- PermissionError
- RecordingError
- TranscriptionError
- CorrectionError
- InsertionError
- UserMessage（表示文言）とTechnicalDetail（ログ詳細）を分離する

## 9. セキュリティ/プライバシー方針
- 音声・テキストはローカル処理を原則とする
- 不要な永続保存を避ける（一時ファイルは処理完了後に削除）
- ログに機微情報を過剰に残さない

## 10. 拡張ポイント
- リアルタイム文字起こし表示
- カスタム辞書/固有名詞補正
- アプリ別挿入戦略の最適化
- モデル切替の高度設定
