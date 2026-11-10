# Phase 1: Pre-production

Every creative decision gets made and written down before any audio or code exists. This is the cheapest place to fix things, so the timing check runs here first, not only in QC.

**Read:** `LESSONS.md` and `$K/references/style-guide.md` §3 and §5 only. **Create:** `mkdir -p $P/{audio,src,exports,qc}` (kebab-case slug), then work from `$P`.

## 1. Brief → `brief.md`

Write one line per field. Infer from the request, the user's repo/docs/demo and `LESSONS.md`, and ask only about gaps that change the video.

```
Subject:   what it is; where the facts come from
Audience:  who, and what they already know
Takeaway:  the one thing to remember
CTA:       what to do next
Format:    length (s), aspect (16:9 / 9:16 / 1:1), channel
Language:  narration + on-screen text
Tone:      one mood word
Theme:     signature, light/dark ground, accent
Voice:     TTS provider + voice (voice.env), or "user records"
Music:     none, synth (calm / cinematic / energetic), or a licensed track
Captions:  sidecar (default), burned + sidecar (muted autoplay: social, 9:16), or none
Facts:     bullets, each with its source. The script may claim nothing else.
```

- **Theme.** Run `$K/tools/load-signature.sh` every video (it's cheap, and it stops a stale `resolved.json` being used), then read `$K/signature/resolved.json`. If its `notes` say the subject is a poor fit, or if more than one bundled preset looks plausible for this subject, run `$K/tools/preview-signature.sh "<a line from the script>" qc/signature-preview.png` and show that one image — comparing the actual look settles it faster than comparing prose. Switching edits `signature/source.env` for later videos too, so say so. Accent: `{{ACCENT_COLOR}}` if set, otherwise the signature's `accentColorToken`.
- **Tone sets pacing.** Calm or cinematic takes the long end of timing ranges with ease-in-out. Energetic or playful takes the short end with ease-out.
- **Voice.** If it's not already settled (a returning project, or the user names one), run `$K/tools/preview-voice.sh "<a line from the script>" qc/voice-preview.wav` — it reads each candidate's name aloud, then that candidate's take on the line, back to back, so you pick by ear rather than from voice.env's comments. A provider that isn't installed is skipped with a note, not fatal. Set the winner as `TTS_PROVIDER`/`LOCAL_VOICE` in `voice.env`.
- **Language.** For anything other than English, confirm the voice speaks it (`say -v '?'` or Kokoro's per-language voices; Phonon's multilingual models are non-commercial) and skip the words-per-second rule. The bundled fonts are Latin-first, so add one per `$K/references/assets.md` if needed.
- **Music.** `synth` is the zero-setup option, as `say` is for voice: a plain synthesized pad with nothing to license (Phase 3 §4). Pick the mood nearest the Tone. A track has to pass the Music check in `$K/references/assets.md`.
- **Brand.** Use `{{BRAND}}` and a logo from `$K/assets/brand/`. If unset, ask once. If the user doesn't care, end on the takeaway and CTA with no logo. If `$K/assets/reference-frames/` has a contact sheet, one is enough for pacing.

## 2. Script

Shape it as an arc. Every beat serves one part, and a beat that serves none gets cut.

1. **Question:** the one thing the viewer wants answered (for a launch, the problem). The Takeaway answers it.
2. **Cause and effect:** how it works, one step per beat, each a visible input and its result. These are the `ripple`, `bridge` and `chain` beats.
3. **Turn:** the moment it clicks, or the reveal. It gets the video's biggest move, and nothing else competes with it.
4. **Payoff:** the takeaway, then the CTA, then the hold.

For 20 s that's about 4–6 beats. Write for the ear, at about 2–2.3 words per second in English (~45 words for 20 s). Every claim has to trace to a Fact. With `PROVIDER=agent` (the default, set in `providers.env`) you write it. With `local`, `$K/tools/draft.sh script <promptfile>` drafts it and you tighten the draft.

## 3. Beat map → `beats.json`

One idea per beat. From here on, this file is the only source of narration.

```json
[{"beat":"hook","t":0.0,"text":"Why did the build get slow?","action":"spinner stalls","word":"slow","primitive":"ripple"}]
```

- `beat` is a slug with no spaces or slashes (`check-sync.sh` uses it as a filename). `t` is the planned visual start in seconds. `text` is exactly what's said.
- `action` is what changes on screen, and `word` is the keyword it lands on.
- `primitive` is an enabled primitive from `resolved.json`. Vary them. Interpretive beats get none (`mechanismVsMeaningBoundary`).

## 4. Timing check (the animatic)

```sh
$K/tools/check-sync.sh beats.json
```

This speaks each beat in the real `voice.env` voice and compares when each line would start with its `t`. On DRIFT, copy the `audio_at` column into `t` so the visuals follow the voice. If a beat truly needs more screen time, add words rather than silence. The printed narration total plus a 1–2 s end hold should fit the brief's length. Re-run until it prints OK. If `tts.sh` itself fails, fix `voice.env` first (`say` always works on macOS).

## 5. Storyboard checkpoint

Before Production starts, show the brief's key lines and the beats as a table (beat, t, text, action) — every time, not only when asked. This is the storyboard: the cheapest point to catch a wrong beat, a missing fact or a weak turn, so it's the default feedback loop, not an opt-in extra. A change here is a `beats.json` edit and a re-run of `check-sync.sh`, nothing downstream yet. Only skip showing it when the user has already said not to pause for this kind of thing.

## Exit gate

- [ ] Every brief field is filled (or "none"), and every Fact has a source
- [ ] `load-signature.sh` ran for this video
- [ ] Every claim in `beats.json` appears in Facts
- [ ] Every beat serves one part of the arc, and the turn is clear
- [ ] `check-sync.sh` prints OK, and the narration total fits the length
- [ ] The storyboard checkpoint was shown (§5), and any resulting notes are resolved
