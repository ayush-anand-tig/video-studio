# Video studio — plan and status

A personal studio for making product and explainer videos with Claude Code. The skill in `video-style-kit/` defines the workflow and style; this repo grows into the studio around it.

## What's here

| Path | Purpose |
|---|---|
| `video-style-kit/SKILL.md` | Skill entry point: routes through four gated phases |
| `video-style-kit/phases/` | `1-preproduction.md` (brief, narrative arc, beat map, timing check), `2-production.md` (voice, captions, build, render, rough cut), `3-edit.md` (beat sheet, notes, fixes, picture lock, music/SFX, mix, export), `4-qc.md` (spec + freshness, sync, loudness, picture checklist, delivery) |
| `docs/v2-frame-feedback.md` | Design (not built): timestamp/screenshot notes on a cut, resolved to beat + code and routed like QC failures |
| `video-style-kit/references/style-guide.md` | Look, type, layout, motion, sound |
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
| Agent (script, animation code, frame review) | `qwen2.5:14b` script drafts, `qwen2.5-coder:14b` scene drafts via Ollama — wired up as `PROVIDER=local` in `video-style-kit/providers.env` + `tools/draft.sh` (fine for scripts, weaker at animation code) | **Claude Code** (`PROVIDER=agent`, the default — keep this paid) |
| Rendering | HyperFrames + GSAP or Remotion, headless Chrome, ffmpeg | — |
| Voiceover | `tools/tts.sh` — `say` (zero setup, default), Kokoro-82M (Apache, best local quality/size, runs on a MacBook Air, no GPU) or Kitten TTS nano (~24MB, lighter still) — wired, not yet installed. Chatterbox dropped from the default plan: needs a GPU, Mac Air can't run it well | ElevenLabs via `tools/tts.sh`, needs `ELEVENLABS_API_KEY` |
| Word timing + captions | `tools/transcribe.sh` — `faster-whisper` (`TRANSCRIBE_PROVIDER=whisper`), not yet installed; falls back to even timing until it is. `tools/captions.sh` turns `beats.json` + that timing into SRT/VTT and burn-in data (wired) | — |
| Music | `tools/synth-audio.sh bed` (wired, zero-setup, synthesized pad, nothing to license). Better: ACE-Step (Apache), Stable Audio Open. Avoid MusicGen (non-commercial weights) | Epidemic Sound / Artlist |
| SFX | `tools/synth-audio.sh sfx` (wired: tick/click/pop/whoosh, placed by beat). Better: Freesound CC0, Stable Audio Open | — |
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
3. Kokoro/Chatterbox makes VO; Whisper makes word timings; `captions.sh` makes captions.
4. Claude builds the video from `scenes/`, timed to words; HyperFrames renders a rough cut.
5. I watch the cut and give notes (or Claude reviews its beat sheet); fixes until picture lock; music/SFX, mix, export.
6. QC checks freshness, sync, loudness, frames, readability; Claude reviews frames.
7. Feedback goes into `LESSONS.md`.

## Next steps

1. Decide: which Mac/RAM will render, and own cloned voice or a stock local voice?
2. Fill `{{BRAND}}` / `{{ACCENT_COLOR}}` and add a logo to `video-style-kit/assets/brand/` — see `references/assets.md` for the import checklist and a list of reusable icon/footage/font sources.
3. Create the skeleton above and the local voice + word-timing pipeline.
4. Make one 20-second test video end to end to prove the chain.
5. If `PROVIDER=local` script/scene drafts turn out useful, consider pulling `qwen2.5-coder:14b` by default and wiring voice/word-timing the same provider-toggle way.
6. After a few real videos have gone through Edit with hand-written `notes.md`, build v2 frame feedback (`docs/v2-frame-feedback.md`). Real notes will show which categories and anchors actually come up.
