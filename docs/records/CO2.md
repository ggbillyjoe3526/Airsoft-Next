# CO2 · Callouts in the feed and the radio click

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | 3310 / 3310 | – (QA Fail: blocking 1) | – |
| 2026-10-25 | 2 | worker | 3325 / 3325 | Retry 7/8 | fix round 1: QA blocking 1 fixed (on Keep a call pushed a hit out of a feed full of hits) |
| 2026-10-25 | 3 | worker | see Gate | Accept 8/8 | fix round 2: critic check 1 (Keep feed refused calls) fixed |

## Goal

The calls CO1's director says reach the player: your team's in the one hit feed with the hits (concept
`step27/callouts.png`), each with the radio click panned toward the speaker; an enemy's only as its click, close by and
through walls; Settings › HUD › Callouts to switch them off; the screen reader reading each call. Plan: project files
`plan/step27-deferred.md` › Bot callouts (CO2) and Defaults taken.

## Approach

- `HitFeed` (`game/ui/hit_feed.gd`): a line is a hit or a call (`call`, `words`); `add_call` fills the newest line
  as `add` does (one `_front`), so a call keeps the hits' time and fade and counts toward the lines shown. On Keep a
  call still ages and fades while the hits stay: the feed holds `max_lines` hits and up to `max_lines` calls beside
  them (its fixed pool made twice `max_lines` at setup), shows the newest `max_lines` (`shown`), and a hit a call moves
  past them is hidden, not dropped, until the call ages out (fix round 2). `drop_calls` takes the calls out, the hits
  keeping their order.
- `HudFeedRow` (`game/ui/hud_feed_row.gd`): `show_call` lays a call row out once: the team bar, the speaker's chevron
  and name (your team's colour, as a hit's names), a drawn radio glyph (a handset under its antenna, the grille cut
  across it) and the words in white, weight 600. `HudFeed._fill` fills a call row from the line; rows stay the ones made
  at setup.
- `Hud.on_calls` (`game/ui/hud.gd`) reads `CalloutLog` from the serial it read up to: your team's calls go into the
  feed and, with Screen reader messages on, `Announcer.add_call` gathers a polite "Brick: Two, Crate yard!"
  (`HUD_SR_CALL`). The other team's words are never read. Off, the calls are passed over (never shown late);
  `apply_prefs` with Callouts off drops the call lines at once; a round's start drops them.
- `SimAudio.on_calls` (`game/play/sim_audio.gd`) reads the log the same way: a teammate's call plays `radio_ack` on one
  of `radio_voices` (2) `AudioStreamPlayer3D`s made at setup on Interface, placed at the speaker's eyes, attenuation
  off and `panning_strength` = `SoundConfig.radio_pan` (0.6), so it is as loud anywhere and panned toward them at most
  0.6 of a field sound's pan; an enemy's plays through `_play` from their eyes within `enemy_radio_reach` (15 m),
  muffled by `SoundOcclusion` as their other sounds (Kind `RADIO_CALL`, field priority). `stop_calls` stops the
  callout voices and any enemy click sounding; the order click (`on_order`) is untouched.
- `PlaySession._after_tick` hands `_bots.callouts.said` to sound and the HUD after the HUD's tick; `_apply_hud` stops the
  clicks when Callouts goes off.
- `HudPrefs.callouts` (On; saved under "hud"; an old file or a bad value loads On), the Callouts row on Settings › HUD
  under Hit feed lines with its note, `SoundConfig`'s callout numbers (the browser's CALLOUTS and AUDIO levels:
  0.35, 0.6, pitch ± 0.04, pan 0.6, 15 m).
- CO1's review advisories: `CalloutsFile` capitalises `{area}` wherever a sentence starts (not only at the line's
  start); Pace's and Marks' defaults live only in their classes (the rows no longer repeat them); `Callouts._fits` is
  the one line filter `_line` and `_line_count` share; the guards' header and the CI job's comment name every field.
- Tests: `tests/unit/test_callouts_feed.gd` (23): the lines, the rows, the other team, each call once, a new log, the
  round's start, the setting (default, saved, old file, Off at once, never late, the tab), the screen reader, the
  teammate's and the enemy's clicks, Off and the order click, no object per call, and a match end to end.
  `test_callouts_file.gd` gains an area starting a later sentence.

