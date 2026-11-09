# START HERE (for Claude on my personal laptop)

Turn two projects into two **public** GitHub repos under my personal account. Everything is pre-written.
**Don't explore or re-read the bundle.** Follow these steps exactly; it should take a handful of tool calls.

| Folder | What | Context file |
|---|---|---|
| `shravan/` | On-device Wispr Flow-style dictation app for macOS 26 (Swift) | `shravan/CLAUDE.md` |
| `video-studio/` | Video studio built around a Claude video skill (HyperFrames + ffmpeg) | `video-studio/CLAUDE.md` |

Each project already has `README.md`, `CLAUDE.md`, `.claude/settings.json`, `.gitignore`, `LICENSE` (MIT), `install.sh` and `HANDOFF.md`.

## Steps

1. Run `gh auth status`. If not logged in, tell me to run `! gh auth login` (personal account), then continue.
2. Ask me to confirm the GitHub username it shows. That's the only question to ask.
3. Run `./setup.sh --user <username>` (add `--private` only if I ask for it).
   It copies both projects to `~/code/`, commits them, runs each `install.sh` (builds and tests Shravan, links the video skill) **before** pushing, then creates the repos and pushes.
   It's safe to re-run: if it stops, fix only the reported problem (e.g. `brew install gh`, update Command Line Tools, set git identity) and run it again. If Shravan's tests fail only because Apple Intelligence isn't ready, re-run with `--skip-tests`.
4. Reply in ≤5 lines: both repo URLs, test result, and "Next: `cd ~/code/<project> && claude`".

Then stop. Future work happens in a new session inside each project folder, where its `CLAUDE.md` loads automatically.
A copy of this file and `setup.sh` is saved in each repo under `setup/`.

## Placeholders
- Video kit: `{{BRAND}}`, `{{ACCENT_COLOR}}`, and empty `assets/brand/` and `assets/reference-films/` folders (each has a PLACEHOLDER.md).
- Shravan: bundle ID `com.example.shravan` in `app/Info.plist`. Change it to your own before signing.

## First tasks later (one per session)
- **shravan:** manual GUI pass, then the "Known gaps" in its HANDOFF.md (URL protection, language gate, secure-field check).
- **video-studio:** fill the placeholders, create the skeleton, make one 20-second test video ("Next steps" in its HANDOFF.md).

## Token saving (built in, Pro plan)
Already set up in each repo:
- `.claude/settings.json`: **Sonnet is the default model**; build output and media files are blocked from reading.
- `CLAUDE.md` → **Token budget**: short replies, targeted reads, no subagents or web searches, builds run once at the end.

My habits:
- One task per session; `/clear` between unrelated tasks; `/compact` if a session gets long.
- Name exact files instead of asking Claude to search.
- Use `/model opus` only for hard design or debugging, then switch back to `/model sonnet`.
- Run builds and tests myself with `! <command>` when I only need the result. Check `/usage` now and then.
