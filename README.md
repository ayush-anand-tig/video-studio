# Video studio

Make product and explainer videos with Claude Code, run like a small production house: pre-production (brief, narration, tone, theme, language) → production (voiceover, captions, animated HTML composition with HyperFrames + GSAP, render) → edit (rough cut, notes, sound, picture lock) → QC (freshness, sync, loudness, frames). Includes the `video-style-kit` Claude skill.

## Quickstart

```sh
git clone https://github.com/ayush-anand-tig/video-studio && cd video-studio
./install.sh
claude
```

Then just say: **"make a 20-second video about `<topic>`."**

That's it — nothing to set up first. It works immediately with a bundled original default signature (a consistent set of motion devices so the video looks considered, not generic) and a neutral placeholder brand. Claude writes the brief and script, generates or waits for your voiceover, builds the scene, renders it and QCs it, only asking you about gaps it can't infer.

## How it works

One skill, four phases. `video-style-kit/SKILL.md` is a short producer's run sheet, and each phase has its own doc in `video-style-kit/phases/` with an exit gate. Claude doesn't move on until the gate passes.

| Phase | Decides / makes | Gate |
|---|---|---|
| 1. Pre-production | Brief (audience, takeaway, tone, theme, language, music, captions, sourced facts), a script shaped as question → cause and effect → turn → payoff, beat map | `tools/check-sync.sh` confirms the narration fits the planned timing, before any code is written |
| 2. Production | Voiceover, word timing, captions, scenes, render, rough cut | Cues and captions generated from the beat map; animation is deterministic; the rough cut is stamped with a fingerprint of its sources |
| 3. Edit | Watch the rough cut (one beat sheet), notes, fixes, picture lock, music and effects, mix, final export | Every note closed in a fresh cut; final exported from the locked render |
| 4. QC & delivery | Spec + freshness, sync, loudness, contact-sheet review against a checklist | All four gates pass (a render older than its sources fails), then 4K/vertical/caption deliverables and a line in `LESSONS.md` |

Give notes on a cut ("at 3.2 s the card clips") and Claude takes them back through Edit. Say "review this video" to jump straight to QC, or point Claude at an existing `projects/<slug>/` to resume wherever it left off.

Want your own brand or your own signature instead of the defaults? That's all optional and comes after — see "Make it yours" below.

## Tools needed

| For | Required | Optional, better quality |
|---|---|---|
| Rendering | Node.js (`npx hyperframes`), ffmpeg | — |
| QC (sync check) | `jq`, `bc` (both ship with recent macOS) | — |
| Script/scene drafting | — (Claude writes it by default) | A local Ollama model, to save tokens — see `video-style-kit/providers.env` |
| Voiceover | — (macOS `say` works out of the box) | Kokoro or Kitten TTS (better local quality, no GPU needed) or ElevenLabs (cloud) — see `video-style-kit/voice.env` |
| Word-level timestamps | — (falls back to even timing) | `faster-whisper` — see `video-style-kit/voice.env` |
| Captions (SRT, VTT, burned in) | — (`jq`, from the beat map) | `faster-whisper`, for tighter timing |
| Music and sound effects | — (none, or a synthesized pad and UI sounds from ffmpeg, license-free) | Your own licensed track |

Nothing optional is installed automatically; `install.sh` just reports what it finds so you know what you're missing.

## Make it yours

Every video carries a **signature** — a small set of consistent motion devices (how cause-and-effect, repetition, and identity render) so your videos look like *yours* no matter the topic. The bundled default (`SIGNATURE_SOURCE=default` in `video-style-kit/signature/source.env`) is Halo; two more original presets ship alongside it (`preset:signal`, `preset:scanline`) — or point `SIGNATURE_SOURCE` at a local file, a GitHub repo, or any URL instead.

Want your own instead of the bundled one? Just ask, conversationally, in a Claude Code session here:

> "Help me design my own video signature."

Claude walks you through six quick questions (`video-style-kit/references/signature-wizard.md`) and writes a starter `signature/mine.json`. If you want it to stay personal/proprietary rather than public, say so — it'll tell you to keep that file in a private repo instead of this one.

## Token-light by default

`CLAUDE.md` and `.claude/settings.json` keep usage low (Sonnet by default, targeted reads, short replies, no reading of media files).

MIT licensed. Bundled fonts are under the OFL and the icon under ISC (see `video-style-kit/assets/`).
