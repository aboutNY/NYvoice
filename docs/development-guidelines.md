# Development Guidelines

## 1. 目的
本書は、NYvoiceプロジェクトの開発時に守る実装・レビュー・検証の基準を定義する。

## 2. 基本方針
- 仕様先行: 実装前に `docs/` と `.steering/` を更新する
- 小さく進める: 変更は小さな単位で実装し、都度動作確認する
- 失敗に備える: 権限不足や外部依存失敗のケースを先に考慮する
- ローカル完結: 音声・テキスト処理はローカルを原則とする

## 3. 必須開発フロー
1. `Agents.md` と関連 `docs/` を確認する
2. `.steering/YYYYMMDD-task-name/` を作成する
3. `requirements.md` -> `design.md` -> `tasklist.md` を作成する
4. `tasklist.md` に従って実装する
5. 実装と同時にテスト/動作確認を行う
6. 結果に応じて `tasklist.md` と `docs/` を更新する

## 4. ブランチ・コミット方針
- ブランチ名は作業内容が判別できる命名にする
- 1コミット1意図を基本とする
- コミットメッセージは「何を」「なぜ」を含める

## 5. コーディングガイド（Swift）
### 5.1 設計原則
- 単一責務を守る
- UI層にビジネスロジックを持ち込まない
- 外部依存はProtocolで抽象化し、差し替え可能にする

### 5.2 命名
- 型名: `UpperCamelCase`
- メソッド/変数: `lowerCamelCase`
- Boolは `is/has/can` で始める
- 略語を避け、意図が分かる名前を使う

### 5.3 エラー処理
- `do-catch` で握りつぶさない
- ユーザー向け文言と技術詳細を分離する
- 失敗時のフォールバック手段を明示する

### 5.4 非同期処理
- 長時間処理（録音後変換、LLM補正）はUIスレッドをブロックしない
- キャンセル可能な処理はキャンセル手段を提供する

## 6. 外部依存連携の規約
### 6.1 Whisper.cpp
- 実行バイナリ呼び出しはAdapter層に集約する
- プロセス終了コードとstderrをログに残す
- モデル未配置時は起動時または実行前に検出する

### 6.2 Ollama
- API呼び出し失敗時はリトライ方針を明確化する
- 補正結果が空や異常な場合は生文字起こしへフォールバック可能にする
- プロンプトは「意味維持」を明示する

### 6.3 テキスト挿入
- 直接挿入失敗時にクリップボードフォールバックを実装する
- アクセシビリティ権限不足時は設定誘導を行う

## 7. テスト方針
### 7.1 Unit Test
- Domain/Applicationを中心にロジックを検証する
- 状態遷移とエラー分岐を重点的にテストする

### 7.2 Integration Test
- Sessionの正常系フロー（開始→停止→文字起こし→補正→挿入）
- 外部依存失敗時のフォールバックフロー

### 7.3 手動確認
- 主要アプリ（エディタ、チャット）への挿入成功を確認する
- 初回権限導線（マイク、アクセシビリティ）を確認する

## 8. ログ/観測性
- セッションID単位で追跡可能なログを残す
- ログレベルを `debug/info/error` で分類する
- 機微情報（生音声、全文テキスト）の恒久保存を避ける

## 9. パフォーマンス目標（MVP）
- 停止後から結果表示までの待機を短く保つ
- 長時間録音でメモリ使用量が過剰に増えないこと

## 10. レビュー基準
- 仕様（docs/.steering）と実装差分が一致している
- エラー処理とフォールバックが実装されている
- テストまたは手動確認結果が記録されている
- 不要な依存追加がない

## 11. ドキュメント更新ルール
- 仕様変更を伴う実装は必ず `docs/` を更新する
- 作業中は `tasklist.md` の進捗を随時更新する
- レビュー指摘で仕様が変わる場合は先に文書を修正する

## 12. リリース反映手順（再現性確保）
`/Applications/NYvoiceApp.app` へ最新修正を反映する際は、依存関係のある処理を**必ず直列**で実行する。`build` と `copy` を並列実行しない。

### 12.1 標準手順（必須）
1. `swift build -c release`
2. `cp "$PWD/.build/release/NYvoiceApp" "$PWD/dist/NYvoiceApp.app/Contents/MacOS/NYvoiceApp"`
3. `cp "$PWD/.build/release/NYvoiceApp" "/Applications/NYvoiceApp.app/Contents/MacOS/NYvoiceApp"`
4. `codesign --force --deep --sign - /Applications/NYvoiceApp.app`
5. `open -a /Applications/NYvoiceApp.app`

### 12.2 反映確認（必須）
- `ps ax -o pid=,command= | rg "NYvoiceApp.app/Contents/MacOS/NYvoiceApp"` で実行実体を確認
- `strings /Applications/NYvoiceApp.app/Contents/MacOS/NYvoiceApp | rg "<変更した表示文言>"` で反映内容を確認
- `codesign --verify --deep --strict --verbose=2 /Applications/NYvoiceApp.app` が成功することを確認
