# Adding content

How a new replica, part, map, mode or skin gets into the game: the rulebooks, the briefs, the checks and the report.
Read it before adding any content; the `new-content` skill (`.claude/skills/new-content/SKILL.md`) walks a thread
through it.

The rules carry from the browser game; its toolkit (the checks and the command) is rewritten for Godot. Until then the
browser game's checks in `legacy/browser/src/content/` and its command `legacy/browser/pipeline/content-check.mjs` are
the reference.

## The steps

1. **Ask.** The owner tells Claude in a thread what he wants ("a DMR", "a holo sight") (owner, 2026-10-05).
2. **Brief.** Claude asks the questions in that type's rulebook, offers a default for each, and writes a spec sheet from
   the answers for the owner to approve: the item's numbers beside the content already in the game, what it is good and
   bad at, its look and its sound.
3. **Build.** Claude adds the rows to `data/pool.md` and `data/stats.md`, the item's Name to a level in
   `data/levels.md`, any code, the model and the sounds. New content is always tagged `dev`, so only the owner sees it
   (Settings › Dev › Dev content).
4. **Check.** The content check runs the checks, quickest first (below) (command: rewritten with the Godot content
   toolkit).
5. **Report.** The check writes a one-page report in plain words, with pictures. The thread attaches it.
6. **Playtest.** The owner tries it with Dev content on. When he says "make it public", the public gate runs and only
   then does `dev` become `public`.

A fail stops an item going public. A warning ("look at this") is shown to the owner and he decides.

## The rulebooks

| Type | Rulebook | Checks built in the browser game |
|---|---|---|
| Replicas | `docs/content/replicas.md` | All four levels |
| Parts (optics, grips, lasers, magazines, barrels, muzzles, lights, power sources) | `docs/content/attachments.md` | All four levels |
| Maps | `docs/content/maps.md` | All four levels (level 2 is the layout) |
| Game modes | `docs/content/modes.md` | All four levels (level 2 is its fit and short matches) |
| Skins | `docs/content/skins.md` | Levels 1 to 3 (level 2 is its fit; no balance run, a skin changes no number) |

Every type keeps the standing rules: one hit is one hit, toys not firearms, no real brand names or copied trademarked
designs, nothing map-only, and an ID (pool ID, map id, mode id) never changes once given.

## The four levels

1. **Rules:** is everything filled in, correctly, and wired up? (seconds)
2. **Compatibility:** does it work with everything it is meant to work with? For a map, its **layout**: lanes,
   sightlines, walk times against Depot's. For a mode, its **fit**: short headless matches of every ruleset, level,
   team size and Custom switch, and the bots playing it their own way. (seconds; a mode's matches about half a minute)
3. **Spec test:** does it shoot, look and cost what the spec sheet says? Numbers, model cost, sound and pictures.
   (about a minute, 2026-10-11)
4. **Balance run:** headless bot matches on every map, lighting, round mode and level: is it fair? (about 3 minutes per
   map, lighting and pairing at the default 8 seeds; the maps run in parallel, 2026-10-11)

Levels 1 and 2 run for every asset, map and mode in every pull request (in the unit tests), and each mode's short match
runs in the smoke test. Levels 3 and 4 run on demand. A map's spec test adds the perf run on Low, Medium and High and
its balance run plays each lighting and round mode in its own process, in parallel.

## The command

(Command: rewritten with the Godot content toolkit.) What the browser game's command did, which the new one keeps:

- **One item** by pool ID, name or Key (`000007`, `"Red Dot"`, `redDot`) runs levels 1 to 3; **all** runs levels 1 to 3
  on every asset, without pictures.
- **Balance** adds level 4. **Public** is the public gate: all four levels at full length.
- **A map** by its id or name (`depot`, `"Woodland"`), or every map (levels 1 to 3, without perf runs or pictures).
  Its perf runs can be skipped, and name their environment (a cloud container, or the owner's PC).
- **A mode** by its id or name (`attackDefend`, `"Attack and Defend"`): its rules and fit, its short matches on every
  map that hosts it, a full match on its first public map, the perf run on each host on the budget preset, and with
  balance the map balance run in that mode on each host. Every mode: levels 1 and 2, its short matches on one public
  map each.
- **A skin** by its id or name (`cobalt`, `Signal`): its rules and fit, its team colours and texture, pictures on each
  replica, and each map's colours measured in the game (about a minute a map). Every skin: levels 1 to 3 without the
  maps.
- A replica's or part's balance run can be limited to some maps (`depot,woodland`); each map runs in its own process,
  in parallel. Pictures can be skipped.

It writes a report per item (`report.md`, a one-file `report.html` with the pictures inside it, `report.json` and
`pictures/`), and fails when a check fails or a runner could not run. The thread copies the report to
`/mnt/project-files/content-reports/<id>/` and attaches the HTML page.

## Balance

- **The target.** A new replica's or part's team wins 40 to 60 % of decided rounds against what is there
  (owner, 2026-10-05). A replica plays each ordinary public replica of its class; a part plays its replica with and
  without it. Its team should also land at least half as many hits as the other.
- **Public counts.** Figures on public maps, modes and levels are judged. Dev ones are shown as information
  (owner, 2026-10-05).
- **Noise.** A figure outside its band but within noise asks for a look: re-run on more seeds (16) before acting.
- **Overrides.** A failed balance check can be overridden by the owner with a reason. The reason goes into
  `docs/DECISIONS.md` and the item into `ALLOWED_STRONGER` (the content rules, `game/config/`): its figures are then
  shown and never judged (the Cyber Pistol, the level 10 reward, is the first).
- **A map's balance** is each end's share instead: the end that starts west (the attackers in Attack / Defend) wins 40
  to 60 % at Pro and 35 to 65 % below it (Audit 2 decision 3), with bots leaving spawn and nobody stuck or falling.
- **Extraction** plays whole runs, not rounds. A replica or part: the squad carries it, then the rival kit, over the
  same seeds, and of the runs only one of the two got out of, its share holds the 40 to 60 % band. A map or mode: the
  runs the squad gets out of and what it gets out with, against the map's bands (the Extraction bands, `game/ai/`).
- **A mode's balance** adds two figures to a map's: the objective decides at least 1 decided round in 10, and its pay
  a minute is within × 0.75 to × 1.25 of Elimination's on the same map, lighting and level.

## Going public

1. The owner has played it and says "make it public".
2. Run the public gate (command: rewritten with the Godot content toolkit). Every fail is fixed or overridden (above);
   every warning is put to the owner and he accepts it.
3. Change its Access to `public` in `data/pool.md` (or its tag in the map or mode registry) and add it to
   `PUBLIC_ITEMS` in the content rules (`game/config/`) with the date and the owner's word (`PUBLIC_MAPS` for a map;
   for a mode `PUBLIC_MODES`, and its id to `SHIPPED_MODE_IDS`). A `public` item missing from that register fails the
   rules check, so nothing skips the gate.

## Where the rules live

- **Rulebooks and briefs:** `docs/content/`.
- **The numbers the checks use** (normal ranges, budgets, the balance band, the registers of exceptions): the content
  rules in `game/config/`. Changing a range or a band is an owner decision.
- **The checks, the command and the report:** rewritten with the Godot content toolkit; the browser game's are in
  `legacy/browser/src/content/` and `legacy/browser/pipeline/`.
