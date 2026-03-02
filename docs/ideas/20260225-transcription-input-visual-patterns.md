# 音声文字起こしサービス調査: 入力中の視覚表現パターン

- 作成日: 2026-02-25
- 対象: 開発リスト No.2「音声入力中であることが視覚的に分かる波形表示を追加する」
- 目的: 既存サービスの「録音・入力中」可視化の実装パターンを抽出し、NYvoice のUI設計インプットを作る

## 調査対象（公式ヘルプ中心）

1. Notta（Instant Record / Real-time transcription）
2. Otter.ai（Live Notes）
3. Google Docs（Voice Typing）
4. Microsoft Word for Web（Dictate）
5. Apple Voice Memos（Mac, transcription表示）

## 観察結果サマリ

### 1. 「録音中」を示す明確な状態アイコン
- 多くのサービスで、マイクアイコンや録画インジケータを状態スイッチとして使う。
- 例:
  - Google Docs はマイクをクリックして開始/停止（待機と入力中の切り替えが明確）。
  - Microsoft Dictate は「マイクがONになったことを確認して話し始める」導線。
  - Otter Live Notes は Zoom 側の recording indicator（通知用途も兼ねる）。

示唆:
- NYvoiceでも「今は入力中」の単一で強いシグナル（色・点滅・ON表示）が必要。

### 2. 波形/音声アクティビティの動きで安心感を出す
- Otter のヘルプ上で、live transcribing と audio waveform が同時に見える説明がある。
- Apple Voice Memos では waveform 表示が基本UIとして常時使われ、transcription表示へ切り替える設計。

示唆:
- 波形は「録れている実感」を与える主要表現。
- 文字起こし結果を待つ前段階で、入力中フィードバックとして価値が高い。

### 3. リアルタイム文字列ストリームを同時提示
- Notta は録音と同時に real-time transcript を表示。
- Apple Voice Memos は録音中に transcription を表示し、現在語をハイライト。

示唆:
- 波形単体でも成立するが、将来的には「簡易テキストプレビュー」の追加余地が大きい。

### 4. 操作ボタン（Pause / Stop）を常時見える位置に配置
- Notta は録音中の下部中央に Pause/Stop を配置（Web/Mobileとも説明が一貫）。

示唆:
- NYvoiceの録音UIも、停止操作の視認性を高めると誤操作を減らせる。
- No.3（Esc終了）とも整合を取りやすい。

### 5. 表示モード切り替え（波形 ↔ 文字）
- Apple Voice Memos は、録音中に waveform と transcription をトグル切り替え。

示唆:
- MVPでは波形を優先し、将来拡張として「波形ビュー / テキストビュー」の切替設計が有効。

## パターン整理（抽象化）

- パターンA: `状態バッジ`（録音中ONを明確化）
- パターンB: `動的メーター`（波形・レベルメーター）
- パターンC: `テキストストリーム`（逐次文字起こし）
- パターンD: `即時操作`（Pause/Stopの常時表示）
- パターンE: `表示切替`（波形優先とテキスト優先のモード切替）

実運用では、A+B が最小構成として最も採用されやすく、C〜Eは段階導入される傾向。

## NYvoice No.2 への具体的示唆（MVP寄り）

- 最低限入れるべき要素
  - `録音中バッジ`（赤点 + 「録音中」）
  - `中央波形`（入力音量に応じてアニメーション）
- あると有効な補助要素
  - `経過時間`（既存UIと整合）
  - `停止方法ヒント`（例: 「Escで停止」はNo.3実装後に表示）
- 実装上の注意
  - 無音時も完全停止に見えないよう、ベース揺らぎを残す
  - 色だけに依存しない（形状・ラベルも併用）
  - 低負荷（描画更新間隔を制御）

## 参照リンク

- Notta Instant Record（2025-11-28更新）
  - https://support.notta.ai/hc/en-us/articles/15388442646939-Instant-Record
- Notta Disable real-time transcription（2025-07-30更新）
  - https://support.notta.ai/hc/en-us/articles/38227184907547-Disable-real-time-transcription
- Otter Live Notes（2026-02-12更新）
  - https://help.otter.ai/hc/en-us/articles/10474062838295-How-to-use-Otter-Live-Notes
- Google Docs: Type & edit with your voice
  - https://support.google.com/docs/answer/4492226
- Microsoft Dictate Help (Word for web)
  - https://support.microsoft.com/en-au/office/dictate-help-internal-78766431-0933-4603-abf5-5bcc1dee9dda
- Apple Voice Memos: View a transcription on Mac
  - https://support.apple.com/en-lamr/guide/voice-memos/vm4a03609f0d/mac

## メモ

- 本調査は「UI上でユーザーが入力中だと認識できる表現」に限定。
- 次ステップでは、このパターンを `.steering` 側の design/tasklist に落として実装粒度へ分解する。
