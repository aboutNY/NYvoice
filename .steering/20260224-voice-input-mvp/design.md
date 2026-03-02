# design.md

## 1. 設計方針
MVPでは「録音開始から挿入完了までを1セッションで確実に処理する」ことを最優先とする。
複雑な最適化より、状態遷移の明確化と失敗時フォールバックを重視する。

## 2. アーキテクチャ概要
- 実装: Swift（SwiftUI + AppKit）
- 構成: メニューバー常駐アプリ
- 処理パイプライン
1. グローバルショートカット受信
2. 録音開始（モーダル表示）
3. 録音停止
4. Whisper.cppで文字起こし
5. Ollamaで文脈補正
6. カーソル位置へ挿入（失敗時クリップボードフォールバック）

## 3. 主要コンポーネント設計
### 3.1 SessionController
- 責務: セッション状態の一元管理
- 状態: Idle / Recording / Transcribing / Correcting / Inserting / Error
- 入力: shortcut, modal stop action
- 出力: UI状態更新、サービス呼び出し、通知

### 3.2 ShortcutManager
- 責務: グローバルショートカット監視
- 実装方針: ユーザー設定値に基づき登録、無効時は保存拒否

### 3.3 AudioCaptureService
- 責務: マイク録音と一時ファイル生成
- 実装方針: セッションごとに一時ファイルを払い出し、後段へ受け渡し

### 3.4 WhisperAdapter
- 責務: whisper.cppプロセス呼び出し
- 入力: 音声ファイルパス、モデル設定
- 出力: 文字起こしテキスト or 失敗エラー
- 失敗処理: 実行コード/stderrをログに保存

### 3.5 OllamaAdapter
- 責務: 補正API呼び出し
- 入力: 生文字起こしテキスト、モデル名
- 出力: 補正テキスト
- プロンプト方針: 意味維持、誤字・変換ミス優先、不要な要約禁止

### 3.6 TextInsertionService
- 責務: アクティブアプリへの反映
- 第一手段: 直接挿入
- 第二手段: クリップボード格納 + 手動貼り付け案内

### 3.7 RecordingModalView
- 責務: 録音状態可視化と停止操作
- 表示要素: 録音中ラベル、経過時間、停止ボタン

## 4. シーケンス設計
### 4.1 正常系
1. ユーザーがショートカット押下
2. SessionControllerがRecordingへ遷移し、モーダル表示
3. 停止操作で録音終了・音声ファイル確定
4. Transcribingへ遷移しWhisperAdapter実行
5. Correctingへ遷移しOllamaAdapter実行
6. Insertingへ遷移しTextInsertionService実行
7. 成功通知後にIdleへ復帰

### 4.2 異常系
- マイク権限なし: 開始前にError遷移、権限案内
- Whisper失敗: Error遷移、再試行案内
- Ollama失敗: 生文字起こしで継続する選択肢を提示
- 挿入失敗: クリップボードフォールバック後にIdle復帰

## 5. データ設計
### 5.1 SessionContext
- sessionId: String
- startedAt: Date
- audioFilePath: String?
- transcriptRaw: String?
- transcriptCorrected: String?
- lastError: DomainError?

### 5.2 Settings
- shortcut: String
- whisperModel: String
- ollamaModel: String
- correctionEnabled: Bool

## 6. エラー設計
- PermissionError
- RecordingError
- TranscriptionError
- CorrectionError
- InsertionError

UI向けメッセージと、ログ向け詳細情報を分離して保持する。

## 7. ログ設計
- 形式: セッションID付き構造化ログ
- 記録タイミング
- start/stop recording
- transcription start/end
- correction start/end
- insertion success/failure

## 8. 実装フェーズ（MVP）
1. セッション状態管理 + 録音モーダル
2. 録音からWhisper文字起こしまで
3. 挿入処理（直接 + フォールバック）
4. Ollama補正の組み込み
5. 設定画面（ショートカット/モデル）

## 9. 検証方針
- 正常系: 開始→停止→補正→挿入が1操作フローで完了
- 異常系: 各エラーで復帰可能かを確認
- 互換性: 主要入力先アプリで挿入できることを確認

## 10. 未決事項
- デフォルトショートカットの最終決定
- Ollama未起動時の自動起動要否
- 長時間録音の上限時間
