# Phase 2: Production

This phase turns the locked plan into a rough cut: the real voice, the built scenes and a render, with no mix yet. Nothing creative gets decided here. If the words or the story need to change, go back to Phase 1. Judging and refining the cut is Phase 3.

**Read:** `$K/references/style-guide.md` §1–4, and `$K/signature/resolved.json` if it's not already in context. Run commands from `$P`.

```
projects/<slug>/  brief.md  beats.json  script.txt (generated)  notes.md (Phase 3)
  audio/   vo.wav  words.json  music.wav  sfx.txt  mix.wav
  src/     index.html  film.css  film.js  cues.json  captions.json (both generated)
  exports/ gitignored, and unreadable to Claude by design
  qc/      gitignored; beat sheets and contact sheets go here
```

## 1. Voice

```sh
jq -r '.[].text' beats.json > script.txt
$K/tools/tts.sh script.txt audio/vo.wav                # or the user's recording at audio/vo.wav
$K/tools/transcribe.sh audio/vo.wav audio/words.json   # exits 2 when TRANSCRIBE_PROVIDER=none; that's fine
```

## 2. Lock timing

If you have `words.json`, set each beat's `t` to its first word's start (up to 0.2 s earlier is fine). Otherwise keep Phase 1's `t` values. Then generate the cue map, which is the timeline's only source of beat times, and the captions, unless the brief says none:

```sh
jq 'map({(.beat): .t}) | add' beats.json > src/cues.json
$K/tools/captions.sh            # add --max-chars 28 for burned 9:16 captions
```

`captions.sh` takes the text from `beats.json` and the timing from `words.json`, or from `t` when there's no `words.json`. It writes `src/captions.json` for a burned-in layer and `exports/captions.srt` and `.vtt` for delivery.

The audio is now locked. Changing any words means editing `beats.json`, then re-recording and redoing this step.

## 3. Build

Build the scenes in HTML/CSS with one GSAP timeline driven by the renderer's clock.
- Each beat starts at `cues[beat]`, never at a literal time in `film.js` (offsets inside a beat are fine). Start each beat's block with a `// beat: <slug>` comment so a note about that beat finds its code.
- Apply each beat's `primitive` with its timing (`drawSeconds`, `easing`, `pathStyle`), plus the `pulse` and `colorRoles` rules from `resolved.json`.
- **Burned captions** (if the brief asks): a caption layer reads `src/captions.json` the way the timeline reads `cues.json`, and shows each cue from `start` to `end`, with no animation inside a cue. Use body type at about 40 px or more, inside the margins. For 9:16, keep it out of the bottom fifth, where apps put their own buttons.
- Reuse `scenes/` blocks when they exist. With `PROVIDER=local`, `$K/tools/draft.sh scene <promptfile>` drafts the markup and GSAP. Local models are weak at animation code, so review those drafts closely.
- Logos come from `$K/assets/brand/`. Never redraw or retype one.

**Deterministic (required).** The renderer seeks to each frame rather than playing in real time. So: one GSAP timeline (or the renderer's frame number) drives everything. No `setTimeout`, `requestAnimationFrame` loops, CSS animations or transitions, or `Date.now()`. Every frame must render the same regardless of the frame before it. Fonts and images load locally (copy them from `$K/assets/`) and finish loading before frame one. Before rendering, both of these must print nothing:

```sh
grep -nE 'setTimeout|setInterval|requestAnimationFrame|Date\.now|@keyframes|animation:|transition:' src/*
grep -nE 'https?://' src/* | grep -v 'w3\.org'
```

## 4. Render

**HyperFrames** (the default) renders the HTML with headless Chrome via `npx hyperframes`. Check `--help` for current flags, and pin the version in `package.json` once a project works. **Remotion** (React) works too, under the same rules. Author at 1920×1080 (or 1080×1920 / 1080×1080) and render 1080p to `exports/render.mp4`. 4K waits for QC.

Write the fingerprint in the same command as the render, so it describes exactly what got rendered. QC uses it to catch a render that's older than its sources.

```sh
$K/tools/fingerprint.sh > exports/render.fp && npx hyperframes <render args>
```

## 5. Rough cut

This is the render plus the raw voice, for watching. Music, effects and loudness wait until Phase 3 locks the picture.

```sh
ffmpeg -v error -y -i exports/render.mp4 -i audio/vo.wav -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k \
  -metadata comment="fp=$(cat exports/render.fp)" exports/cut.mp4
```

Phase 3 repeats §4–5 ("render + cut") after each fix.

## Exit gate

- [ ] `src/cues.json` was regenerated from the current `beats.json`, and `$K/tools/captions.sh --check` prints OK (unless the brief says no captions)
- [ ] Both determinism greps printed nothing
- [ ] `$K/tools/fingerprint.sh check exports/cut.mp4` prints OK
