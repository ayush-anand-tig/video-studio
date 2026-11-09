# Video studio

Make product and explainer videos with Claude Code: brief → script → voiceover → animated HTML composition (HyperFrames + GSAP) → render → ffmpeg export → review. Includes the `video-style-kit` Claude skill.

## Install

Needs Node.js, ffmpeg and Claude Code.

```sh
git clone https://github.com/<you>/video-studio && cd video-studio
./install.sh          # checks tools, links the skill into ~/.claude/skills
claude                # then: "make a 20-second video about <topic>"
```

Set your brand: replace `{{BRAND}}` and `{{ACCENT_COLOR}}` (`grep -rn "{{" video-style-kit`) and add your logo to `video-style-kit/assets/brand/`.

## Token-light by default

`CLAUDE.md` and `.claude/settings.json` keep usage low (Sonnet by default, targeted reads, short replies, no reading of media files).

MIT licensed. Bundled fonts are under the OFL and the icon under ISC (see `video-style-kit/assets/`).
