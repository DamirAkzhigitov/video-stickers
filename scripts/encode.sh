#!/usr/bin/env bash
# Encode a source video to a Telegram video sticker (.webm VP9).
# Usage: scripts/encode.sh <input> <output.webm> [--start SECONDS]
set -euo pipefail

MAX_DURATION="2.90"
MAX_BYTES=$((256 * 1024))
MAX_SIDE=512
FPS=24
CRF_STEPS=(24 28 32 36 40 44 48 52 56 63)

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <input> <output.webm> [--start SECONDS]" >&2
  exit 1
fi

IN="$1"
OUT="$2"
START=""
shift 2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --start)
      START="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$IN" ]]; then
  echo "Input not found: $IN" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

START_ARGS=()
if [[ -n "$START" ]]; then
  START_ARGS=(-ss "$START")
fi

SCALE="scale='if(gte(iw,ih),${MAX_SIDE},-2)':'if(gte(ih,iw),${MAX_SIDE},-2)'"
VF="${SCALE},fps=${FPS},format=yuva420p"

echo "Encoding $IN -> $OUT"

last_size=0
for crf in "${CRF_STEPS[@]}"; do
  echo "  pass CRF ${crf}..."
  ffmpeg -y -hide_banner -loglevel error \
    "${START_ARGS[@]}" \
    -i "$IN" \
    -t "$MAX_DURATION" \
    -an \
    -vf "$VF" \
    -c:v libvpx-vp9 \
    -pix_fmt yuva420p \
    -deadline good \
    -cpu-used 2 \
    -row-mt 1 \
    -auto-alt-ref 0 \
    -lag-in-frames 0 \
    -b:v 0 -crf "$crf" \
    "$OUT"

  last_size=$(stat -c%s "$OUT")
  echo "    size ${last_size} bytes (limit ${MAX_BYTES})"
  if (( last_size <= MAX_BYTES )); then
    echo "OK  ${OUT}  CRF=${crf}  ${last_size} bytes"
    exit 0
  fi
done

echo "FAILED  ${OUT} still ${last_size} bytes after CRF 63 (limit ${MAX_BYTES})" >&2
exit 1
