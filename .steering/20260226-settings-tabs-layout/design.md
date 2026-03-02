# design.md

## 1. UI構成
- `SettingsView` を `Form` から `VStack + segmented Picker` に変更
- タブ状態は `SettingsTab` enum で管理

## 2. サイズ設計
- `SettingsView` に `minWidth: 720, minHeight: 500`
- `AppDelegate` の設定ウィンドウを 720x500 固定に設定
- `NYvoiceApp` の `Settings` scene も 720x500 に揃える

## 3. データ連携
- 既存 `AppSettings` バインディングを継続利用し、保存処理は変更しない
