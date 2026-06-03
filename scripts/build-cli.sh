#!/bin/sh
set -eu

app_name="Gacha"
cli_name="gacha-cli"
configuration="${CONFIGURATION:-release}"
output_dir="${OUTPUT_DIR:-build}"
app_path="$output_dir/$app_name.app"

swift build -c "$configuration" --product "$cli_name"
bin_path="$(swift build -c "$configuration" --show-bin-path)"

cp "$bin_path/$cli_name" "$app_path/Contents/MacOS/$cli_name"
chmod 755 "$app_path/Contents/MacOS/$cli_name"

# Re-sign the bundle so the seal covers the freshly added CLI binary.
codesign --force --sign - --entitlements "App/Gacha.entitlements" "$app_path"

echo "$app_path/Contents/MacOS/$cli_name"
