# Style guide

Default look: clean, technical and calm. Change anything here if the user's brand calls for it, and record the change in `LESSONS.md`.

## 1. Look

- Light, quiet background (off-white or very light gray) with dark text. A dark variant works the same way with the values inverted.
- One accent, `{{ACCENT_COLOR}}`, reserved for whatever is active or important right now. If everything is accented, nothing is.
- Thin lines, subtle grids and small dots for structure. No gradients or glows unless the brand uses them.
- Show the real product (UI, terminal, diagram), simplified for readability. Avoid stock imagery.

## 2. Typography

- Bundled fonts: Sora (headlines), Inter (UI and body), JetBrains Mono (code). Swap them in `assets/fonts/` for your own.
- At 1080p, body text should be at least about 28 px and labels at least about 22 px. Test at half size (960×540): if you can't read it there, it's too small.
- Hold text on screen long enough to read it twice. Animate words in, but never while the viewer needs to read them.
- Keep it to one or two type sizes per scene.

## 3. Story and layout

- Build each video around a **main object** (a window, a card, a diagram) that stays on screen and changes, instead of cutting between unrelated slides.
- One idea per beat. Each beat answers "what changed, and why does it matter?"
- Show cause and effect: an input happens, then a visible result follows.
- Keep generous margins (about 8% of the width at the frame edges). Labels sit outside busy areas, joined by a short leader line.
- Use plausible sample data only. Never show real customer data, credentials or private URLs.
- End on the takeaway and the call to action, with the logo. Hold the last frame 1–2 s.

## 4. Motion

- Move the **camera** (scale and position of the scene group) to guide attention, rather than flying individual elements around.
- Easing: ease-in-out for camera moves and ease-out for entrances. Pick one curve per role and reuse it.
- Typical durations: camera moves 0.8–1.6 s, entrances 0.3–0.6 s, connector lines 0.4–0.8 s.
- Land each visual change on its narration keyword, or up to about 0.2 s before it.
- When text needs reading, stop the camera level and still. Never zoom while the viewer is reading.
- Prefer small zooms (1.1–1.3×) for detail. Use big moves only for big ideas.
- Use the same transition style for the same kind of change throughout the video.

## 5. Sound

- Narration: conversational, short sentences, active verbs. For 30 s, aim for about 65–70 words.
- Music: instrumental and unobtrusive, ducked under the voice, resolving at the end rather than cutting off.
- Sound effects: few and quiet, tied to real interactions (a click, a connection), not every movement.
- Delivery target: about −14 to −16 LUFS integrated, true peak ≤ −1 dBTP, or whatever the platform asks for.

## 6. Review checklist

The checklist moved to `phases/3-qc.md` (Gate 4), alongside the other QC checks.
