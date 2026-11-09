# Phase 4: QC & delivery

Gates 1–3 are mechanical, so they don't depend on the builder's judgment. Run them before looking at any frames. The video is done only when all four gates pass. QC checks a locked cut. Judging how the cut feels belongs to Phase 3. Run from `$P` with `F=exports/final-1080p.mp4`. Images go in `qc/`, because `exports/` is unreadable by design.

## Gate 1: Spec + freshness

```sh
ffprobe -v error -show_entries stream=codec_type,codec_name,width,height,duration -of csv=p=0 "$F"
ffprobe -v error -show_entries format=duration -of csv=p=0 audio/vo.wav
$K/tools/fingerprint.sh check "$F"
```

To pass:
- H.264 video at the brief's aspect, plus an AAC audio stream
- duration within about 10% of the brief's length
- the video runs at least 1 s past the end of `vo.wav`, so narration never outruns the last frame
- `fingerprint.sh` prints OK. STALE means `beats.json`, `src/` or `vo.wav` changed after the render, so the file isn't what the sources describe. UNSTAMPED is acceptable only for a video made outside this pipeline.

## Gate 2: Sync

```sh
jq 'map({(.beat): .t}) | add' beats.json | diff - src/cues.json   # timeline uses the checked times
$K/tools/captions.sh --check                                       # unless the brief says no captions
$K/tools/check-sync.sh beats.json
```

To pass, `diff` prints nothing, and `captions.sh --check` and `check-sync.sh` both print OK. Run this even if the video "sounds right": a script sized by word count can drift seconds off its beats. On DRIFT, retime `t` (or fix the words in Phase 1), regenerate `cues.json` and the captions, and re-render. `check-sync.sh` times the TTS voice, so if `vo.wav` is a human recording and `t` came from its `words.json`, check against `words.json`. If the real timestamps agree with `t`, note a TTS mismatch and pass. Never move `t` away from real timestamps.

## Gate 3: Loudness

```sh
ffmpeg -nostats -i "$F" -af ebur128=peak=true -f null - 2>&1 | grep -E 'I:|Peak:' | tail -2
```

To pass, I is within 1 LU of the −16 to −14 LUFS target and true peak is at or below −1 dBTP (or the brief's platform spec). Single-pass `loudnorm` can land about 1 LU low on short clips. If you're outside the range, shift `loudnorm`'s `I=` (or lower `TP=`) by the shortfall, then re-mix and re-export (Phase 3 §5). No re-render.

## Gate 4: Picture + checklist

Two image reads in total: a contact sheet across the whole video and a first/last-frame strip.

```sh
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$F")
ffmpeg -v error -y -i "$F" -vf "fps=16/$D,scale=480:-1,tile=4x4" -frames:v 1 qc/sheet.jpg
ffmpeg -v error -y -i "$F" -sseof -0.1 -i "$F" -filter_complex \
  "[0:v]trim=end_frame=1,scale=480:-1[a];[1:v]trim=end_frame=1,scale=480:-1[b];[a][b]hstack" -frames:v 1 qc/thumbs.jpg
```

Tiles are 480 px, smaller than the 960×540 readability test. If text looks marginal, grab that moment alone: `ffmpeg -ss <t> -i "$F" -frames:v 1 -vf scale=960:-1 qc/at-<t>.jpg`. Every box must be ticked:

- [ ] The one takeaway is clear to someone who has never seen the product
- [ ] Every claim matches `brief.md` Facts, with no invented numbers
- [ ] All text is readable at 960×540 and held long enough to read twice
- [ ] Visual changes land on their words, and nothing moves while text is being read
- [ ] Nothing is clipped, overlapping or leaving the screen early
- [ ] Burned captions, if any, are readable, inside the margins, and never cover a label
- [ ] The accent is used only for active or important elements
- [ ] The audio is balanced and the ending resolves rather than cutting off
- [ ] The first and last frames work as thumbnails (`qc/thumbs.jpg`)
- [ ] No private data, real credentials or unlicensed assets (`$K/references/assets.md`)

## When a gate fails

Fix it where it lives, then re-run only what the fix touches. "Render + export" means Phase 2 §4 followed by Phase 3 §5's export line, with the same `mix.wav`.

| Problem | Fix in | Re-run |
|---|---|---|
| STALE fingerprint | nothing to fix; the sources moved on after the render | render + export, then all gates |
| Words, claims, takeaway | `beats.json` (Phase 1) + check-sync | Phase 2 from Voice, Phase 3, then all gates |
| Timing drift | `t` in `beats.json`, regenerate `cues.json` and the captions | render + export, then Gates 1, 2, 4 |
| Clipping, overlap, accent, readability, burned captions | `src/` | render + export, then Gates 1, 4 |
| Captions STALE | re-run `captions.sh` | render + export if burned in, then Gates 1, 2 |
| Loudness or balance | the mix (Phase 3 §5) | export, then Gates 1, 3 |

## Delivery (only after all gates pass)

- **4K**, if the brief asks: re-render (the same command writes `render.fp`), export with the same `mix.wav`, and re-run Gate 1.
- **Unauthored aspect ratios**: crop with `ffmpeg -i "$F" -vf "crop=ih*9/16:ih,scale=1080:1920" -c:a copy exports/final-9x16.mp4`. The fingerprint stamp carries over. Crops cut the edges, where labels and burned captions sit, so run Gate 4's contact sheet on each crop.
- **Captions**: `exports/captions.srt` (YouTube, LinkedIn) and `exports/captions.vtt` (web players). One pair serves every aspect ratio, since the timing doesn't change.
- Report in five lines or fewer: file paths, plus one line per gate.

**Wrap.** Add one line to `LESSONS.md` (newest first) for each user correction, whether it came during the run (including the creator's notes in `notes.md`) or later, and for any gate failure worth remembering. Phase 1 reads it next time.
