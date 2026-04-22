#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN_DEFAULT="/Users/glenlim/Downloads/Godot.app/Contents/MacOS/Godot"
GODOT_BIN="${GODOT_BIN:-$GODOT_BIN_DEFAULT}"
EXPORT_NAME="Birthday Present"
EXPORT_PRESET="macOS"
TEMP_APP="/private/tmp/${EXPORT_NAME}.app"
DESKTOP_APP="$HOME/Desktop/${EXPORT_NAME}.app"
TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates/4.6.2.stable"

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "Godot binary not found or not executable: $GODOT_BIN" >&2
	echo "Set GODOT_BIN=/path/to/Godot before running this script." >&2
	exit 1
fi

if [[ ! -f "$PROJECT_DIR/export_presets.cfg" ]]; then
	echo "Missing export_presets.cfg in $PROJECT_DIR" >&2
	exit 1
fi

if [[ ! -f "$TEMPLATE_DIR/macos.zip" ]]; then
	echo "Missing macOS export template: $TEMPLATE_DIR/macos.zip" >&2
	echo "Install Godot 4.6.2 export templates first." >&2
	exit 1
fi

echo "Exporting $EXPORT_NAME.app with preset \"$EXPORT_PRESET\"..."
rm -rf "$TEMP_APP"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "$EXPORT_PRESET" "$TEMP_APP"

if [[ ! -d "$TEMP_APP" ]]; then
	echo "Export did not produce $TEMP_APP" >&2
	exit 1
fi

echo "Copying app to Desktop..."
rm -rf "$DESKTOP_APP"
cp -R "$TEMP_APP" "$DESKTOP_APP"

echo "Done: $DESKTOP_APP"
echo "If macOS blocks the first launch, right-click the app and choose Open."
