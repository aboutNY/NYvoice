# design.md

## 1. 設計方針
- 形状は「丸角スクエア背景 + マイク本体 + パルスリング」の3要素に限定する。
- サイズが小さくなるほど要素を減らし、線幅と余白を優先する。
- menu bar template は塗りのみで構成し、システムの tint 適用に耐える。

## 2. 成果物配置
- `docs/ideas/20260226-icon-roughs/pulse-mic-minimal.svg`（1024 マスター）
- `docs/ideas/20260226-icon-roughs/pulse-mic-minimal-32.svg`
- `docs/ideas/20260226-icon-roughs/pulse-mic-minimal-16.svg`
- `docs/ideas/20260226-icon-roughs/pulse-mic-template-18.svg`
- `docs/ideas/20260226-icon-roughs/README.md` 更新

## 3. 形状ルール
### 3.1 1024 マスター
- 角丸背景は高コントラストのダークトーン
- パルスリングは1本のみ（多重リング禁止）
- マイクは楕円ベースのシンプル形状

### 3.2 32 / 16 簡略版
- グラデーションを排除（単色背景）
- 細線・半透明効果を減らす
- マイク脚部を短縮し、中心可読性を優先

### 3.3 template 18
- 背景なし / 単色
- マイクとアーチを同色で統一
- 18x18 のメニューバー表示を想定

## 4. 検証方針
- SVG の viewBox とサイズ定義を固定し、意図したピクセルサイズと一致することを確認
- README に用途を明記し、次工程（PNG/icns 化）の入口を揃える

## 5. リスクと対応
- リスク: 16px で潰れる
- 対応: 16px 専用ファイルで要素削減
- リスク: template が細く見えづらい
- 対応: 線より塗り中心のシルエットを採用
