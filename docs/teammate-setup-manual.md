# Teammate Setup Manual (NYvoice)

この手順書は、初回セットアップを「コピペで完了」できるように作成しています。  
記載どおりに実行してください。

## 1. この手順で実施すること
- NYvoiceアプリを `/Applications` に配置
- Ollama のインストールとモデル取得
- `whisper-cli`（whisper.cpp実行ファイル）とモデル配置
- NYvoiceの設定反映
- 権限付与（Microphone / Accessibility）
- 動作確認

## 2. 前提条件
- macOS
- 管理者権限を持つユーザー
- 配布された `NYvoiceApp.zip`
- インターネット接続（Ollamaモデル取得時のみ）

## 3. 先にまとめて実行するコマンド（そのままコピペ可）
以下をターミナルで順番に実行してください。

```bash
# 1) 配布Zipを展開して /Applications へ配置
cd ~/Downloads
unzip -o NYvoiceApp.zip
cp -R ./NYvoiceApp.app /Applications/NYvoiceApp.app

# 2) Homebrew が未導入ならインストール（導入済みならスキップ）
command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3) whisper.cpp をインストール
brew install whisper-cpp

# 4) whisperモデル配置ディレクトリ作成
mkdir -p "$HOME/whisper-models"

# 5) ベースモデルを取得（チーム配布モデルがある場合はこの行をスキップ可）
curl -L --fail -o "$HOME/whisper-models/ggml-large-v3-turbo.bin" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin

# 6) Ollama インストール（導入済みならスキップ）
brew install --cask ollama

# 7) Ollama 起動（既に起動中ならそのままでOK）
open -a Ollama

# 8) Ollama モデル取得（NYvoice既定）
ollama pull qwen2.5:7b
```

## 4. インストール結果の確認（コピペ可）
以下を実行し、エラーが出ないことを確認してください。

```bash
# whisper-cli のパス確認（Apple Silicon: /opt/homebrew/bin, Intel: /usr/local/bin）
which whisper-cli

# whisperモデル確認
ls -lh "$HOME/whisper-models/ggml-base.bin"

# Ollama API 応答確認（JSONが返ればOK）
curl -s http://127.0.0.1:11434/api/tags
```

## 5. NYvoice の初回起動
```bash
open -a /Applications/NYvoiceApp.app
```

初回起動でmacOSの警告が出た場合:
- 「開けない」と表示されたら `システム設定 > プライバシーとセキュリティ` の下部にある「このまま開く」を選択
- それでも起動できない場合は以下を実行後に再起動

```bash
xattr -dr com.apple.quarantine /Applications/NYvoiceApp.app
open -a /Applications/NYvoiceApp.app
```

## 6. NYvoice 設定値（UIにそのまま入力）
メニューバーのNYvoiceアイコンから `Open Settings` を開き、以下を設定して `Save` を押してください。

### 6.1 タブ: `音声認識モデル`
- `Whisper Binary Path`
  - Apple Silicon(M1/M2/M3...): `/opt/homebrew/bin/whisper-cli`
  - Intel Mac: `/usr/local/bin/whisper-cli`
- `Whisper Model Path`
  - `$HOME/whisper-models/ggml-base.bin`  
  - 実際に入力する場合の例: `/Users/<あなたのユーザー名>/whisper-models/ggml-base.bin`

### 6.2 タブ: `LLM修正`
- `Enable Correction`: ON（推奨）
- `Ollama Model`: `qwen2.5:7b`
- `Ollama Prompt Template`: 既定値のままで可（`{{transcript}}` を含むこと）

## 7. 権限付与（必須）
初回利用時に以下を必ず許可してください。

1. `Microphone` 許可
2. `Accessibility` 許可

許可できているか不安な場合は以下で確認:
- `System Settings > Privacy & Security > Microphone`
- `System Settings > Privacy & Security > Accessibility`
- どちらも `NYvoiceApp` がONになっていること

## 8. Environment Check 実行
メニューバーのNYvoiceアイコンから `Run Environment Check` を実行してください。  
エラーが表示されなければセットアップ完了です。

## 9. 動作確認（録音から挿入まで）
1. テキスト入力できるアプリ（メモ、Slack、Notionなど）を開く
2. カーソルを入力欄に置く
3. `Option` キーを素早く2回押して録音開始
4. もう一度 `Option` キーを素早く2回押して録音停止
5. 文字起こし結果が入力欄に挿入されることを確認

## 10. 問題が出たとき（症状別・コピペ可）

### 10.1 `Whisper binary not found or not executable`
```bash
which whisper-cli
ls -l "$(which whisper-cli)"
```
対処:
- `Open Settings > 音声認識モデル > Whisper Binary Path` を上記パスに修正

### 10.2 `Whisper model is not configured`
```bash
ls -lh "$HOME/whisper-models/ggml-base.bin"
```
対処:
- ファイルが無ければ再取得

```bash
mkdir -p "$HOME/whisper-models"
curl -L --fail -o "$HOME/whisper-models/ggml-base.bin" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin
```

### 10.3 `Ollama is not reachable`
```bash
open -a Ollama
curl -s http://127.0.0.1:11434/api/tags
```
対処:
- `curl` 応答がない場合、数秒待って再実行
- モデル未取得なら再取得

```bash
ollama pull qwen2.5:7b
```

### 10.4 `Accessibility permission is not granted`
対処手順:
1. `System Settings > Privacy & Security > Accessibility` で `NYvoiceApp` を一度OFF→ON
2. NYvoiceを終了して再起動
3. `Run Environment Check` を再実行

必要時のみ（最終手段）:
```bash
tccutil reset Accessibility com.nyvoice.dev
open -a /Applications/NYvoiceApp.app
```

### 10.5 録音はできるが文字が挿入されない
対処:
- Accessibility権限を再確認
- 入力欄が実際にフォーカスされているか確認
- `Run Environment Check` を再実行してエラー内容を確認

## 11. セットアップ完了チェックリスト
- `/Applications/NYvoiceApp.app` から起動できる
- `Run Environment Check` でエラーが出ない
- `Option` ダブルプレスで録音開始/停止できる
- 発話した内容が入力欄に挿入される

以上で初回セットアップは完了です。
