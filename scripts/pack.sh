#!/usr/bin/env bash
# Usage: ./scripts/pack.sh mods/<mod_name>
# Packages a mod folder into dist/<mod_name>.zip

set -euo pipefail

MOD_DIR="${1:?Usage: pack.sh <mod_dir>}"
MOD_NAME="$(basename "$MOD_DIR")"
DIST_DIR="$(dirname "$0")/../dist"

if [[ ! -d "$MOD_DIR" ]]; then
  echo "Error: '$MOD_DIR' is not a directory." >&2
  exit 1
fi

if [[ ! -f "$MOD_DIR/info.json" ]]; then
  echo "Error: '$MOD_DIR/info.json' not found." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
OUT="$DIST_DIR/${MOD_NAME}.zip"

# Build zip from inside the mod folder so paths inside the zip are relative
(cd "$MOD_DIR" && zip -r "$OLDPWD/$OUT" .)

echo "Packed: $OUT"
