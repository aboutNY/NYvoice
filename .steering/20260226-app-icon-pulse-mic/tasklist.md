# tasklist.md

## 1. ステアリング作成
- [x] 1.1 requirements.md を作成
- [x] 1.2 design.md を作成
- [x] 1.3 tasklist.md を作成

## 2. 実装
- [x] 2.1 Pulse Mic 1024マスターを調整
- [x] 2.2 32px 簡略版を作成
- [x] 2.3 16px 簡略版を作成
- [x] 2.4 menu bar template（18px）を作成
- [x] 2.5 README に用途・使い分けを追記

## 3. 検証
- [x] 3.1 ファイル配置と命名を確認
- [x] 3.2 tasklist チェックを最終更新

## 4. 実装追補（反映）
- [x] 4.1 `scripts/release/generate-icons.sh` を追加（SVG -> iconset PNG / menu template PNG）
- [x] 4.2 `MenuBarController` を template 画像読み込み方式へ変更
- [x] 4.3 `iconutil` による `AppIcon.icns` 生成
- [x] 4.4 `swift build` でビルド確認

## 5. 配布反映
- [x] 5.1 `swift build -c release` で本番ビルド作成
- [x] 5.2 `dist/NYvoiceApp.app` にバイナリ・Info.plist・Resourcesを反映
- [x] 5.3 `/Applications/NYvoiceApp.app` に反映し再署名
- [x] 5.4 起動確認（実行プロセスが `/Applications/NYvoiceApp.app/Contents/MacOS/NYvoiceApp`）
- [x] 5.5 `codesign --verify --deep --strict` で検証成功

## 6. 追加調査（Accessibility回帰）
- [x] 6.1 `CFBundleIdentifier` を `local.nyvoice.app` から `com.nyvoice.dev` に戻す
- [x] 6.2 `dist` と `/Applications` に再反映・再署名
- [x] 6.3 `tccutil reset Accessibility com.nyvoice.dev` / `local.nyvoice.app` を実施
