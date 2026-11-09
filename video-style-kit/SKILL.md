---
name: video-style-kit
description: Make short product, explainer and launch videos as code (HTML + GSAP rendered to MP4 with HyperFrames or Remotion, finished with ffmpeg), run like a production house — pre-production (brief, narration, tone, theme, language), production (voice, scenes, render), QC (sync, frames, loudness). Use when the user asks to make, plan, script, voice, animate, render, QC or review a video, or to design their own video signature.
---

# Video style kit

You're the producer. A video goes through three phases in order, and each ends in a gate. Don't start a phase until the previous gate passes. A failed check goes back to the phase that owns it.

`$K` = this skill's folder (the base directory Claude Code reports on load). `$P` = `projects/<slug>/` in the working directory (the studio repo, which also holds `LESSONS.md`). Phase commands run from `$P`.

| Phase | Read on entry | Produces | Gate |
|---|---|---|---|
| 1. Pre-production | `phases/1-preproduction.md` | `brief.md`, `beats.json` | brief with sourced facts; `tools/check-sync.sh` OK on planned timing; approval if asked |
| 2. Production | `phases/2-production.md` | `audio/`, `src/`, `exports/final-1080p.mp4` | cues generated from `beats.json`; determinism greps clean |
| 3. QC & delivery | `phases/3-qc.md` | `qc/` sheets, deliverables, `LESSONS.md` line | spec, sync, loudness, picture checklist |

Read a phase doc when you enter that phase, not up front.

## Where to start

- "Make a 20-second video about X" → Phase 1. A short ask still gets a brief: it's about ten lines, mostly inferred, and it's what QC checks against. A script the user supplies goes into the beat map.
- `$P` exists → resume at the first unmet gate (no `beats.json` → 1, no `exports/final-1080p.mp4` → 2, else → 3).
- "Review/QC this video" → Phase 3. With no `beats.json`, build one from its script and cue times first, because the sync gate can't be skipped.
- "Design my own signature" → `references/signature-wizard.md`. That's a separate task, not a video run.

## Ground rules

- Ask only about gaps that change the video, in one message. Infer the rest into the brief.
- Narration lives only in `beats.json`. `script.txt` and `src/cues.json` are generated from it, never hand-edited.
- Fix at the source and re-run only what the fix touches.
- Keep it cheap: read only the style-guide sections a phase names, look at one contact sheet rather than many frames, and show only the tail of tool output.

## Also here

`references/style-guide.md` (house look, motion, sound), `references/assets.md` (assets, placeholders, licensing), `signature/` (active signature in `resolved.json`, chosen in `source.env`, presets in `presets/`), `providers.env` (drafting: `agent` or `local` via `tools/draft.sh`), `voice.env` (TTS and word timestamps via `tools/tts.sh`, `tools/transcribe.sh`).
