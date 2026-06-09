#!/bin/sh
set -eu

app_name="Gacha"
configuration="${CONFIGURATION:-release}"
output_dir="${OUTPUT_DIR:-build}"
app_path="$output_dir/$app_name.app"
icon_source="App/AppIcon.icon"

swift build -c "$configuration"
bin_path="$(swift build -c "$configuration" --show-bin-path)"
executable_path="$bin_path/$app_name"

rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"

cp "App/Info.plist" "$app_path/Contents/Info.plist"
cp "$executable_path" "$app_path/Contents/MacOS/$app_name"
chmod 755 "$app_path/Contents/MacOS/$app_name"

cp -R "Sources/Gacha/Resources/." "$app_path/Contents/Resources/"

icon_partial_plist="$(mktemp)"
trap 'rm -f "$icon_partial_plist"' EXIT
xcrun actool \
  --output-format human-readable-text \
  --notices --warnings \
  --app-icon AppIcon \
  --include-all-app-icons \
  --output-partial-info-plist "$icon_partial_plist" \
  --enable-on-demand-resources NO \
  --target-device mac \
  --minimum-deployment-target 15.0 \
  --platform macosx \
  --product-type com.apple.product-type.application \
  --bundle-identifier com.iven.gacha \
  --compile "$app_path/Contents/Resources" \
  "$icon_source" >/dev/null

codesign --force --sign - --entitlements "App/Gacha.entitlements" "$app_path"

echo "$app_path"
