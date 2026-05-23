#!/bin/sh
set -eu

app_name="Gacha"
configuration="${CONFIGURATION:-release}"
output_dir="${OUTPUT_DIR:-build}"
app_path="$output_dir/$app_name.app"

swift build -c "$configuration"
bin_path="$(swift build -c "$configuration" --show-bin-path)"
executable_path="$bin_path/$app_name"

rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"

cp "App/Info.plist" "$app_path/Contents/Info.plist"
cp "$executable_path" "$app_path/Contents/MacOS/$app_name"
chmod 755 "$app_path/Contents/MacOS/$app_name"

cp -R "Sources/Gacha/Resources/." "$app_path/Contents/Resources/"

codesign --force --sign - --entitlements "App/Gacha.entitlements" "$app_path"

echo "$app_path"
