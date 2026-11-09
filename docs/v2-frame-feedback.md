# v2 design: frame-level creator feedback

Status: **design only, not built.** This file sits outside `video-style-kit/` on purpose. Nothing in the skill's runtime docs refers to it, so a video session never treats an unbuilt tool as an instruction. Build it after a few real videos have gone through Phase 3 with hand-written `notes.md` (HANDOFF.md, next steps).

## Goal

A creator watches a cut, points at a moment ("at 3.2 s the card is clipping", a screenshot, "this transition feels rushed") and the note lands on the right beat, the right code and the right fix route without anyone re-deriving where it belongs. QC's "When a gate fails" table does this for mechanical failures. This does it for subjective notes.

**In scope:** pointing at a moment by time, range, beat or screenshot; resolving it to beat → offset → code lines; routing it by category through Phase 3 §3's table; showing Claude the frame at minimum token cost; checking the fix in the next cut.

**Out of scope:** a GUI editor, player plugins, element-level hit-testing (that's v3, below), the tool making the fix itself (Claude still does that), and multi-reviewer threads.

## Where it fits

Phase 3 (Edit) §2 already takes notes in `notes.md`: one line per note, anchored to a time or a beat, closed as `[x]` fixed or `[~]` waived. v2 keeps that file as the human-facing source of truth and adds a resolver next to it. The v1 grammar is a strict subset of v2's, so old notes stay valid.

```
creator watches exports/cut.mp4 ──► notes.md (hand-written, or pasted from the review page)
                                       │
                         tools/feedback.sh resolve        (deterministic: anchor → time → beat → code → route)
                                       │
                 notes.json + 1-line-per-note table + qc/notes.jpg (one image, all open notes)
                                       │
               Claude fixes per route ──► render + cut ──► feedback.sh verify (before/after sheet)
                                       │
                         Claude closes notes in notes.md ──► Phase 3 gate
```

## 1. Pointing at a moment

The creator watches in whatever player they like. Four anchors, from least to most effort:

| Anchor | Example line in `notes.md` | When to use |
|---|---|---|
| Beat | `- [ ] payoff: end hold too short` | the note is about a whole beat |
| Time | `- [ ] 3.2 card clips the right edge` · `0:03.2` · `1:04` | the usual case |
| Range | `- [ ] 7.0-7.8 transition feels rushed` | transitions and pacing, which happen over time, not on a frame |
| Screenshot | `- [ ] @shot-1 label overlaps the arrow` | the time is vague, or the creator wants to show *where in the frame* |

Optional `#category` tag at the end (section 4). Optional `(creator)` / `(self)` source, as in v1.

**Why a screenshot isn't required.** Renders are deterministic, so the tool can always regenerate the exact frame at a timestamp. A screenshot adds two things: it pins the frame when the creator's player only shows whole seconds, and it shows *where* in the frame they mean, especially if they circle something. Screenshots go in `$P/shots/` (gitignored once v2 lands, so the pre-commit hook's media warning never fires on them) and are referenced as `@<basename>`.

**Getting a precise time without a special player (optional review page, build last).** `feedback.sh round` also writes `qc/review.html`: a static page with a `<video>` of `../exports/cut.mp4`, a time readout to 0.01 s, `,`/`.` to step one frame, and `N` to type a note at the current time. Notes collect in a list on the page, and a "Copy for notes.md" button puts them on the clipboard as ready-made lines (`- [ ] 3.24 … (creator)`). It's file:// only, with no server, no file writes and no network, and Claude never reads it. This solves timestamp precision with no extra install.

**A screenshot pasted straight into the Claude Code prompt** never touches the disk, so the tool can't match it. Claude handles it without the tool: it compares the image with the latest beat sheet (`qc/beats.jpg`, already one image) to pick the beat, writes the note as a beat-anchored line, and asks for a time only if two beats look alike.

## 2. Review rounds: anchoring notes to a cut version

A time only means something against the cut it was watched on. If notes from round 1 get resolved after round 2's retime, "3.2 s" points at the wrong beat. So notes are grouped by round:

```
## Round 2 · cut 92a075144194b217
- [ ] 3.2 card clips the right edge (creator)
```

`feedback.sh round` opens a round. It refuses unless `fingerprint.sh check exports/cut.mp4` is OK, appends the heading to `notes.md` (append-only; the tool never rewrites the creator's lines), and stores a snapshot in `notes.json`: `{fp, cues (copy of src/cues.json), duration}`. A note resolves against **its own round's cues**, so an old note still finds its beat after the timeline moves.

## 3. Resolution: time → beat → code

For each open note, `feedback.sh resolve` does the following:

1. **Anchor → time.** Time and range parse directly (`s`, `m:ss`, `m:ss.f`). A beat anchor uses the beat's whole span. For a screenshot:
   ```sh
   ffmpeg -i exports/cut.mp4 -loop 1 -i shots/<s> -filter_complex \
     "[0:v]fps=10,scale=320:180,format=gray[a];[1:v]scale=320:180,format=gray[b];[a][b]ssim=stats_file=<log>:shortest=1" -f null -
   ```
   Then take the frame with the highest `All:` score, t = (n−1)/10. Measured on a 16 s fixture: a 1280×720 JPEG screenshot matched the exact frame (SSIM 0.998) in 0.24 s. Rules: best < 0.90 → `no match` (ask for a time; likely a crop, a window grab or the wrong video). All frames within 0.005 of the best → report them as a range (a held frame), not a single time. A typed time on the same line (`@shot-1 ~3s`) restricts the search to ±1.5 s, which also settles near-ties.
2. **Time → beat.** Take the last beat in the round's cues with `cue ≤ t`, and offset = t − cue. Within 0.4 s of a beat start → `boundary: prev→next`, and both beats are candidates (transition notes live there). A range covers every beat it overlaps.
3. **Word at that moment** (context only): the `words.json` word whose span contains t. Without `words.json`, give the beat's `word` field.
4. **Beat → code.** `grep -n '// beat: <slug>' src/*` gives the block's first line, and the block runs to the line before the next marker. Phase 2 §3 already requires the marker. Videos built before that rule fall back to lines matching `cues\.<slug>|cues\[["']<slug>["']\]`. Layout and look notes also list `src/film.css`.
5. **Category → route.** This is a lookup, never a guess (section 4).

Output is one line per note. This table is all Claude reads:

```
id      anchor        beat (offset)        cat     fix in                                   then
a1b2c3  3.2s          cause (+1.1s)        layout  src/film.js:41-63, src/film.css          render + cut
d4e5f6  7.0-7.8s      cause→turn           motion  src/film.js:41-63, 64-80                 render + cut
g7h8i9  @shot-1→9.0s  turn (+1.6s) ssim.99 layout  src/film.js:64-80, src/film.css          render + cut
j0k1l2  payoff        payoff (all)         ?       needs a #category
```

Plus `qc/notes.jpg`: one tiled image with a tile per open note, 480 px, in the same order as the table. A range note's tile is a 3-frame strip (start, middle, end), because "rushed" can't be judged from one frame. This is the only image Claude reads per round, however many notes there are.

## 4. Categories and routing: one table, not two

The routes are Phase 3 §3's table. v2 adds a tag column to that table and nothing else, so there is a single routing source:

| Tag | Phase 3 §3 row | Fix in | Then |
|---|---|---|---|
| `#timing` | rushed / lingers / lands early or late | the beat's block in `src/film.js` | render + cut |
| `#start` | beat starts early or late against its words | `t` in `beats.json`, then cues + captions | render + cut |
| `#length` | needs more or less screen time | Phase 1 words | Phase 2 from Voice |
| `#motion` | transition, camera, emphasis | the beat's block (both beats at a boundary) | render + cut |
| `#layout` | layout, overlap, readability, caption placement | the beat's block + `src/film.css` | render + cut |
| `#captions` | caption line breaks | `captions.sh --max-chars` | render + cut if burned |
| `#words` | wording, a claim, the story | Phase 1 | Phase 2 from Voice |
| `#sound` | music or effects | Phase 3 §4 (`audio/sfx.txt`, the bed) | mix + export |

**Who assigns the category.** The creator can type a tag. Otherwise Claude appends one to the line in `notes.md` before resolving: it's an LLM, which beats a keyword list, and the tag stays visible and editable by the creator. The tool never guesses. An untagged note is reported as `needs a #category` and skipped. Keeping judgment (the category, the fix) with Claude and lookup (time, beat, lines, route) with the tool keeps the tool small and testable.

**Drift guard.** The tool holds the tag → route mapping as a `case` statement. An acceptance test (section 7) checks that every tag in the tool appears in `phases/3-edit.md`'s table, so the two can't drift silently.

## 5. Data: `notes.json` (generated, never hand-edited)

```json
{"rounds": {"92a075144194b217": {"n": 2, "cues": {"hook": 0, "cause": 2.1}, "duration": 16.0}},
 "notes": [{
   "id": "a1b2c3",                 "round": "92a075144194b217",
   "line": "3.2 card clips the right edge #layout (creator)",
   "anchor": {"kind": "time", "t": 3.2, "until": null, "shot": null, "ssim": null},
   "beat": "cause", "offset": 1.1, "boundary": null, "word": "cache",
   "category": "layout",
   "fix_in": ["src/film.js:41-63", "src/film.css"], "then": "render + cut",
   "before": "qc/notes/a1b2c3-before.jpg",
   "status": "open"}]}
```

- `id` is the first 6 hex characters of the sha256 of round + normalized line text. It's stable across reordering. An edited line is a new note, and orphans drop out on the next resolve.
- `status` mirrors the checkbox in `notes.md` (`open` / `fixed` / `waived`). `notes.md` wins every time. The tool only reads it.
- `before` is the frame (or strip) saved at resolve time, kept for verify.

## 6. Closing the loop: beat-relative verify

After Claude fixes and runs render + cut, `feedback.sh verify` pairs each `[x]` note's `before` with an **after** frame. The after frame is taken at `current cues[beat] + offset`, not at the old absolute time, so it shows the same story moment even if the fix (or anything else) moved the beat. The pairs go side by side in `qc/verify.jpg`, one image. Claude, or the creator if they're reviewing, confirms. A note whose after frame still shows the problem gets reopened (`[ ]`) with a short reason.

Gate addition for Phase 3 once v2 exists: every note closed, every `[x]` note confirmed in `verify`, and `fingerprint.sh check exports/cut.mp4` OK.

## 7. Build plan

One tool, `video-style-kit/tools/feedback.sh` (sh + jq + ffmpeg, like the others). Subcommands: `round`, `resolve`, `sheet` (called by resolve; separate for re-runs), `verify`. Then:

1. `round` + `resolve` for beat, time and range anchors. Add the tag column to `phases/3-edit.md` §3, and replace §2's anchor paragraph with the two commands. The doc grows by about 4 lines.
2. Screenshot matching (section 3.1) and the `shots/` gitignore line.
3. `verify`.
4. The review page (`qc/review.html`), last and optional.

**Fixture.** A 4-beat `beats.json` and a cut made of solid colors per beat (`color=c=…` segments joined with `concat`, since this machine's ffmpeg has no drawtext), plus one 2 s hold, so matches are unambiguous and holds are testable.

**Acceptance tests:**
1. `3.2` → `cause (+1.1s)`, with the line range of `// beat: cause`.
2. `7.35` with turn at 7.4 → `boundary cause→turn`, and both blocks listed.
3. A 1280×720 JPEG of the frame at 9.0 s → 9.0 s ±0.1, SSIM ≥ 0.95. A frame from another video → `no match`. A frame inside the hold → a range.
4. A round-1 note at 3.2 s, after `cause` moves from 2.1 to 2.6 → still `cause`; verify grabs 3.7 s.
5. An untagged note → `needs a #category` and no route.
6. `round` on a STALE cut → refuses with fingerprint.sh's message.
7. Every tag in `feedback.sh` appears in `phases/3-edit.md`.
8. Re-running `resolve` with no changes leaves `notes.json` byte-identical.

**Token budget.** Per round: the table (about 30 tokens per note), one `notes.jpg`, one `verify.jpg`. No video is ever read, and `exports/` stays unreadable.

## Open questions

- **Pronunciation notes** ("it says Kuber-NEET-ees"). The fix is a respelling for TTS, but `beats.json` `text` also feeds the captions. Likely answer: an optional per-beat `say` field that `tts.sh`/`check-sync.sh` use instead of `text`, with captions keeping `text`. That's a schema change, so decide it when it first comes up.
- **Notes on a crop or the final** rather than the cut. Times carry over. Screenshot matching against a 9:16 crop needs a crop-aware match, so ask for the time instead until that comes up.
- **v3: element hit-testing.** Seek the composition in headless Chrome to t and run `document.elementFromPoint` at a circled point to get the element's id, then grep it in `src/`. That gets from "the card" to `#cache-card` exactly. Only worth it if section 3's beat-block resolution turns out too coarse in practice.
