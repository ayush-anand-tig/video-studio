# Video studio — plan and status

A personal studio for making product and explainer videos with Claude Code. The skill in `video-style-kit/` defines the workflow and style; this repo grows into the studio around it.

## What's here

| Path | Purpose |
|---|---|
| `video-style-kit/SKILL.md` | Skill entry point: the 7-step workflow |
| `video-style-kit/references/style-guide.md` | Look, type, layout, motion, sound, review checklist |
| `video-style-kit/references/production.md` | Deterministic animation, render, ffmpeg export, QA |
| `video-style-kit/references/assets.md` | Asset list and placeholders |
| `video-style-kit/assets/` | Fonts (OFL) and icon (ISC); placeholders for logo and reference films |

Install: `./install.sh` (checks node/ffmpeg, symlinks the skill to `~/.claude/skills/video-style-kit`).

## Target structure (this repo)

```
brand/            colors, fonts, logo; fills {{BRAND}} / {{ACCENT_COLOR}}
scenes/           reusable blocks: title, terminal, card + connector, captions, end card
formats/          16:9 (YouTube), 9:16 (Shorts/Reels), 1:1 (LinkedIn) presets
pipeline/         scripts: voice → word timing → render → mix → QA
projects/<slug>/  one folder per video (brief, script, beats, audio, src; exports gitignored)
LESSONS.md        feedback after each review; the skill reads it every run
```

## Tools

| Stage | Local / open-source | Paid |
|---|---|---|
| Agent (script, animation code, frame review) | Qwen3-Coder / gpt-oss via Ollama or MLX (fine for scripts, weak at animation code) | **Claude Code** (keep this paid) |
| Rendering | HyperFrames + GSAP or Remotion, headless Chrome, ffmpeg | — |
| Voiceover | Kokoro-82M (Apache) or Chatterbox (MIT, voice cloning) via `mlx-audio` | ElevenLabs (~$5–22/mo) |
| Word timing + captions | mlx-whisper / whisper.cpp, WhisperX for word-level | — |
| Music | ACE-Step (Apache), Stable Audio Open. Avoid MusicGen (non-commercial weights) | Epidemic Sound / Artlist |
| SFX | Freesound CC0, Stable Audio Open | — |
| Mixing + QA | ffmpeg `loudnorm`/`ebur128`, contact sheets reviewed by Claude | — |
| Remote access | Tailscale + SSH, or watched `inbox/` folder via launchd | — |

## Mac Mini sizing

| RAM | Capability |
|---|---|
| 16 GB | Rendering, Kokoro, Whisper, ffmpeg (1080p or `--low-memory-mode` for 4K) |
| 32 GB | + Chatterbox, ACE-Step, small local LLM |
| 64 GB+ | + 30B-class local coding model |

Also: 512 GB+ storage or external SSD, disable sleep (`pmset`), launchd job watcher.

## Daily run

1. Drop `brief.md` in (or message the Mini via SSH/bot).
2. Claude drafts script + beat map → I approve.
3. Kokoro/Chatterbox makes VO; Whisper makes word timings + captions.
4. Claude builds the video from `scenes/`, timed to words.
5. HyperFrames renders; ffmpeg mixes and exports.
6. QA script checks loudness, frames, readability; Claude reviews frames.
7. Feedback goes into `LESSONS.md`.

## Next steps

1. Decide: which Mac/RAM will render, and own cloned voice or a stock local voice?
2. Fill `{{BRAND}}` / `{{ACCENT_COLOR}}` and add a logo to `video-style-kit/assets/brand/`.
3. Create the skeleton above and the local voice + word-timing pipeline.
4. Make one 20-second test video end to end to prove the chain.
