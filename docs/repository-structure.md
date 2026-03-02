# Repository Structure

## 1. 目的
本書は、macOS音声入力文字起こしアプリ（Swift）のリポジトリ構造と各ディレクトリの責務を定義する。

## 2. 設計方針
- アプリ本体、ドメイン、インフラ連携を分離する
- テスト対象を明確にするため、機能単位でモジュールを分ける
- 外部依存（Whisper.cpp/Ollama）との境界をAdapter層に集約する

## 3. 推奨ディレクトリ構成
```text
NYvoice/
  docs/
    product-requirements.md
    functional-design.md
    architecture.md
    repository-structure.md
    development-guidelines.md
    glossary.md
    distribution-guide.md
    ideas/

  .steering/
    YYYYMMDD-task-name/
      requirements.md
      design.md
      tasklist.md

  app/
    NYvoiceApp/
      App/
        NYvoiceApp.swift
        AppDelegate.swift
        MenuBarController.swift
      Presentation/
        RecordingModal/
        Settings/
        SharedUI/
      Application/
        SessionController/
        UseCases/
      Domain/
        Entities/
        ValueObjects/
        Services/
        Errors/
      Infrastructure/
        Audio/
        Whisper/
        Ollama/
        InputInsertion/
        Shortcut/
        SettingsStore/
        Logging/
      Resources/
        Assets.xcassets
        Info.plist
      Support/
        Constants/
        Extensions/

  tests/
    Unit/
      Application/
      Domain/
      Infrastructure/
    Integration/
      SessionFlow/
      ExternalAdapters/
    Fixtures/
      Audio/
      Text/

  scripts/
    setup/
    dev/
    release/

  third_party/
    whisper.cpp/
    models/

  .github/
    workflows/

  README.md
```

## 4. 各領域の責務
### 4.1 `app/NYvoiceApp/App`
- エントリーポイント
- ライフサイクル管理
- メニューバー常駐初期化

### 4.2 `app/NYvoiceApp/Presentation`
- SwiftUI/AppKitベースUI
- 録音モーダルと設定画面
- ViewModelを通じた状態反映

### 4.3 `app/NYvoiceApp/Application`
- ユースケース実行
- セッション状態遷移の制御
- PresentationとDomainの調停

### 4.4 `app/NYvoiceApp/Domain`
- ルールと概念モデル
- 外部ライブラリ非依存の純粋ロジック
- エラー型やValueObject定義

### 4.5 `app/NYvoiceApp/Infrastructure`
- OS API、外部プロセス、HTTP連携
- Whisper.cpp/Ollama/入力挿入の実装
- 永続化、ログ出力

### 4.6 `tests/`
- Unit: ドメインとアプリケーション層の検証
- Integration: 外部連携を含むフロー検証
- Fixtures: テスト用音声・テキスト

### 4.7 `scripts/`
- 環境構築、開発補助、配布準備を自動化

### 4.8 `third_party/`
- 外部同梱資産を管理
- Whisper.cpp関連アセットやモデル配置

## 5. 命名規約
- 型名: `UpperCamelCase`
- 関数/変数: `lowerCamelCase`
- ファイル名: 型名と一致
- プロトコル: `~ing` または `~Service` など責務が分かる命名

## 6. 依存ルール
- Presentation -> Application -> Domain の一方向依存
- InfrastructureはDomain/Applicationのプロトコル実装を担当
- Domainは他層に依存しない

## 7. 設定ファイルと機密情報
- 開発用設定は `app/NYvoiceApp/Resources/` 配下に配置
- 機密情報はリポジトリに含めない
- ローカル設定の上書きは `.gitignore` 対象ファイルで管理

## 8. ドキュメント運用
- 仕様変更時は `docs/` を先に更新する
- 実装タスクは `.steering/` を単位として管理する
- 変更履歴はPR説明とコミットメッセージで追跡する

## 9. 将来拡張の余地
- モジュール分割をSwift Package化して段階的に独立可能
- UIを機能別にFeature単位へ再編可能
- モデル配布戦略変更時も`Infrastructure`配下の調整で吸収可能
