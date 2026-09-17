# Telegram video stickers

Local pipeline for encoding VP9 `.webm` stickers that Telegram will accept. No remote is set up; this is a local git repo.

Official rules: [video sticker encoding](https://core.telegram.org/stickers/webm-vp9-encoding).

## What already works

First sticker: **smug** (`dist/smug.webm`), uploaded successfully via @Stickers.

| | Source `source/smug.mp4` | Sticker `dist/smug.webm` |
| --- | --- | --- |
| Format | H.264 MP4 + AAC audio | VP9 WebM, no audio, `alpha_mode=1` |
| Size | 480×640 | 384×512 (height is 512) |
| Length | 6.04s | 2.92s |
| FPS | 24 | 24 |
| File size | ~1.4 MB | 240356 bytes (~235 KB) |

Telegram rejects clips over 3s, so this pack used the **last 2.9s** (`--start 3.10`) — the smug hold — instead of speeding up the whole selfie. That loops on the expression instead of jumping from smirk back to a neutral face.

Encode command that produced the accepted file:

```bash
scripts/encode.sh source/smug.mp4 dist/smug.webm --start 3.10
```

CRF 24 fit under 256 KB. `ffprobe` still reports `pix_fmt=yuv420p` for VP9; Telegram cares about the WebM tag `alpha_mode=1`, which `-pix_fmt yuva420p -auto-alt-ref 0` sets.

Suggested emoji: 😏

## Layout

```
source/     masters (mp4/mov/…)
dist/       final .webm stickers
scripts/    encode.sh, validate.sh
pack.yaml   sticker list and emoji
PLAN.md     original pack plan
```

`.preview/` is ffmpeg frame dumps for inspection. It is gitignored.

## Add another sticker

1. Put the master in `source/`, short name, no spaces (`wave.mp4`).
2. If the clip is longer than 3s, pick a start time for the best 2.9s, or omit `--start` to take the beginning.
3. Encode and check:

```bash
scripts/encode.sh source/wave.mp4 dist/wave.webm
# or: scripts/encode.sh source/wave.mp4 dist/wave.webm --start 1.20

scripts/validate.sh dist/wave.webm
```

4. Add a row in `pack.yaml`.
5. In Telegram, open [@Stickers](https://t.me/Stickers) and send the new `.webm` into the existing video pack (or `/newvideo` for a new pack).

`encode.sh` scales so one side is exactly 512, caps duration at 2.90s, strips audio, forces VP9 + alpha, and raises CRF until the file is ≤ 256 KB.

## Telegram limits (fail the upload if broken)

- `.webm` + **VP9**, never VP8
- No audio
- One side **exactly 512 px**, the other ≤ 512
- ≤ 3 seconds, ≤ 30 FPS
- ≤ 256 KB
- Looped motion
- Alpha channel (`alpha_mode=1`)

## Tools

Needs `ffmpeg` / `ffprobe` built with `libvpx-vp9` (Ubuntu package is enough).