## Risks

- The teammate's click is panned by Godot's 3D panner (the camera's frame), not the browser's stereo formula: its
  strength is the field's times 0.6 and it follows where the speaker stands, above or below included.
- A callout's click is not cut at a round's end: it is a short click, and its voice is freed with SimAudio.
- An enemy's click shares the field's voice pool with steps and shots (field priority), so in a busy firefight one can
  be dropped or take a step's voice; PLAYTEST › Callouts asks to listen for it in a firefight.
- Settings › HUD now scrolls at 1080p: the page is 763 px in a 734 px box, the minimap's note under the fold
  (`docs/KNOWN_ISSUES.md` row).
- While skipping a round (fast forward after you're out), calls and their clicks come at the skip's speed, as hits do.

## Defaults taken

- **A round's start drops the calls only:** the hits keep their rules (Keep holds them all match, Fade ages them), so
  "the feed is cleared at a round's start" is read as the call lines; last round's calls are stale.
- **On Keep a call shows on top of a full feed by hiding the oldest hit, not dropping it:** Keep promises the hits
  stay and the calls still go, so the feed holds both and shows the newest 10; the hidden hit comes back when the call
  ages out. A call takes only an older call's place, a hit only an older hit's (fix round 2).
- **A call is read to the screen reader only while the feed is up to show it** (`HudFeed.newest_shows`: not under the
  summary, on the range, or held to no lines under What got you).
- **The teammate's click uses its own two 3D voices** on Interface, not the plain pool: a plain voice has no pan, and
  the bus layout is not touched (no panner bus).
- **Callouts said while Off are skipped, not queued:** switching On shows only calls made after it.
- **The call's words are white at weight 600, the name bold in your team's light colour:** the concept's look; no
  team hue is new (the chevron and bar are your team's own).
- **"Brick: Two, Crate yard!" for the screen reader**, polite and joined with lines inside the 0.3 s window as hits are.
- **The calls a teammate makes while you spectate** still show and click: the radio is your team's, not your eyes'.
- **The settings note names no key:** "Your teammates' calls in the feed, each with a radio click; enemies close by
  are heard keying their radios."

## Measurements

Headless, the 4-core container, 2,000 calls each (scratch script, not kept):

| What | Cost |
|---|---|
| A teammate's call read into the feed and its six rows refilled (once per call) | 55 to 61 µs |
| Its click (`SimAudio.on_calls`) | 7.2 to 8.5 µs |
| An enemy's click, in reach (a field voice, occlusion open) | 12.8 to 14.0 µs |
| A tick with no call (both readers) | 1.9 to 2.0 µs |

A team says at most one call every 1.5 s, so the feed's refill is about 0.04 µs a tick averaged. Objects: none made
by 4,000 calls through the HUD (static memory +512 bytes, noise); the audio side holds 4 objects and 51 KB for the
playbacks in flight, the same after 12,000 calls. The test `test_a_call_makes_no_object` holds the HUD's side.

Real matches at 1920 x 1080 (Compatibility, Xvfb), Depot, speed 2: seed 3 said 10 calls in 58 s, seed 4 said 4 in 9 s,
each showing as lines among the hits.

## Pictures

In `screenshots/step27/` (project files), each a real match on Depot with bots playing:

- `co2-feed-top-right.png`: the default corner, two calls among two hits ("Jinx: One, West room!", "Rocket: Eyes on
  one, Alley.").
- `co2-feed-bottom-left.png`: the feed moved bottom left, the newest at the bottom.
- `co2-feed-rows-3x.png`: the rows enlarged: chevron, name, radio glyph, words.
- `co2-settings-hud.png`: Settings › HUD with the Callouts row.

## Verified

- `test_callouts_feed.gd` 23, `test_callouts_file.gd` 14, `test_callouts.gd` 25, `test_hit_feed.gd`,
  `test_hud_prefs.gd`, `test_announcer.gd`, `test_so3_qa.gd` pass.
- The pictures above, looked at.
- Not verified: how the clicks sound and pan on speakers or headphones, and a screen reader reading the calls; the
  owner's PLAYTEST › Callouts (CO2).

## Fix round 1 (attempt 2)

- QA blocking 1: on Keep a call took the oldest hit's line when the feed was full of hits. `HitFeed.add_call` now
  leaves the call out on a full Keep feed with no call in it (`_oldest_call`, shared with `_front`); QA's
  `test_co2_qa.gd` pins it.
- Advisories taken: every Settings tab's ScrollContainer follows focus (`SettingsScreen._page`, `follow_focus`), so the
  keyboard or a pad scrolls Settings › HUD to the row it reaches; the long comment lines QA listed are wrapped to the
  usual width; `SimAudio.stop_calls` no longer builds a throwaway default array; the Risks above note the click at a
  round's end and the enemy's click in the field's pool.

## Fix round 2 (attempt 3)

- Critic check 1: fix round 1 made a full Keep feed refuse every call, so after about two rounds a Keep player saw no
  more calls. Now `HitFeed` has a fixed pool of twice `max_lines`: on Keep it holds `max_lines` hits and up to
  `max_lines` calls, `_make_room` frees only a line of the new line's own kind (the oldest not kept), and `shown()`
  is the newest `max_lines`, which `HudFeed` draws. A call always shows on top; the hit it moves past the tenth row is
  hidden and shows again when the call ages out. Fade is as before (the oldest line not kept goes).
- `Hud.on_calls` reads a call aloud only when `HudFeed.newest_shows()`.
- Tests: `test_callouts_feed.gd` (25): a call over ten kept hits and the tenth back after it ages out (the feed, and
  the HUD's rows), calls taking each other's place, never a hit's; `test_co2_qa.gd`'s Keep test also asserts the call
  is line 0 and the hit hidden, not dropped.

## Files outside `touches`

- `game/config/callouts_file.gd`, `game/ai/callouts.gd`, `tests/guards/test_callout_guards.gd`,
  `.github/workflows/ci.yml` (comment): CO1's review advisories, as the coordinator asked.
- `game/ui/settings_screen.gd` (fix round 1: `follow_focus` on every tab's page, the QA advisory).
- `game/play/README.md`, `game/config/README.md`, `docs/KNOWN_ISSUES.md`, `docs/wiki/Roadmap.md`,
  `docs/wiki/Accessibility.md`, `changelog.d/bot-callouts.md` (its "in a coming update" sentence): docs.

## Advisories left

- **A click is not cut at a round's end** (QA): it is short and its voices stop when SimAudio is freed.
- **Enemy clicks share the field voice pool with steps and shots** (performance): within the cue_voices cap; PLAYTEST
  asks for a listen in a firefight.
- **Small notes** (critic): one wiki line in HUD-and-Minimap.md runs past the wrap width; no test for a call left
  unread while What got you holds the feed to none.

## Gate

`tools/check.sh` on `eff1b7d`'s tree (CO2 on CO1 at `15f1cee`; this record not yet written), on the 4-core container,
passed in about 1,080 s: gdlint, the changelog notes and the wiki; unit tests part 1 829 tests in 344 s, part 2 1,570
in 337 s, part 3 911 in 318 s (3,310, all passing); the smoke test (a whole match on Depot with callouts on, no script
errors); the licence notices. The match guards were not run: the director's only changes are an area's capital and a shared line filter (the
same lines and the same draws), held by `test_callouts.gd` and `test_callouts_file.gd`.

Fix round 1: `tools/check.sh` on `3f86ab4` (the fix over QA's `0c54a6a`, CO2 rebased onto `a334f81`), on the 4-core container, passed in about 1,125 s: gdlint, the changelog notes and the wiki; unit
tests part 1 844 tests in 348 s, part 2 1,570 in 334 s, part 3 911 in 331 s (3,325, all passing, `test_co2_qa.gd` 4 of
4 among them); the smoke test; the licence notices.

Fix round 2: `tools/check.sh` on `f5c4c2e` (the Keep fix; this record's edit the only change since), on the 4-core
container, passed in about 1,115 s: gdlint, the changelog notes and the wiki; unit tests part 1 846 tests in 341 s,
part 2 1,570 in 333 s, part 3 911 in 328 s (3,327, all passing, `test_callouts_feed.gd` 25 and `test_co2_qa.gd` 4
among them); the smoke test; the licence notices.
