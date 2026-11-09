---
name: video-style-kit
description: Make short product, explainer and launch videos as code (HTML + GSAP rendered to MP4 with HyperFrames or Remotion, finished with ffmpeg). Use when the user asks to plan, script, animate, render or review a video.
---

# Video style kit

Videos are built as web pages that animate over time, rendered frame by frame to MP4, then mixed and exported with ffmpeg.

## Workflow

1. **Brief.** Pin down product, audience, one takeaway, length, aspect ratio, channel and call to action. Pull facts from the user's repo, docs or demo. Ask only about gaps that change the video.
2. **Script + beat map.** Write narration for the ear (about 2–2.3 words per second). `tools/draft.sh script <promptfile>` gives a first draft — by default (`PROVIDER=agent` in `providers.env`) that means writing it yourself; switch to `PROVIDER=local` to draft with a local Ollama model instead and save tokens, then review and tighten whatever it writes. Split the locked script into beats: one idea per beat, each with its on-screen action and the word it lands on. Get approval if the user wants a checkpoint.
3. **Voice.** Record or generate the VO, then get word timestamps (Whisper or WhisperX). Lock the audio before animating.
4. **Build.** Compose scenes in HTML/CSS with a single GSAP timeline driven by the renderer's clock. Reuse blocks from `scenes/` when present. Time every change to a word from the timestamps. For each beat, pick the matching primitive from `references/signature.md` (Ripple for the common case of one object changing; Bridge/Chain/Fan/Loop/Timeline/Compare only when the beat's shape actually calls for them) rather than defaulting to the same device everywhere. `tools/draft.sh scene <promptfile>` can draft a scene's starting markup/GSAP the same way step 2 drafts the script (agent by default, local model optional) — local models are noticeably weaker at animation code, so review these drafts more carefully than script drafts.
5. **Render + export.** Render the master, then make delivery copies with ffmpeg. See `references/production.md`.
6. **Review.** Run the checklist in `references/style-guide.md` §6, fix the issues, and re-render only what changed.
7. **Learn.** Append what the user corrected to `LESSONS.md` at the repo root. Read `LESSONS.md` before step 2 next time.

## Read when needed

- `references/style-guide.md`: look, typography, color, layout, motion, sound, review checklist. Read before building.
- `references/signature.md`: "a personal design" — the personal motion signature (Pulse bookend, and the Bridge/Ripple/Chain/Fan/Loop/Timeline/Compare/Origin/Analogy primitives). Applies by default; read alongside the style guide, not instead of it.
- `references/production.md`: renderer setup, deterministic animation, render and export commands, QA.
- `references/assets.md`: what's in `assets/` and the placeholders to fill.

## Brand

Use `{{BRAND}}` and `{{ACCENT_COLOR}}` from the user's settings, or ask once if they're still unset. Logos come from `assets/brand/`. Never redraw or retype a logo. If `assets/reference-films/` has films, study them for pacing only. Otherwise rely on this guide.
