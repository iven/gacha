#!/bin/sh
set -eu

app_name="Gacha"
configuration="${CONFIGURATION:-release}"
output_dir="${OUTPUT_DIR:-build}"
version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" App/Info.plist)"
app_path="$output_dir/$app_name.app"
dmg_root="$output_dir/dmg-root"
dmg_path="$output_dir/$app_name-$version.dmg"

rm -rf "$dmg_root" "$dmg_path"
mkdir -p "$dmg_root"

ditto "$app_path" "$dmg_root/$app_name.app"
ln -s /Applications "$dmg_root/Applications"

hdiutil create \
  -volname "$app_name" \
  -srcfolder "$dmg_root" \
  -ov \
  -format UDZO \
  "$dmg_path"

hdiutil verify "$dmg_path"

echo "$dmg_path"
