# design.md

## 1. 方針
`SessionState` にキャンセル表示専用状態を追加し、短時間表示後に `idle` へ戻す。

## 2. 実装
- `SessionState` に `cancelling` を追加
- `SessionController`
  - `cancelRecording()` を追加（録音停止後、文字起こしせずキャンセル表示）
  - 無音判定時も `cancelling` 経由で終了
  - 共通の `showCancelledThenReturnToIdle` を実装
- `RecordingModalView`
  - `cancelling` 状態のUIを追加（キャンセルメッセージ）
- `AppDelegate`
  - ローカルキーダウン監視を追加し、`Escape` 押下時に `cancelRecording()` を呼ぶ

## 3. 影響範囲
- app/NYvoiceApp/Domain/Entities/SessionState.swift
- app/NYvoiceApp/Application/SessionController/SessionController.swift
- app/NYvoiceApp/Presentation/RecordingModal/RecordingModalView.swift
- app/NYvoiceApp/App/AppDelegate.swift
- tests/Integration/SessionFlow/SessionControllerIntegrationTests.swift

## 4. 検証
- swift test
- 実機で無音キャンセルとEscapeキャンセルの表示遷移を確認
