# Video studio

Make product and explainer videos with Claude Code: brief → script → voiceover → animated HTML composition (HyperFrames + GSAP) → render → ffmpeg export → review. Includes the `video-style-kit` Claude skill.

## Quickstart

```sh
git clone https://github.com/ayush-anand-tig/video-studio && cd video-studio
./install.sh
claude
```

Then just say: **"make a 20-second video about `<topic>`."**

That's it — nothing to set up first. It works immediately with a bundled original default signature (a consistent set of motion devices so the video looks considered, not generic) and a neutral placeholder brand. Claude writes the script, generates or waits for your voiceover, builds the scene, and renders it, only asking you about gaps it can't infer.

Want your own brand or your own signature instead of the defaults? That's all optional and comes after — see "Make it yours" below.

## Tools needed

| For | Required | Optional, better quality |
|---|---|---|
| Rendering | Node.js (`npx hyperframes`), ffmpeg | — |
| Script/scene drafting | — (Claude writes it by default) | A local Ollama model, to save tokens — see `video-style-kit/providers.env` |
| Voiceover | — (macOS `say` works out of the box) | Kokoro or Kitten TTS (better local quality, no GPU needed) or ElevenLabs (cloud) — see `video-style-kit/voice.env` |
| Word-level timestamps | — (falls back to even timing) | `faster-whisper` — see `video-style-kit/voice.env` |

Nothing optional is installed automatically; `install.sh` just reports what it finds so you know what you're missing.

## Make it yours

Every video carries a **signature** — a small set of consistent motion devices (how cause-and-effect, repetition, and identity render) so your videos look like *yours* no matter the topic. The bundled default (`SIGNATURE_SOURCE=default` in `video-style-kit/signature/source.env`) is Halo; two more original presets ship alongside it (`preset:signal`, `preset:scanline`) — or point `SIGNATURE_SOURCE` at a local file, a GitHub repo, or any URL instead.

Want your own instead of the bundled one? Just ask, conversationally, in a Claude Code session here:

> "Help me design my own video signature."

Claude walks you through six quick questions (`video-style-kit/references/signature-wizard.md`) and writes a starter `signature/mine.json`. If you want it to stay personal/proprietary rather than public, say so — it'll tell you to keep that file in a private repo instead of this one.

## Token-light by default

`CLAUDE.md` and `.claude/settings.json` keep usage low (Sonnet by default, targeted reads, short replies, no reading of media files).

MIT licensed. Bundled fonts are under the OFL and the icon under ISC (see `video-style-kit/assets/`).
