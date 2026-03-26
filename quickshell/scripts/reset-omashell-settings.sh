#!/usr/bin/env bash
set -euo pipefail

ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
SETTINGS_DIR="$ROOT/settings"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
BACKUP_DIR="$SETTINGS_DIR/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$SETTINGS_DIR" "$BACKUP_DIR"

HAD_BACKUP=0
if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "$BACKUP_DIR/settings.$STAMP.json.bak"
  HAD_BACKUP=1
fi

cat > "$SETTINGS_FILE" <<'EOF'
{
  "notificationPosition": "top-center",
  "osdPosition": "bottom-center",
  "barPosition": "top",
  "barStyle": "dock",
  "workspaceStyle": "og",
  "launcherIconPreset": "command",
  "launcherIconSize": 12,
  "rememberSettingsWindowPosition": false,
  "openSettingsOnGeneralAlways": true
}
EOF

printf 'Omashell settings were reset to defaults.\n'
if [ "$HAD_BACKUP" -eq 1 ]; then
  printf 'Backup: %s\n' "$BACKUP_DIR/settings.$STAMP.json.bak"
fi
