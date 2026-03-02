#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
APP_PATH="${APP_PATH:-$ROOT_DIR/dist/NYvoiceApp.app}"
SUBMIT_ZIP_PATH="${SUBMIT_ZIP_PATH:-$ROOT_DIR/dist/NYvoiceApp-notary-submit.zip}"
DIST_ZIP_PATH="${DIST_ZIP_PATH:-$ROOT_DIR/dist/NYvoiceApp.zip}"
NOTARY_PROFILE="${NOTARY_PROFILE:-NYVOICE_NOTARY}"
DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

require_cmd xcrun
require_cmd codesign
require_cmd ditto
require_cmd spctl
require_cmd security

if [ -z "$DEVELOPER_ID_APP" ]; then
  echo "error: DEVELOPER_ID_APP is empty." >&2
  echo "example: export DEVELOPER_ID_APP='Developer ID Application: Your Name (TEAMID)'" >&2
  exit 1
fi

if [ ! -d "$APP_PATH" ]; then
  echo "error: app not found: $APP_PATH" >&2
  exit 1
fi

if ! security find-identity -v -p codesigning | rg -F "$DEVELOPER_ID_APP" >/dev/null 2>&1; then
  echo "error: codesigning identity not found in keychain: $DEVELOPER_ID_APP" >&2
  exit 1
fi

echo "==> codesign app (hardened runtime + timestamp)"
codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APP" "$APP_PATH"

echo "==> verify signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | rg -n "Authority=|TeamIdentifier=|Timestamp="

echo "==> create zip for notarization submission"
rm -f "$SUBMIT_ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$SUBMIT_ZIP_PATH"

echo "==> submit to Apple notary service and wait"
xcrun notarytool submit "$SUBMIT_ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> staple ticket"
xcrun stapler staple "$APP_PATH"

echo "==> gatekeeper assessment"
spctl --assess --type execute -vv "$APP_PATH"

echo "==> create distributable zip from stapled app"
rm -f "$DIST_ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$DIST_ZIP_PATH"

echo "done"
echo "app: $APP_PATH"
echo "zip: $DIST_ZIP_PATH"
