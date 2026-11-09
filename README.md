# Video studio

Make product and explainer videos with Claude Code: brief → script → voiceover → animated HTML composition (HyperFrames + GSAP) → render → ffmpeg export → review. Includes the `video-style-kit` Claude skill.

## Quickstart

```sh
git clone https://github.com/ayush-anand-tig/video-studio && cd video-studio
./install.sh          # checks tools, links the skill into ~/.claude/skills, reports voice options
claude                # then: "make a 20-second video about <topic>"
```

That's it — Claude reads `video-style-kit/SKILL.md` and works the brief with you conversationally (only asking about gaps it can't infer), writes the script, generates or waits for your voiceover, builds the HTML/CSS/GSAP scene, and renders it. Set your brand first: replace `{{BRAND}}` and `{{ACCENT_COLOR}}` (`grep -rn "{{" video-style-kit`) and add your logo to `video-style-kit/assets/brand/` — see `video-style-kit/references/assets.md` for the import checklist and reusable icon/footage/font sources if you don't have your own yet.

## Tools needed

| For | Required | Optional, better quality |
|---|---|---|
| Rendering | Node.js (`npx hyperframes`), ffmpeg | — |
| Script/scene drafting | — (Claude writes it by default) | A local Ollama model, to save tokens — see `video-style-kit/providers.env` |
| Voiceover | — (macOS `say` works out of the box) | Kokoro or Kitten TTS (better local quality, no GPU needed) or ElevenLabs (cloud) — see `video-style-kit/voice.env` |
| Word-level timestamps | — (falls back to even timing) | `faster-whisper` — see `video-style-kit/voice.env` |

Nothing optional is installed automatically; `install.sh` just reports what it finds so you know what you're missing.

## Make it yours

Every video carries a **signature** — a small set of consistent motion devices (how cause-and-effect, repetition, and identity render) so your videos look like *yours* no matter the topic. A bundled original default ships in `video-style-kit/signature/presets/` (pick with `SIGNATURE_SOURCE` in `video-style-kit/signature/source.env`: `default`, a local file, a GitHub repo, or any URL).

Want your own instead of the bundled one? Just ask, conversationally, in a Claude Code session here:

> "Help me design my own video signature."

Claude walks you through six quick questions (`video-style-kit/references/signature-wizard.md`) and writes a starter `signature/mine.json`. If you want it to stay personal/proprietary rather than public, say so — it'll tell you to keep that file in a private repo instead of this one.

## Token-light by default

`CLAUDE.md` and `.claude/settings.json` keep usage low (Sonnet by default, targeted reads, short replies, no reading of media files).

MIT licensed. Bundled fonts are under the OFL and the icon under ISC (see `video-style-kit/assets/`).
