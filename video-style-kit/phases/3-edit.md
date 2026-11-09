# Phase 3: Edit

Production built what the plan said. Edit is where the cut gets watched and made to feel right, the way an editor works: rough cut, notes, fixes, picture lock, then sound and the final export. Words, facts and story are already settled, so a note that needs different words goes back to Phase 1. QC (Phase 4) then checks the locked result mechanically, so it shouldn't become the place where the video gets edited.

**Read:** `$K/references/style-guide.md` §4–5 only. Run from `$P`.

## 1. Watch the rough cut

```sh
$K/tools/beat-sheet.sh exports/cut.mp4 qc/beats.jpg
```

That's one image read: a tile per beat at the moment it's fully built, plus a printed key from tile to beat. Look at it with the beat table in mind:

- Does each beat finish building before the next one starts, and hold still long enough to read?
- Does the turn (Phase 1 §2) get the biggest move, with nothing competing with it?
- Is the same kind of change animated the same way every time?
- Does the end hold long enough for the payoff to land?

If the user wants to see the cut, give them the path to `exports/cut.mp4` and wait for their notes. Otherwise this review is yours.

## 2. Notes → `notes.md`

Write one line per note, anchored to a time or a beat, and say who it's from. Keep the user's wording.

```
- [ ] 3.2 cause: card enters before "cache", land it on the word (creator)
- [ ] payoff: end hold too short (self)
```

To find a time's beat, take the last beat in `src/cues.json` that starts at or before it. Within 0.4 s of a boundary the note may be about the transition, so check both beats. Each beat's code starts at its `// beat: <slug>` comment. Close every note as `- [x] … → what changed` or `- [~] … → waived: why`.

## 3. Fix

| Note | Fix in | Then |
|---|---|---|
| Rushed, lingers, lands early or late (inside a beat) | that beat's offsets and durations in `src/film.js` | render + cut |
| A beat starts too early or late against its words | `t` (at most 0.2 s before its word, never away from real timestamps), then regenerate cues and captions (Phase 2 §2) | render + cut |
| Needs more or less screen time | the words, in Phase 1 (add words, not silence) | Phase 2 from Voice |
| Transition, camera move, emphasis | `src/` (style guide §4) | render + cut |
| Layout, overlap, readability, caption placement | `src/` | render + cut |
| Caption line breaks | `captions.sh --max-chars` | render + cut if burned in |
| Wording, a claim, the story | Phase 1 | Phase 2 from Voice |
| Music or effects | §4 | mix + export (§5) |

"Render + cut" is Phase 2 §4–5. After fixing, make a fresh beat sheet, and close a note only once its change is visible in a cut.

## 4. Lock picture, then sound

Once every note is closed, the picture is locked: the latest render is the one that ships. Any later change to `beats.json`, `src/` or `audio/vo.wav` means rendering again, and QC's fingerprint check fails if that's skipped. Get the length with `D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 exports/render.mp4)`.

**Music**, per the brief:
- **none:** skip.
- **synth:** `$K/tools/synth-audio.sh bed "$D" <calm|cinematic|energetic> audio/music.wav`. It's a soft chord pad built from sine waves, with the fades already in. Nothing is sampled, so there's nothing to license. It's plain, so a real licensed track is better when there is one.
- **a licensed track:** trim it to `$D`, with a 2 s fade-out, into `audio/music.wav`.

**Effects** (optional; a few, only on real interactions, per style guide §5): list them in `audio/sfx.txt`, one per line as `<beat> <offset> <tick|click|pop|whoosh>`. Times follow `src/cues.json`, so they move with any retime. Then fold them into the voice stem, and use `audio/vo-fx.wav` as the mix's first input instead of `audio/vo.wav`:

```sh
$K/tools/synth-audio.sh sfx audio/sfx.txt "$D" audio/sfx.wav
ffmpeg -i audio/vo.wav -i audio/sfx.wav -filter_complex \
  "[1:a]volume=0.5[s];[0:a][s]amix=inputs=2:duration=longest:normalize=0" audio/vo-fx.wav
```

## 5. Mix + export

```sh
# With music. The padded VO keeps music playing under the end hold instead of cutting off on the last word.
ffmpeg -i audio/vo.wav -i audio/music.wav -filter_complex \
  "[0:a]asplit=2[vo][sc];[sc]apad[scp];[1:a]volume=0.25[m];[m][scp]sidechaincompress=threshold=0.05:ratio=8[d];[vo][d]amix=inputs=2:duration=longest:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=11" \
  -ar 48000 audio/mix.wav
# VO only
ffmpeg -i audio/vo.wav -af loudnorm=I=-16:TP=-1.5:LRA=11 -ar 48000 audio/mix.wav
# Export, stamped with the render's fingerprint. -ar 48000 above is needed because loudnorm otherwise
# writes 192 kHz. TP=-1.5 leaves room for the few tenths of a dB that AAC encoding adds to true peak.
ffmpeg -i exports/render.mp4 -i audio/mix.wav -map 0:v -map 1:a -vf "scale=1920:-2:flags=lanczos" \
  -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -c:a aac -b:a 192k \
  -metadata comment="fp=$(cat exports/render.fp)" -movflags +faststart exports/final-1080p.mp4
```

## Exit gate

- [ ] Every note in `notes.md` is closed (if notes were taken)
- [ ] `$K/tools/fingerprint.sh check exports/cut.mp4` prints OK, so every fix is in the latest render
- [ ] Music and effects match the brief
- [ ] `exports/final-1080p.mp4` has one video stream and one audio stream
- [ ] The user approved the cut, if they asked to see it
