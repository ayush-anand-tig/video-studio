# Bundled assets

All paths are relative to the skill folder.

## Style references (placeholders: add your own)

| Folder | Put here |
| --- | --- |
| `assets/reference-films/` | 2–3 finished films whose pacing and motion you want to match (your own, or ones you have rights to). Optional; used for pacing reference only |
| `assets/reference-frames/` | Contact sheets and key frames exported from those films |

Reference films teach visual and pacing decisions only, not product facts, copy or current API syntax.

## Identity and UI assets

| Folder | Contents |
| --- | --- |
| `assets/brand/` | Placeholder. Add your own `logo-dark.svg` and `logo-white.svg`. Preserve aspect ratio; never retype a logo |
| `assets/fonts/` | Sora variable TTF, Inter 400/700 WOFF2, JetBrains Mono 400 WOFF2, with their OFL license files (free to reuse) |
| `assets/icons/` | Lucide PhoneCall SVG and its ISC license (free to reuse) |

Placeholders used in the docs: `{{BRAND}}` = your brand name, `{{ACCENT_COLOR}}` = your single accent color.

## Reusable sources (free, commercial-safe) — for anything not bundled

Logos and your own reference films can't come from anywhere but you, but icons, b-roll and fonts
can. Check each source's current license page before use — terms can change.

| Need | Source | License notes |
| --- | --- | --- |
| More icons | [lucide.dev](https://lucide.dev) (same set as `assets/icons/`) | ISC, free, no attribution |
| More icons | [heroicons.com](https://heroicons.com), [phosphoricons.com](https://phosphoricons.com) | MIT, free, no attribution |
| B-roll / stock footage | [pexels.com/videos](https://www.pexels.com/videos/), [pixabay.com/videos](https://pixabay.com/videos/) | Free for commercial use, no attribution required; can't resell as-is or imply endorsement |
| B-roll / stock footage | [mixkit.co](https://mixkit.co/free-stock-video/) | Free license, no attribution; can't redistribute as a competing stock library |
| More fonts | [fonts.google.com](https://fonts.google.com) | Mostly OFL/Apache — same family as the bundled Sora/Inter/JetBrains Mono |
| Animated flourishes | [lottiefiles.com](https://lottiefiles.com) (filter to free) | Mixed licenses — verify the specific animation's license, not the site-wide default |

Treat anything pulled from these as pacing/visual filler the same way reference films are used: never
let stock b-roll carry product facts or copy, only mood and motion.

## Criteria for importing your own asset

Check every item before an asset goes in `assets/` or a project folder. If it fails any line, fix
that first — don't add it "for now."

**Logo** (`assets/brand/`)
- Vector (SVG) preferred; if raster, PNG with a transparent background at ≥512px on the short side
- A dark-on-light and a light-on-dark variant, both correctly colored (not just inverted)
- You own it or have written permission to use it in rendered video
- Never redrawn, retyped, or recolored from a screenshot — use the source file

**Reference film / your own footage** (`assets/reference-films/`, `projects/<slug>/`)
- You own it, licensed it, or it's public domain / permissively licensed (not just "found online")
- Resolution ≥ the target render (no upscaling soft footage to fill the frame)
- Frame rate and color space compatible with the render pipeline (see `phases/2-production.md`)
- Anyone recognizable in it has consented to the footage being used this way
- Used for pacing/motion reference only — never treat it as a source of product facts or copy

**Font** (`assets/fonts/`)
- License explicitly permits embedding in distributed/rendered video, not just on-screen display in an editor (most desktop/OFL licenses do; some commercial and "personal use" fonts don't)
- Keep the license file alongside it, same as the bundled OFL fonts

**Music / SFX**
- You own it, or hold a license that covers the video's actual distribution (YouTube, ads, etc. — sync rights, not just streaming rights)
- Sample rate ≥ 44.1kHz, no audible compression artifacts
- No license needed for `tools/synth-audio.sh` output (the `synth` music bed and the tick/click/pop/whoosh effects): it's generated from sine waves and seeded noise, with nothing sampled
