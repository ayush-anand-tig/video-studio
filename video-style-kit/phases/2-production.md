# Phase 2: Production

This phase turns the locked plan into a mixed 1080p master. Nothing creative gets decided here. If the words or the story need to change, go back to Phase 1.

**Read:** `$K/references/style-guide.md` §1–4, and `$K/signature/resolved.json` if it's not already in context. Run commands from `$P`.

```
projects/<slug>/  brief.md  beats.json  script.txt (generated)
  audio/   vo.wav  words.json  music.wav  mix.wav
  src/     index.html  film.css  film.js  cues.json (generated)
  exports/ gitignored, and unreadable to Claude by design
  qc/      gitignored; Phase 3 writes images here
```

## 1. Voice

```sh
jq -r '.[].text' beats.json > script.txt
$K/tools/tts.sh script.txt audio/vo.wav                # or the user's recording at audio/vo.wav
$K/tools/transcribe.sh audio/vo.wav audio/words.json   # exits 2 when TRANSCRIBE_PROVIDER=none; that's fine
```

## 2. Lock timing

If you have `words.json`, set each beat's `t` to its first word's start (up to 0.2 s earlier is fine). Otherwise keep Phase 1's `t` values. Then generate the cue map, which is the timeline's only source of beat times:

```sh
jq 'map({(.beat): .t}) | add' beats.json > src/cues.json
```

The audio is now locked. Changing any words means editing `beats.json`, then re-recording and redoing this step.

## 3. Build

Build the scenes in HTML/CSS with one GSAP timeline driven by the renderer's clock.
- Each beat starts at `cues[beat]`, never at a literal time in `film.js` (offsets inside a beat are fine).
- Apply each beat's `primitive` with its timing (`drawSeconds`, `easing`, `pathStyle`), plus the `pulse` and `colorRoles` rules from `resolved.json`.
- Reuse `scenes/` blocks when they exist. With `PROVIDER=local`, `$K/tools/draft.sh scene <promptfile>` drafts the markup and GSAP. Local models are weak at animation code, so review those drafts closely.
- Logos come from `$K/assets/brand/`. Never redraw or retype one.

**Deterministic (required).** The renderer seeks to each frame rather than playing in real time. So: one GSAP timeline (or the renderer's frame number) drives everything. No `setTimeout`, `requestAnimationFrame` loops, CSS animations or transitions, or `Date.now()`. Every frame must render the same regardless of the frame before it. Fonts and images load locally (copy them from `$K/assets/`) and finish loading before frame one. Before rendering, both of these must print nothing:

```sh
grep -nE 'setTimeout|setInterval|requestAnimationFrame|Date\.now|@keyframes|animation:|transition:' src/*
grep -nE 'https?://' src/* | grep -v 'w3\.org'
```

## 4. Render

**HyperFrames** (the default) renders the HTML with headless Chrome via `npx hyperframes`. Check `--help` for current flags, and pin the version in `package.json` once a project works. **Remotion** (React) works too, under the same rules. Author at 1920×1080 (or 1080×1920 / 1080×1080) and render 1080p to `exports/render.mp4`. 4K waits for QC.

## 5. Mix + export

```sh
# With music (trim music.wav to the video length with a fade-out first). The padded VO keeps
# music playing under the end hold instead of cutting off on the last word.
ffmpeg -i audio/vo.wav -i audio/music.wav -filter_complex \
  "[0:a]asplit=2[vo][sc];[sc]apad[scp];[1:a]volume=0.25[m];[m][scp]sidechaincompress=threshold=0.05:ratio=8[d];[vo][d]amix=inputs=2:duration=longest:normalize=0,loudnorm=I=-16:TP=-1:LRA=11" \
  -ar 48000 audio/mix.wav
# VO only
ffmpeg -i audio/vo.wav -af loudnorm=I=-16:TP=-1:LRA=11 -ar 48000 audio/mix.wav
# Attach to the render (-ar 48000 above is needed: loudnorm otherwise writes 192 kHz)
ffmpeg -i exports/render.mp4 -i audio/mix.wav -map 0:v -map 1:a -vf "scale=1920:-2:flags=lanczos" \
  -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart exports/final-1080p.mp4
```

## Exit gate

- [ ] `src/cues.json` was regenerated from the current `beats.json`
- [ ] Both determinism greps printed nothing
- [ ] `exports/final-1080p.mp4` has one video stream and one audio stream
