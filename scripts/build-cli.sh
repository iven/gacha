#!/bin/sh
set -eu

app_name="Gacha"
cli_name="gacha"
configuration="${CONFIGURATION:-release}"
output_dir="${OUTPUT_DIR:-build}"
app_path="$output_dir/$app_name.app"

swift build -c "$configuration" --product GachaCLI
bin_path="$(swift build -c "$configuration" --show-bin-path)"

cp "$bin_path/GachaCLI" "$app_path/Contents/MacOS/$cli_name"
chmod 755 "$app_path/Contents/MacOS/$cli_name"

echo "$app_path/Contents/MacOS/$cli_name"
