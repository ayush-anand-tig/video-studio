# Video studio

Personal video studio built on `video-style-kit/`, a Claude skill for product/explainer videos: brief → script + beat map → voiceover → HyperFrames + GSAP composition → 4K render → ffmpeg export → QA.

## Setup
- `./install.sh` checks tools and installs the skill by symlink: `~/.claude/skills/video-style-kit` → `./video-style-kit` (edits here are live and tracked in git)
- Needs: `node`/`npx`, `ffmpeg`. HyperFrames comes via `npx`. Optional ElevenLabs key in `.env` (never commit)

## Where things are
- `video-style-kit/SKILL.md`: entry point. `references/style-guide.md` = look, motion, review checklist (read before building), `production.md` = render/export/QA
- `video-style-kit/providers.env`: script/scene drafting backend — `agent` (default, Claude writes it) or `local` (Ollama, via `tools/draft.sh`, to save tokens)
- `video-style-kit/assets/`: fonts + icon (free licences). `brand/`, `reference-films/`, `reference-frames/` are placeholders. Fill them with your own material
- `HANDOFF.md`: target repo structure, local tool choices, Mac Mini sizing, next steps. Read once when planning, not every session

## Placeholders to fill
`{{BRAND}}` (brand name) and `{{ACCENT_COLOR}}` (one accent hex) across the kit: `grep -rn "{{" video-style-kit`

## Rules
- One folder per video under `projects/<slug>/` (brief, beat map, audio, source, exports). Renders and audio are gitignored.
- After each review, append the lessons to `LESSONS.md`. Read it before starting a new video.
- Only use brand assets, music and footage you own or have a licence for.

## Token budget (Pro plan, keep usage low)
- Reply in ≤5 lines unless asked. No preamble, no recaps, no narrating tool steps.
- Read only the files the task needs, and only the relevant line ranges. Never read whole folders. No broad searches when the file is named above.
- Don't read `HANDOFF.md` unless planning the studio structure.
- No subagents, no parallel exploration, no web searches unless asked.
- Make the smallest change that works. Don't refactor or "improve" surrounding code.
- Don't re-run builds or tests after trivial edits. Run them once at the end of a change, and show only the last lines of the output (`| tail -5`).
- If a task looks big or unclear, ask one question first instead of exploring.
- At the end of a task, suggest `/clear` before the next unrelated task.
