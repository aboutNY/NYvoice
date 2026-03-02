# design.md

## 1. 検知方式
- `NSEventShortcutManager` の長押しタイマー方式を廃止
- `.flagsChanged` とポーリングで Option 押下エッジを検知
- 初回押下時刻を保持し、閾値内の2回目押下でトグル発火

## 2. 状態管理
- 管理状態を `isOptionPressed` と `lastOptionTapAt` に集約
- Option 以外の修飾キーが混在する入力は無視
- ダブルタップ成立後は `lastOptionTapAt` をクリアし誤連続発火を防ぐ

## 3. UI反映
- `SettingsView` の案内文を Alt ダブルタップへ変更
- `MenuBarController` のメニュー文言を Alt ダブルタップへ変更
