---
name: video-style-kit
description: Make short product, explainer and launch videos as code (HTML + GSAP rendered to MP4 with HyperFrames or Remotion, finished with ffmpeg), run like a production house — pre-production (brief, narration, tone, theme, language), production (voice, captions, scenes, render), edit (rough cut, notes, sound, picture lock), QC (sync, frames, loudness, freshness). Use when the user asks to make, plan, script, voice, animate, render, edit, caption, QC or review a video, gives notes on a cut, or wants to design their own video signature.
---

# Video style kit

You're the producer. A video goes through four phases in order, and each ends in a gate. Don't start a phase until the previous gate passes. A failed check goes back to the phase that owns it.

`$K` = this skill's folder (the base directory Claude Code reports on load). `$P` = `projects/<slug>/` in the working directory (the studio repo, which also holds `LESSONS.md`). Phase commands run from `$P`.

| Phase | Read on entry | Produces | Gate |
|---|---|---|---|
| 1. Pre-production | `phases/1-preproduction.md` | `brief.md`, `beats.json` | brief with sourced facts; script shaped as an arc; `tools/check-sync.sh` OK on planned timing; storyboard checkpoint shown |
| 2. Production | `phases/2-production.md` | `audio/vo.wav`, `src/` (cues, captions), `exports/cut.mp4` | cues and captions generated from `beats.json`; determinism greps clean; rough cut fingerprint OK |
| 3. Edit | `phases/3-edit.md` | `notes.md`, `audio/mix.wav`, `exports/final-1080p.mp4` | every note closed in a fresh cut; sound per brief; final exported from the locked render; approval if asked |
| 4. QC & delivery | `phases/4-qc.md` | `qc/` sheets, deliverables, `LESSONS.md` line | spec + freshness, sync, loudness, picture checklist |

Read a phase doc when you enter that phase, not up front.

## Where to start

- "Make a 20-second video about X" → Phase 1. A short ask still gets a brief: it's about ten lines, mostly inferred, and it's what QC checks against. A script the user supplies goes into the beat map.
- `$P` exists → resume at the first unmet gate (no `beats.json` → 1, no `exports/cut.mp4` → 2, no `exports/final-1080p.mp4` → 3, else → 4).
- Notes on a cut ("at 3.2 s the card clips", "the ending feels rushed") → Phase 3. Add them to `notes.md` first, even if the video was already delivered: a change after lock goes back through Edit and then QC.
- "Review/QC this video" → Phase 4. With no `beats.json`, build one from its script and cue times first, because the sync gate can't be skipped.
- "Design my own signature" → `references/signature-wizard.md`. That's a separate task, not a video run.

## Ground rules

- Ask only about gaps that change the video, in one message. Infer the rest into the brief.
- Narration lives only in `beats.json`. `script.txt`, `src/cues.json` and the captions are generated from it, never hand-edited.
- Fix at the source and re-run only what the fix touches. Once the picture is locked, any change to `beats.json`, `src/` or `audio/vo.wav` needs a re-render; the fingerprint check enforces it.
- Keep it cheap: read only the style-guide sections a phase names, look at one contact or beat sheet rather than many frames, and show only the tail of tool output.

## Also here

`references/style-guide.md` (house look, motion, sound), `references/assets.md` (assets, placeholders, licensing), `signature/` (active signature in `resolved.json`, chosen in `source.env`, presets in `presets/`), `providers.env` (drafting: `agent` or `local` via `tools/draft.sh`), `voice.env` (TTS and word timestamps via `tools/tts.sh`, `tools/transcribe.sh`). The phases name the other tools when they need them: `check-sync.sh`, `captions.sh`, `fingerprint.sh`, `beat-sheet.sh`, `synth-audio.sh`, `preview-signature.sh` (compare bundled presets on the actual script before picking one), `preview-voice.sh` (compare TTS candidates by ear before picking one).
