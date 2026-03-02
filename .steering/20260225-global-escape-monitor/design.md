# design.md

## 1. 方針
Escape監視をローカルイベント監視からグローバルイベント監視へ置き換える。

## 2. 実装
- `AppDelegate` の Escape 監視を `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` へ変更
- 録音中 (`SessionState.recording`) の時のみ `cancelRecording()` を呼ぶ
- モーダル表示中のみ監視を有効化し、閉じたら解除する

## 3. 影響範囲
- app/NYvoiceApp/App/AppDelegate.swift

## 4. 検証
- swift test
- 実機で他アプリ前面時の Escape キャンセル確認
