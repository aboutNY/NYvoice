# requirements.md

## 1. 目的
他アプリがアクティブな状態でも Escape キーで録音キャンセルできるようにする。

## 2. 背景
現状は `NSEvent.addLocalMonitorForEvents` で Escape を監視しており、NYvoice がアクティブな時しか反応しない。

## 3. 要求
- 録音中はフォーカスアプリに依存せず Escape でキャンセルできる
- キャンセル時のUI遷移は既存（Canceled表示後に閉じる）を維持する

## 4. 受け入れ基準
- 他アプリ前面でも Escape でキャンセルされる
- 既存テストが回帰しない
