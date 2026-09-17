# Telegram Video Sticker Pack — Plan

This repo starts empty. The first deliverable is this plan. We will **not** encode or publish anything until the pack concept and source art are locked.

Official references:

- [Telegram Stickers](https://core.telegram.org/stickers)
- [Encoding Video Stickers (.WEBM / VP9)](https://core.telegram.org/stickers/webm-vp9-encoding)
- [Importing Stickers](https://core.telegram.org/import-stickers)

---

## 1. Goal

Create **one video sticker pack** for Telegram (not custom emoji, not `.TGS` Lottie).

Each sticker is a short looping VP9 `.webm` that people can send in chats. Upload happens through the official **@Stickers** bot (`/newvideo`) or the in-app Sticker Editor.

We will treat encoding as a repeatable pipeline in this repo, so adding or replacing stickers later is mechanical.

---

## 2. Hard constraints (Telegram)

These are reject-or-fail rules. Encode against them, then verify before upload.

| Rule | Stickers (this pack) |
| --- | --- |
| Container | `.webm` |
| Codec | **VP9** (`libvpx-vp9`), never VP8 |
| Audio | **None** (`-an`) |
| Size | One side **exactly 512 px**; the other **≤ 512 px** |
| Duration | **≤ 3 seconds** |
| Frame rate | **≤ 30 FPS**, constant |
| File size | **≤ 256 KB** after encode |
| Loop | Designed to loop (last frame should connect to first) |
| Transparency | Supported; Telegram currently expects an **alpha channel** (`yuva420p`) for video stickers |

Custom emoji (out of scope unless we add a second pack later): exactly **100×100**, same codec/duration/size rules.

---

## 3. Decisions to lock before production

Do this in chat before drawing or encoding. The pack will feel random without these.

1. **Theme / character** — one mascot, a set of objects, a meme format, or a brand.
2. **Emotion list** — 8–20 stickers is a solid first pack. Each sticker needs a clear chat use (hello, laugh, sad, ok, thinking, rage, love, bye).
3. **Art style** — 2D illustration, pixel, 3D, live-action cutout, etc. Video stickers handle detail better than `.TGS`, but complexity fights the 256 KB cap.
4. **Canvas** — square **512×512** is simplest. Non-square is allowed if one side stays 512.
5. **Pack identity** — display title (human), short name (URL slug, letters/digits/underscores), cover sticker, default emoji per file.
6. **Source tool** — After Effects, Blender, Spine, Rive, Figma + video export, or existing footage/GIF. Export should keep **alpha** if the background is transparent.

Until those are chosen, the only work in this repo is planning, folder layout, and the encode/validate scripts.

---

## 4. Recommended workflow

```
concept  →  storyboard  →  source animation  →  encode VP9  →  validate  →  upload  →  publish
```

### Phase 0 — Concept (now)

- Lock theme, sticker list, and emoji mapping.
- Sketch each pose on paper or in a board (`docs/storyboard.md` later).
- Pick a cover sticker (the one that represents the whole pack).

### Phase 1 — Source art

- Animate on a **transparent** canvas when possible.
- Keep motion simple and centered; busy backgrounds blow the 256 KB budget.
- Design **seamless loops**: start ≈ end pose, avoid a hard cut.
- Cap length at **2.0–2.9 s** so encode never overshoots 3 s.
- Export as PNG sequence, ProRes 4444 / QuickTime with alpha, or high-quality MOV/MP4 **without** baked-in audio if you can.

Suggested naming: `hello`, `laugh`, `sad` — short, unique, no spaces.

### Phase 2 — Encode (ffmpeg)

Install `ffmpeg` with `libvpx-vp9`.

Target encode (starting point; raise CRF if a file is still > 256 KB):

```bash
ffmpeg -y -i source.mov \
  -an \
  -t 2.9 \
  -r 30 \
  -vf "scale=512:512:force_original_aspect_ratio=decrease,format=yuva420p" \
  -c:v libvpx-vp9 \
  -pix_fmt yuva420p \
  -b:v 0 -crf 40 \
  -row-mt 1 \
  -auto-alt-ref 0 \
  dist/hello.webm
```

Notes:

- `-b:v 0` + `-crf` = constant quality. **Higher CRF = smaller file.** Try 38 → 42 → 45 if over 256 KB.
- If CRF 45 is still too big: shorten the clip, drop to 24 FPS, simplify the art, or switch to 2-pass VBR.
- `-auto-alt-ref 0` is often needed so VP9 keeps the alpha channel.
- Do **not** pad with a solid color unless we want an opaque sticker. Padding with transparency is OK if we later standardize on 512×512.

A later `scripts/encode.sh` should:

- take files from `source/`
- write `.webm` to `dist/`
- retry with a higher CRF when `stat` reports > 256 KB

### Phase 3 — Validate

For every file in `dist/`, check:

- extension `.webm`, codec VP9, **no audio stream**
- width or height is 512, neither side > 512
- duration ≤ 3.00 s
- fps ≤ 30
- pixel format has alpha (`yuva420p`)
- size ≤ 256 KB (262144 bytes)

`ffprobe` is the source of truth. A later `scripts/validate.sh` should fail the pack if any file breaks a rule.

### Phase 4 — Publish on Telegram

1. Open [@Stickers](https://t.me/Stickers).
2. `/newvideo`
3. Pack title → upload first `.webm` → assign emoji → repeat.
4. Set cover.
5. `/publish` and pick a unique short name.
6. Share `https://t.me/addstickers/<short_name>`.

Keep a local manifest (`pack.yaml`) so emoji assignments are not only in the bot chat.

---

## 5. Proposed repo layout

Create these when we leave planning:

```
Stickers/
  PLAN.md                 # this file
  pack.yaml               # title, short name, sticker → emoji map
  source/                 # masters (mov, png sequence, blend, aep)
  dist/                   # final .webm files only
  scripts/
    encode.sh             # source → VP9 webm
    validate.sh           # ffprobe + size checks
  docs/
    storyboard.md         # pose list and loop notes
```

Do not commit huge raw captures if we can avoid it. Prefer source project files + the small `dist/` webms.

---

## 6. Quality bar (so the pack feels good)

- One character or one visual language across the set.
- Readable at chat size: thick shapes, high contrast, not tiny details.
- Transparent background unless the joke needs a scene.
- Loop without a pop (no sudden jump in position or lighting).
- Prefer 8–12 excellent stickers over 40 weak ones.

---

## 7. Out of scope for v1

- Custom emoji pack (100×100)
- Animated `.TGS` / Lottie stickers
- Mask stickers
- Auto-upload via Bot API (manual @Stickers first; automate later if needed)

---

## 8. Next action

**Choose the pack concept**, then we fill `pack.yaml` and start source art.

Reply with:

1. Theme / character (or “help me invent one”).
2. How many stickers for v1 (recommend 8–12).
3. Where art will come from (draw, 3D, existing clips, generate, mix).
4. Square 512×512 vs tall/wide 512 on one side.

After that: storyboard → folder layout → encode script → first sticker as a pipeline test.
