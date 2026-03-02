# Issue: Whisper binary / model 未設定で Environment Check が失敗する

## 1. 概要
`Run Environment Check` 実行時に以下2件のエラーが表示される。

1. `Whisper binary not found or not executable`
2. `Whisper model is not configured`

## 2. 発生日
- 2026-02-24

## 3. 影響
- 音声文字起こし機能（Whisper.cpp）が実行できない
- 録音後フローが `Transcription failed` で停止する可能性がある

## 4. 再現条件
1. NYvoice を起動
2. Settings で `Whisper binary path` / `Whisper model path` が未設定、または誤ったパス
3. `Run Environment Check` を実行
4. 上記2件のエラーが表示される

## 5. 原因
- `Whisper binary path` が存在しない、または実行権限のないファイルを指している
- `Whisper model path` が未設定、またはモデルファイルが存在しない

## 6. 対応手順
1. Whisper.cpp 実行ファイルをインストール
   - 例: `brew install whisper-cpp`
2. モデルファイルを配置
   - 例: `$HOME/whisper-models/ggml-base.bin`
3. Settings で以下を設定して保存
   - `Whisper binary path`: `/opt/homebrew/bin/whisper-cli`（Intel Mac は `/usr/local/bin/whisper-cli` の場合あり）
   - `Whisper model path`: `$HOME/whisper-models/ggml-base.bin`
4. `Run Environment Check` を再実行

## 7. 完了条件
- `Run Environment Check` で以下2件が表示されない
  - `Whisper binary not found or not executable`
  - `Whisper model is not configured`
- 実際に録音→停止→文字起こしが成功する

## 8. ステータス
- Resolved (2026-02-24)
- 優先度: High

## 9. 解消確認（2026-02-24）
- Settings 画面で以下を設定し保存
  - `Whisper binary path`: 実行可能な `whisper-cli` の絶対パス
  - `Whisper model path`: 既存 `ggml-*.bin` ファイルの絶対パス
- `Run Environment Check` 再実行で以下2件が表示されないことを確認
  - `Whisper binary not found or not executable`
  - `Whisper model is not configured`
