# Issue: Accessibility is not granted が解消しない

## 1. 概要
`System Settings > Privacy & Security > Accessibility` で `NYvoiceApp` を許可済みでも、
`Run Environment Check` 実行時に `Accessibility permission is not granted` が継続表示される。

## 2. 発生日
- 2026-02-24

## 3. 影響
- テキスト挿入機能の前提チェックでエラーが残る
- 10.3（主要アプリ互換確認）の進行を阻害

## 4. 再現条件（現時点）
1. `NYvoiceApp` を起動
2. Accessibilityで `NYvoiceApp` をON
3. `Run Environment Check` 実行
4. `Accessibility permission is not granted` が表示される

## 5. ここまでの確認事項
- `.app` 起動で常駐することは確認済み
- `Run Environment Check` でのクラッシュ（`NSMicrophoneUsageDescription` 欠落）は修正済み
- それでも Accessibility 判定のみ false のまま残るケースがある

## 6. 仮説
- TCCの許可対象（bundle/path/signature）と実行中プロセスの不整合
- 再署名・再コピーにより既存許可エントリが無効化される
- `AXIsProcessTrusted()` 判定タイミング/対象の扱い差

## 7. 暫定回避策
- `/Applications/NYvoiceApp.app` の固定実体のみで起動する
- 許可エントリを削除して再追加し、再起動後に再チェック
- `tccutil reset Accessibility com.nyvoice.dev` 後に再許可

## 8. 恒久対応候補
- Environment Check にデバッグ情報を表示
  - 実行中の bundle id
  - 実行パス
  - `AXIsProcessTrusted()` の生値
- Accessibility判定導線を改善（許可対象の具体パス提示）
- ビルド/配布手順を固定し、署名の再現性を確保

## 9. ステータス
- Resolved (2026-02-24)
- 優先度: High

## 10. 完了条件
- Accessibility をONにした状態で `Run Environment Check` が `Accessibility permission is not granted` を表示しない
- 再起動後も同結果を再現可能

## 11. 原因（2026-02-24 特定）
- Accessibility判定が `AXIsProcessTrusted()` の単一評価だったため、許可反映タイミングや実体差分時の揺らぎに弱かった
- Environment Check の案内に「どの実行実体を許可すべきか」の情報がなく、許可対象の取り違えを検知できなかった

## 12. 修正内容（2026-02-24）
- `DefaultPermissionChecker` を `AXIsProcessTrustedWithOptions(prompt=false)` 優先の判定へ変更し、従来APIも併用
- `StartupDependencyChecker` でアクセシビリティ未許可時に以下のデバッグ情報を表示
  - 実行中 bundle id
  - 実行中 executable path
  - `AXIsProcessTrusted` / `AXIsProcessTrustedWithOptions` の生値

## 13. 解消確認（2026-02-24）
- `tccutil reset Accessibility com.nyvoice.dev` 実施後に `/Applications/NYvoiceApp.app` を再許可
- `Run Environment Check` 再実行で本エラーが表示されないことを確認
