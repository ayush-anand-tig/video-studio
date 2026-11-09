# Production

## Renderer

- **HyperFrames** (default): renders an HTML composition to video with headless Chrome. It runs via `npx hyperframes`. Check `npx hyperframes --help` for the current commands and flags, and pin the version in `package.json` once a project works.
- **Remotion** (alternative): React compositions. Same rules apply.

## Deterministic animation (required)

The renderer captures frames by seeking, not by playing in real time, so:
- Drive everything from one GSAP timeline (or the renderer's frame number). Never use `setTimeout`, `requestAnimationFrame` loops, CSS animations or `Date.now()`.
- Every frame must render the same no matter which frame came before it. Test by seeking to random times and checking the result.
- Load fonts and images locally and wait for them before the first frame. Don't use remote URLs.
- Keep timing in one place: a cue map such as `{ "intro": 0.0, "connect": 4.2 }` taken from the word timestamps.

## Project layout

```
projects/<slug>/
  brief.md  script.md  beats.md      # plan
  audio/    vo.wav  words.json  music.wav
  src/      index.html  film.css  film.js  cues.json
  exports/  (gitignored)
```

## Render

Author at 1920×1080 (or 1080×1920 / 1080×1080). Render a 1080p draft first, and render 4K only for the final.

## Export (ffmpeg)

```sh
# Mix VO + music with ducking, then normalise
ffmpeg -i vo.wav -i music.wav -filter_complex \
  "[1:a]volume=0.25[m];[m][0:a]sidechaincompress=threshold=0.05:ratio=8[d];[0:a][d]amix=inputs=2:normalize=0,loudnorm=I=-16:TP=-1:LRA=11" mix.wav

# Attach the audio to the silent render, H.264 1080p for sharing
ffmpeg -i render.mp4 -i mix.wav -map 0:v -map 1:a -vf "scale=1920:-2:flags=lanczos" \
  -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart final-1080p.mp4

# Vertical crop for Shorts/Reels (only if not authored at 9:16)
ffmpeg -i final-1080p.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" -c:a copy final-9x16.mp4
```

## QA

```sh
ffmpeg -i final-1080p.mp4 -af ebur128=peak=true -f null - 2>&1 | tail -12      # loudness
ffmpeg -i final-1080p.mp4 -vf "fps=1/2,scale=480:-1,tile=4x4" -frames:v 1 sheet.jpg  # contact sheet
ffprobe -v error -show_entries format=duration:stream=codec_name,width,height final-1080p.mp4
tools/check-sync.sh projects/<slug>/beats.json                                 # narration vs. visual timing
```

Review `sheet.jpg` against the checklist in `style-guide.md` §6. Inspecting one contact sheet costs far fewer tokens than inspecting many separate frames.

**Always run `check-sync.sh` before calling a video done, even when it "sounds about right" on a quick listen.** A script sized for word count easily drifts seconds away from its visual beats — see `tools/check-sync.sh`'s own header for the format of `beats.json` (one entry per beat: name, visual start time, narration text). A FAIL means either the beats need retiming to match how long the narration actually takes, or the project should move to real word-level timestamps (`TRANSCRIBE_PROVIDER=whisper` in `voice.env`) instead of fixed seconds.
