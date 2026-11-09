# Signature wizard

A quick, conversational way to get a starter `signature.json` of your own — not a research
project. Ask these six questions **one at a time**, in chat, not as a form. Infer an answer
from context where you already have one instead of asking. When done, write the result to
`signature/mine.json` (never into `signature/default.json` — that one's shared) and set
`SIGNATURE_SOURCE=local:signature/mine.json` in `signature/source.env`.

Trigger this when the user asks to build their own signature, design pattern, or visual
identity for their videos.

## The six questions

1. **"What are your videos mostly about — explaining how something works (tech, science,
   process), or telling a story/making an argument (history, culture, opinion)?"**
   → mechanism-heavy: enable `bridge`, `chain`, `fan`, `loop`, `timeline` by default.
   → narrative-heavy: lean on `ripple`, `compare`, `origin`; leave the rest enabled but
     expect them to be used rarely.

2. **"One mood word for your videos — calm, energetic, cinematic, playful, something
   else?"** → sets pacing: calm/cinematic lean toward the longer end of each primitive's
   timing range and ease-in-out; energetic/playful lean toward the shorter end and
   ease-out.

3. **"Should your identity mark always be visible in a corner, or just appear briefly at
   the very start and end?"** → `pulse.mode`: `continuous` or `bookend`. Default to
   `bookend` if they're unsure — quieter, works across more tones.

4. **"Do your explanations usually involve two separate things you're connecting (e.g. two
   systems, a before/after), or mostly one thing changing over time?"** → how central
   `bridge` is versus `ripple`. Doesn't disable either, just tells you which to reach for
   first when you're unsure which primitive fits a beat.

5. **"Is there a color, a show, a game, or an aesthetic you're drawn to — as a feeling
   reference, not something to copy directly?"** → free text. Use it only as inspiration
   for `notes` and, if they want an Origin vignette style, as a direction to translate
   into your own geometric language — never as a skin to copy. Say this limit out loud if
   their answer names something very visually specific (a show, a game) so they know you
   won't be copying it outright.

6. **"One accent color, or should I pick one for you?"** → `accentColorToken`. If they
   want you to pick, choose something that isn't one of the generic AI-default looks
   (avoid a plain Tailwind-blue or violet-gradient feel) and say what you picked and why
   in one line.

## After the questions

Write `signature/mine.json` following `signature.schema.json`, fill `colorRoles` and
`scopeRules` with the defaults from `signature/default.json` unless something in their
answers suggests otherwise, and tell them in 2–3 lines what you built and how to change
`SIGNATURE_SOURCE` later if they want to point at a different file instead.

**Say this plainly once, at the end:** if this signature is meant to be personal or
proprietary to them, `signature/mine.json` should stay out of any repo they intend to make
public — keep it in a private repo or local-only, and
point `SIGNATURE_SOURCE` at that path instead of committing it here.
