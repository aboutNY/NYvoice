# NYvoice

macOS メニューバー常駐の音声入力アプリです。  
Whisper.cpp で文字起こしし、必要に応じて Ollama で文脈補正します。

## 必要環境
- macOS
- Xcode（推奨）または Xcode Command Line Tools
- Homebrew
- `whisper-cli`（`brew install whisper-cpp`）
- Ollama（`brew install --cask ollama`）

## セットアップ（初回）
以下を上から順にそのまま実行してください。

```bash
# 1) clone
mkdir -p "$HOME/work"
cd "$HOME/work"
git clone https://github.com/aboutNY/NYvoice.git
cd NYvoice

# 2) Xcode ツールチェーンを選択（推奨）
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# 3) 依存インストール
command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install whisper-cpp
brew install --cask ollama

# 4) Whisper モデル配置
mkdir -p "$HOME/whisper-models"
curl -L --fail -o "$HOME/whisper-models/ggml-base.bin" \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin

# 5) Ollama 起動とモデル取得
open -a Ollama
ollama pull qwen2.5:7b

# 6) build
swift build -c release
```

## アプリ起動
`dist/NYvoiceApp.app` が無い環境向けに、`.app` バンドルを生成して起動します。

```bash
cd "$HOME/work/NYvoice"
mkdir -p dist/NYvoiceApp.app/Contents/MacOS
mkdir -p dist/NYvoiceApp.app/Contents/Resources
cp .build/release/NYvoiceApp dist/NYvoiceApp.app/Contents/MacOS/NYvoiceApp
cp app/NYvoiceApp/Resources/Info.plist dist/NYvoiceApp.app/Contents/Info.plist
cp app/NYvoiceApp/Resources/Icons/AppIcon.icns dist/NYvoiceApp.app/Contents/Resources/AppIcon.icns
cp app/NYvoiceApp/Resources/Icons/MenuBarTemplate.png dist/NYvoiceApp.app/Contents/Resources/MenuBarTemplate.png
codesign --force --deep --sign - dist/NYvoiceApp.app
open -a "$PWD/dist/NYvoiceApp.app"
```

`/Applications` 配下で使う場合:

```bash
cp -R "$HOME/work/NYvoice/dist/NYvoiceApp.app" /Applications/NYvoiceApp.app
codesign --force --deep --sign - /Applications/NYvoiceApp.app
open -a /Applications/NYvoiceApp.app
```

## 初期設定（アプリ起動後）
`Open Settings` で以下を設定し `Save`:

- `Whisper Binary Path`
  - Apple Silicon: `/opt/homebrew/bin/whisper-cli`
  - Intel: `/usr/local/bin/whisper-cli`
- `Whisper Model Path`
  - `/Users/<ユーザー名>/whisper-models/ggml-base.bin`
- `Enable Correction`: ON
- `Ollama Model`: `qwen2.5:7b`

権限付与:
- `Microphone`
- `Accessibility`

その後、メニューから `Run Environment Check` を実行。

## 使い方
- 録音開始: `Option` キーを素早く 2 回
- 録音停止: `Option` キーを素早く 2 回
- テキスト入力欄に結果が挿入されます

## 更新手順
```bash
cd "$HOME/work/NYvoice"
git pull
swift build -c release
cp .build/release/NYvoiceApp dist/NYvoiceApp.app/Contents/MacOS/NYvoiceApp
open -a "$PWD/dist/NYvoiceApp.app"
```

## トラブルシュート

### 1. `Invalid manifest` / `Undefined symbols ... PackageDescription`
Swift ツールチェーンの不整合です。Xcode側を使ってください。

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcode-select -p
xcrun --find swiftc
swift --version
```

期待値:
- `xcode-select -p` が `/Applications/Xcode.app/Contents/Developer`
- `swiftc` が `/Applications/Xcode.app/...` 配下

### 2. `cp ... dist/NYvoiceApp.app/... No such file or directory`
`dist/NYvoiceApp.app` がまだ存在しないためです。  
上記「アプリ起動」の `.app` 生成コマンドを実行してください。

### 3. `Ollama is not reachable`
```bash
open -a Ollama
curl -s http://127.0.0.1:11434/api/tags
ollama pull qwen2.5:7b
```

### 4. `Whisper binary not found or not executable`
```bash
which whisper-cli
ls -l "$(which whisper-cli)"
```

### 5. `Whisper model is not configured`
```bash
ls -lh "$HOME/whisper-models/ggml-base.bin"
```

