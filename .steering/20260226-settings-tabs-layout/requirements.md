# requirements.md

## 1. 目的
設定画面が縦長で見づらい問題を解消し、設定項目を2タブで分離して操作性を改善する。

## 2. 要件
- 設定ウィンドウの表示サイズを見やすい固定サイズへ変更する
- 設定画面を「音声認識モデル」「LLM修正」の2タブにする
- 音声認識モデルタブ: Whisper Binary Path, Whisper Model Path
- LLM修正タブ: Enable Collections, Ollama Model, Ollama Prompt Template

## 3. 受け入れ基準
- 既存の設定保存/読み込みが継続動作する
- タブ切替で対象項目のみ表示される
- ウィンドウサイズが極端に縦長にならない
