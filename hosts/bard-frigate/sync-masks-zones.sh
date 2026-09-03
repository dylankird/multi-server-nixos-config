#!/usr/bin/env bash
# Pulls the live motion masks / zones / object-filter masks Frigate is
# currently running with (as last saved via the web UI's mask/zone editor)
# and writes hosts/bard-frigate/masks-zones.json, which default.nix merges
# into each camera's declarative config.
#
# Run this ON bard-frigate itself (e.g. over ssh) with a git checkout of
# this repo. Reads Frigate's live runtime config straight off disk — no
# API/login involved.
#
# GENERATED FILE OUTPUT — masks-zones.json is fully overwritten each run,
# never hand-edit it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_FILE="$SCRIPT_DIR/masks-zones.json"
RUNTIME_CONFIG="${FRIGATE_RUNTIME_CONFIG:-/run/frigate/frigate.yml}"

RAW_YAML=$(sudo cat "$RUNTIME_CONFIG") \
  || { echo "Couldn't read $RUNTIME_CONFIG (is frigate.service running?)" >&2; exit 1; }

FULL_JSON=$(printf '%s' "$RAW_YAML" | yq -o=json '.' -)

echo "$FULL_JSON" | jq -S '
  .cameras
  | to_entries
  | map({
      key: .key,
      value: (
        (if (.value.motion.mask? // null) != null then {motion: {mask: .value.motion.mask}} else {} end)
        * (if (.value.zones? // {}) != {} then {zones: .value.zones} else {} end)
        * (if (.value.objects.mask? // null) != null then {objects: {mask: .value.objects.mask}} else {} end)
        * (
            (.value.objects.filters? // {})
            | to_entries
            | map(select((.value.mask? // null) != null))
            | if length > 0
              then {objects: {filters: (map({key, value: {mask: .value.mask}}) | from_entries)}}
              else {}
              end
          )
      )
    })
  | map(select(.value != {}))
  | from_entries
' > "$OUT_FILE"

echo "Wrote $OUT_FILE"
git -C "$SCRIPT_DIR/../.." --no-pager diff -- hosts/bard-frigate/masks-zones.json || true
