#!/usr/bin/env bash
# Validate Telegram video sticker constraints.
# Usage: scripts/validate.sh <file.webm> [more.webm...]
set -euo pipefail

MAX_BYTES=$((256 * 1024))
MAX_DURATION=3.0
MAX_FPS=30
MAX_SIDE=512
REQUIRED_SIDE=512

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <file.webm> [more.webm...]" >&2
  exit 1
fi

fail=0

check_one() {
  local file="$1"
  local errors=()

  if [[ ! -f "$file" ]]; then
    echo "FAIL  $file  (missing)"
    return 1
  fi

  local size codec audio w h duration fps pix_fmt alpha_mode
  size=$(stat -c%s "$file")
  codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file")
  audio=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$file" || true)
  w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$file")
  h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$file")
  duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file")
  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$file")
  pix_fmt=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$file")
  alpha_mode=$(ffprobe -v error -select_streams v:0 -show_entries stream_tags=alpha_mode -of csv=p=0 "$file")

  local fps_n fps_d fps_val
  fps_n="${fps%/*}"
  fps_d="${fps#*/}"
  if [[ "$fps" == */* && "$fps_d" != "0" ]]; then
    fps_val=$(awk -v n="$fps_n" -v d="$fps_d" 'BEGIN { printf "%.4f", n/d }')
  else
    fps_val="$fps"
  fi

  [[ "$file" == *.webm ]] || errors+=("container must be .webm")
  [[ "$codec" == "vp9" ]] || errors+=("codec is $codec, expected vp9")
  [[ -z "$audio" ]] || errors+=("audio stream present")
  awk -v d="$duration" -v m="$MAX_DURATION" 'BEGIN { exit !(d > m + 0.001) }' \
    && errors+=("duration ${duration}s > ${MAX_DURATION}s")
  awk -v f="$fps_val" -v m="$MAX_FPS" 'BEGIN { exit !(f > m + 0.001) }' \
    && errors+=("fps ${fps_val} > ${MAX_FPS}")
  (( size <= MAX_BYTES )) || errors+=("size ${size} bytes > ${MAX_BYTES}")
  (( w <= MAX_SIDE && h <= MAX_SIDE )) || errors+=("dimension ${w}x${h} exceeds ${MAX_SIDE}")
  (( w == REQUIRED_SIDE || h == REQUIRED_SIDE )) || errors+=("neither side is ${REQUIRED_SIDE} (${w}x${h})")
  # libvpx writes VP9 alpha as WebM tag alpha_mode=1; pix_fmt still reports yuv420p
  [[ "$alpha_mode" == "1" ]] || errors+=("missing VP9 alpha_mode=1 (got pix_fmt=$pix_fmt alpha_mode=${alpha_mode:-empty})")

  if (( ${#errors[@]} > 0 )); then
    echo "FAIL  $file"
    for e in "${errors[@]}"; do
      echo "      - $e"
    done
    return 1
  fi

  echo "OK    $file  ${w}x${h}  ${duration}s  ${fps_val}fps  ${size}B  $pix_fmt"
  return 0
}

for f in "$@"; do
  if ! check_one "$f"; then
    fail=1
  fi
done

exit "$fail"
