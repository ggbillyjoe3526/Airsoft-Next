# Playtest guide

How to run the game and what to check when you play it. Each pull request names the sections to play; a bug pass
plays them all. A change that alters what a section describes updates that section. Tick a box when the game behaves
as described; anything else is worth reporting ([Reporting what you find](#reporting-what-you-find)).

**Nothing is playable until 0.1 Dev 1.** Each section applies once its feature lands; `docs/FEATURES.md` lists what
has. The checks are carried from the browser game, whose guide (with the reasons and exact figures) stays readable in
`legacy/browser/docs/` until 0.1.

## Get the game running

You need a Windows or Linux desktop computer with a graphics card that runs Vulkan or Direct3D 12.

- **A release (the usual way).** Open the GitHub release named in the README (github.com/ggbillyjoe3526/Airsoft-Next
  › Releases) and download one of:
  - **Windows installer** (`.exe`): run it and start Airsoft from the Start menu. Uninstall it from Windows Settings ›
    Apps; your save stays.
  - **Windows zip:** unzip it anywhere and run the `.exe` inside. Nothing is installed.
  - **Linux tarball** (`.tar.gz`): unpack it and run the game file inside (mark it executable if asked).
- **The latest work, or a pull request.** Install **Godot 4.7.2 stable, the standard build** (not .NET) from
  godotengine.org. Download the repository (github.com, **Code** › **Download ZIP**, or pick a pull request's branch
  first), unzip it, open Godot, **Import** the folder's `project.godot` and press **F5**. The first import takes a
  minute or two.

| If this happens | Try this |
|---|---|
| Windows says it protected your PC | **More info** › **Run anyway**: the builds aren't signed yet. |
| The game won't start, or names a graphics problem | Update your graphics driver. |
| Godot asks to upgrade or convert the project | Close it: that is the wrong Godot version. Use 4.7.2 stable. |
| The mouse isn't captured | Click in the window. |

While you play, **F3** shows the frame rate and the match's **seed**. Note the seed when something goes wrong: it
replays the same match.

## Play these first

What to play in the build in your hands: your checklist of open checks is
`/mnt/project-files/playtest/0.1-dev1-checklist.md` in the project's shared files, and each pull request names its
sections here. For 0.1 Dev 1, the core slice: [Movement](#movement), [Shooting and reloads](#shooting-and-reloads),
[BBs](#bbs), [Players and replicas](#players-and-replicas), [Rounds and matches](#rounds-and-matches),
[Depot](#depot), [Bots](#bots) and [Builds and the desktop](#builds-and-the-desktop).

### Only you can do these

- **Performance baselines.** Once the Godot performance run exists, run it on the low-spec laptop and on the desktop
  at Ultra, and send the thread its results: the budgets are set from them.
- **Playing Woodland**, dev content until you make it public.

## Movement

Play › Mode Elimination on Depot, Match › Opponents Normal. Set the mouse sensitivity in Settings › Controls first.

- [ ] **Look and move (mouse, W A S D).** The view turns smoothly with no jumps or drift; you run at a steady pace and
  hear your footsteps.
- [ ] **Hold Shift and move.** You walk slowly and silently, and the crosshair closes to about its standing-still
  size. Is the gain clear enough?
- [ ] **Press 3, then run.** Holstered, you run faster than with the replica out (5.4 m/s against 4.2); with Left Alt
  the sprint is the same as armed, never faster. Fast enough now?
- [ ] **Hold Left Alt and fire while sprinting.** It fires, but the spread is far wider and the rifle climbs faster;
  let go of the trigger and it drops back into the carry.
- [ ] **Press C.** You crouch, slow and silent, and C again stands you up; Left Alt or Space also stands you up. With
  Settings › Controls › Crouch key on Hold, you crouch only while C is held.
- [ ] **Hold Q, then E, beside a wall or crate.** You lean round it; against a wall the lean stops short, so you never
  see through it.
- [ ] **Press Space.** A small hop. Pressed just before landing, or while standing from a crouch, it jumps once,
  never twice. Does it feel right or too forgiving?
- [ ] **Watch the crosshair.** It opens when you run or jump, closes almost at once when you stop, and is tightest
  crouched and still; crouch-walking sits between standing still and walking.
- [ ] **Sprint up and down Depot's dock ramps.** Uphill loses about a quarter of a sprint's pace (a confirmed call).
- [ ] **Controls through a vault (BP5).** Vault a low wall (Depot's office hall has one). On Semi, hold left click
  through it: one BB, not two. Hold right click: the sight drops and comes back.

## Shooting and reloads

The rifle holds 60 BBs and the pistol 18, each with 4 magazines a round. Nothing refills until the next round.

- [ ] **Hold left click with the rifle.** A steady stream; the BB count drops and the box by the name says **Auto**.
- [ ] **Press B.** **Semi** (one BB a click), then **Burst** (three), then **Auto**; the setting carries into the next
  round.
- [ ] **Press 2 or turn the wheel.** The pistol: one shot per click, and a click straight after sprinting fires at
  once. 1 switches back.
- [ ] **Shoot at a far wall.** BBs fly, take a moment to arrive and drop at long range; the pistol's drop sooner.
- [ ] **Fire half a magazine, then press R.** A magazine swap plays (rifle 1.8 s, pistol 1.2 s); the gauges show your
  spares and the half-used one goes back in the pouch.
- [ ] **Empty a magazine, then pull the trigger.** The empty pull starts a reload by itself. With a full magazine in,
  R does nothing and says why (no topping up).
- [ ] **Use up every magazine.** You can't fire again that round; the next round starts you full.
- [ ] **Empty the GBB Pistol.** On the last BB its slide locks back and stays back; through the reload the magazine
  goes in first and the slide closes near the end. The gauges under the count show every magazine: the loaded one
  first, spares fullest first, an empty one dark.

## Aiming and optics

The rifle comes with flip-up iron sights; a red dot or a 2× scope is a part you fit in Loadout › Customise.

- [ ] **Hold right click with iron sights.** The rifle comes up to your eye, the view narrows a touch and the
  crosshair goes: the front post sits in the rear ring.
- [ ] **Fit the red dot and aim.** It sits on the rifle with the iron sights folded under it; the crosshair gives way
  to the dot and you move at a quiet walk (no sprint while aiming). Let go and it all goes back.
- [ ] **Shoot while aiming.** BBs go where the dot (or post) is. Aiming halves the spread: at 25 to 35 m it should be
  clearly tighter, and the hip up close should still feel fine.
- [ ] **Hold Shift while aiming.** You creep slower than the aiming walk (1.4 m/s against 2.3). Steady, not stuck?
- [ ] **Move the mouse while aiming.** It turns at Settings › Controls › Aiming sensitivity (×0.80 at first).
- [ ] **Reload or switch to the pistol while aiming.** The sight drops and comes back if you still hold right click.
- [ ] **Fit the 2× scope and aim.** It comes up a little slower than the red dot; the rifle stays in view with the
  world twice as close through its glass, a fine crosshair and a red centre dot.
- [ ] **Press Esc in a match.** The pause menu has no Loadout: parts are set between matches (the range's has one).

## BBs

### Out of the muzzle

- [ ] **Fire from the hip: single shots, a burst, a spray.** Each BB and its short streak start at the barrel's tip
  and fly out towards the crosshair, also straight after sprinting; the rifle kicks back and up a little rather than
  tipping.
- [ ] **Do the same aiming, and with the pistol.** BBs leave the muzzle under the sight and rise into the dot or
  crosshair.

### Hop-up, flight and wind

Hop-up puts backspin on the BB, which lifts it so it flies flat for longer; each replica has a dial in Loadout ›
Customise. BBs fly by real air physics, and each match has a light breeze (calm to about 2 m/s) that pushes BBs,
never players.

- [ ] **Factory hop (rifle 65 %, pistol 55 %), at a target 30 m or more away.** Rifle BBs rise about a hand's width
  near 20 m and stay on target to about 39 m, taking about half a second; the pistol's drop from about 27 m.
- [ ] **Hop-up at 0 %, then 90 to 100 %.** At 0 BBs drop from about 14 m; at 90 to 100 they climb about half a metre
  over your aim and float before they fall.
- [ ] **Watch the dust (Medium or up).** It drifts one way, the wind, which changes from match to match.
- [ ] **Practice range, every target to 60 m.** Each can be hit: from 40 m aim high (or turn the hop up) and a little
  upwind; a level shot at the 60 m plate lands short.

### Walls and ricochets

- [ ] **BBs stop on everything.** Shoot crates, container sides, wall tops and corners, the dock and its steel ramps,
  a gabion, the toilets: every BB stops or bounces at the surface, never inside or through it (Settings › Dev › BB
  paths).
- [ ] **Fire at concrete or a container at an angle.** BBs glance off and fly on, slower; into a crate they stop.
- [ ] **Ricochets count Off (the default).** A bounced BB that hits you shows "Ricochet · doesn't count, play on"; one
  of yours that reaches a bot shows a grey puff and "Your BB ricocheted · doesn't count".
- [ ] **Ricochets count On** (Play › Match). The same shot knocks you out: the hit feed says RICOCHET (not FRIENDLY).
  Is the notice useful, or does it come up too often in a 3v3?

## Players and replicas

- [ ] **Players.** Teammates and opponents are masked humans (never a bare face) in team camo with a plate carrier in
  the team colour, or robots in a light or dark shell by team.
- [ ] **Team camo** (Medium and up). Clear dark and light blotches in the team's colour, crisp up close and blending
  far off without shimmering; Low keeps plain clothes.
- [ ] **Your hands.** Dark gloves, sleeves in your team's camo (Hand detail High) and the team armband on the left
  forearm. Inspect (Y) the rifle and each pistol: the firing hand's wrist sits low behind the grip, bent a little up
  from a forearm running back about level, the thumb where it was.
- [ ] **Look straight down.** Standing, crouched and in a vault: you see the ground, never your own body (Beta 1
  item 24).
- [ ] **Hit call.** Hit a bot: the HIT! sign, the hand up, the replica hanging; readable at 20 to 30 m.
- [ ] **Replicas.** The rifle and pistol look like toys: blocky, two-tone, stippled grips; others' replicas are in
  their team's colours.
- [ ] **Replica detail on High.** Fine speckle, rounded lit edges, rail slots and sights. In Loadout try every optic,
  grip and magazine: nothing floats or clips the hands.
- [ ] **Gas puffs and impacts.** The pistol puffs a little gas each shot; the rifle none. No flash, no casings.
  Impacts make pale dust on concrete, tan crumbs on wood, a grey puff on steel: never sparks.
- [ ] **Name tags.** A teammate's tag sits just above the head at 1 to 2 m and at 30 m. Try a field of view of 80.

## Loadout and Customise

Loadout (the title screen or the top bar). The slots are Primary, Secondary and Grenades (greyed: none yet); a replica
still to unlock is greyed with a lock and its level. Right-click an equipped replica, or use Customise, to change its
parts. To try every part before you have levelled, turn on Settings › Dev › Disable levelling.

- [ ] **Swap slots.** The GBB Pistol in Primary moves the AEG rifle to Secondary. Any replica goes in either slot.
- [ ] **Saved loadouts.** One dropdown picks a saved loadout, with Rename, Duplicate, New and Delete beside it.
- [ ] **Customise.** Colour, optic, BB weight, hop-up, grip, laser, magazine, power source, barrel, muzzle and light,
  each offering the parts that fit. Back (or Esc) returns to the Loadout, named in a plain-text breadcrumb.
- [ ] **Locked parts.** At a low level the options still to unlock follow the ones you have, greyed with a lock and
  "Level N", and can't be picked; "Level up to unlock more" goes once a row is fully unlocked.
- [ ] **BB weight.** 0.25 g on the rifle and 0.20 g on the pistol as they come. 0.28 g on the rifle needs more hop (at
  about 75 % it stays on target to about 41 m); 0.20 g at 65 % hop floats, about 50 % flies flat.
- [ ] **Grips.** Vertical: after a sprint the crosshair closes sooner; switching is a touch slower. Angled: switching
  and raising the sight are quicker; after a sprint the crosshair stays wide a moment longer.
- [ ] **Magazines.** Hi-cap: 120 BBs and one spare; a bot facing away hears its rattle within about 7 m. Low-cap: 30
  BBs, five spares, quicker change and draw. The pistol's extended magazine: 27 BBs, slower to draw.
- [ ] **Barrels and the silencer.** Tight-Bore: spread −15 %. Long Barrel: energy +10 %, spread −10 %, slower to draw
  and raise. Silencer: energy −5 %, a slower draw, shots heard from 22 m become 11 m, duller and quieter; a bot facing
  away 15 m off doesn't turn at a silenced shot.
- [ ] **Performance panel.** Energy, muzzle speed, BB weight, rate of fire, on-target range, time to 20 m, spread,
  recoil, magazines, reload, draw, aim raise, shots heard from.
- [ ] **The 11.1 V LiPo battery** on the rifle: rate of fire +15 %, energy unchanged; it empties faster.
- [ ] **Glowing BBs** (per replica): At Night (the default), Always or Off. A glowing BB is green, a little larger at
  range, with a longer streak.
- [ ] **Light** (dev content, night fields). Every replica has the Weapon Torch from level 0, switched with **T**.
- [ ] **Your setup is kept.** Quit and start the game again: every pick is still
  there. Teammates carry replicas as they come;
  opponents carry kits of their own ([Bots](#bots)).
- [ ] **Edit `data/stats.md`.** Set the AEG's `Fire rate (BBs/s)` to 20 and start the game again: the panel says 20
  and every rifle fires faster. A typo keeps the built-in value with a warning in Godot's output, and
  `tools/unit_tests.sh` names its line.

## Cyber Pistol

The level 10 reward. To try it now, turn on Settings › Dev › Disable levelling, or press Settings › Dev › Level up
until 10.

- [ ] **Equip it.** Below level 10 it is greyed with a lock and "Level 10"; once unlocked it goes in either slot.
- [ ] **Its look.** A white slab with glowing cyan lines and a magenta core, the same on either team; with Realistic
  colours plain grey and unlit. Does it read as rare and special?
- [ ] **Customise.** Power source reads Built-in battery, the magazine "Its own, 50 BBs"; optic, grip, laser, barrel
  and muzzle rows are greyed; BB weight and hop-up still turn.
- [ ] **On the range.** It starts on Semi and the selector steps Burst and Auto; even on Auto the sight barely climbs.
  It stays on target to about 33 m.
- [ ] **Its sound.** A quiet electronic chirp and a soft pop, no motor whine; an empty trigger blips; a reload ends in
  a two-note chime. Futuristic but still a toy?
- [ ] **The Armory and the summary.** Level 10's row holds it; reaching it the summary says "Level 10!" and "Unlocked:
  Cyber Pistol".
- [ ] **Bots with it.** With it unlocked (or Disable levelling on), about 1 Hard match in 20 has an opponent with it.
  Never on Easy or Normal, never a teammate.

## Levels and the Armory

Finished matches give XP, each level up to 10 unlocks parts for good, and nothing is ever sold. What each level
unlocks is in `data/levels.md`; the Armory shows it in the game.

- [ ] **Level 0 to start.** On a fresh save (Settings › Save file › Delete) the top bar reads "LVL 0"
  with an empty bar.
- [ ] **The level badge.** "LVL N" with a thin XP bar at the far right of the top bar on every screen after the title;
  point at it for "X XP to level N+1", click it to open the Armory (from the pause menu it does nothing).
- [ ] **The Armory.** Your level "of 10", the XP bar and how XP is earned (a match 100, a win 100 more, each round won
  20, each hit 10, times the difficulty), what the next level unlocks, and every level with its items (reached ones
  Unlocked, the next Next). Easy to read?
- [ ] **XP on the summary.** Win a standard first-to-5 match on Normal: "XP earned +N XP", what gave it, then "Level
  N: X / Y XP" over a bar. A loss gives less.
- [ ] **A level up.** Your first finished standard match takes you to level 1: the summary says "Level 1!" and
  "Unlocked: Red Dot", and the Red Dot is in Customise with no lock.
- [ ] **No XP.** The range and the tutorial give none; a match with a dev map or mode, or a Dev aid on, says why it
  gave none.
- [ ] **Settings › Dev › Disable levelling.** The badge goes, the Armory says levelling is off, and the Loadout and
  Customise offer everything unlocked. A match gives no XP and stays out of your records.
- [ ] **Dev XP buttons.** **+500 XP** adds 500 (a level it reaches unlocks its items); **Level up** adds exactly what
  the next level takes (at 10: "At the top level"); **Reset level** asks first, then returns you to level 0.
- [ ] **At the cap.** At level 10 the Armory and the summary say "Top level reached. XP counts again when the level
  cap goes up." and the bar is full.
- [ ] **Edit `data/levels.md`.** Swap the Red Dot (level 1) and the Silencer (level 4) and start the game again: at
  level 1 the Armory lists the Silencer.

## Rounds and matches

One BB hit puts anyone out. A round lasts up to 2:30 and the first team to 5 round wins takes the match.

- [ ] **Get hit.** A sharp tick, a sign of where it came from, and your view walks off. Then you watch a teammate; a
  click moves to the next one.
- [ ] **Skip to next round** (M83). Out and spectating, Esc skips at once with no pause menu, then "Click to play · Esc
  for the menu" holds the next round; the pause menu's **Skip to next round** still works. On match point it reads
  **Skip to the result**. Not offered in play, between rounds, in Extraction or on the range.
- [ ] **Shoot a teammate (carefully).** Friendly fire counts, so they go out too.
- [ ] **Walk-offs.** Hit players walk all the way to their dead zone by a sensible route, promptly, on every map; they
  stand on separate spots.
- [ ] **End a round.** A banner says who won, the score updates and the next round starts by itself. The first round
  after starting the game opens with the referee's two short whistle blasts.
- [ ] **Overtime flag (OT1).** In Elimination, hide until the clock runs out with both teams in (Round time 1:30 is
  quickest): three whistles, "Overtime · touch the flag", a chequered flag near the middle and a 0:30 clock. Touch it
  (within a metre) and your team wins, "Flag touched"; with both teams at it nobody wins; untouched, "draw" and the
  round replays. Bots head for it; does 30 s feel right? Attack / Defend has none.
- [ ] **Overtime banner (BP5).** It fits on one line at 1280 px wide; the feed (hits and callouts) hides while Tab is
  up.
- [ ] **Finish a match.** The Match summary ([HUD and match info](#hud-and-match-info)), then the result screen. Go
  straight to Stats: the match is counted and its XP given at once.
- [ ] **Play again** shows a new seed in the F3 box; that seed, given as `--seed=<n>`, replays the match's
  start. Quitting and
  playing the same map a few times starts almost at once and looks like the first Play.

## Maps

### Depot

An asymmetric warehouse yard. Attackers start in the west yard, defenders in the north-east corner, and the one
flagpole stands in the walled loading bay. Three lanes lead there: **Dock Road** (north, along a raised loading dock),
**Container Alley** (the middle, through the Main Gate) and the **Office** (south, close quarters).

- [ ] **Walk all three lanes from the west yard to the pole.** None has a dead end and you can tell which you're in.
- [ ] **The dock.** Its ramps have no bumps; you can step off its open edge (a 1.2 m drop) but walking up to it
  doesn't push you off.
- [ ] **Jump against crates, the ramp kerbs and the dock edge.** You never land on top or hang on an edge. You can't
  see the other team's spawn from yours, standing or crouched.
- [ ] **Cover.** A pallet rack, a gabion barrier and a portable toilet are full cover; crouched behind an IBC tank, a
  generator or sandbags you're hidden, standing you can shoot over.
- [ ] **The east end** (Alpha's start in Elimination): the team leaves past the wall's south end and nobody gets stuck
  in the yard's north corner.
- [ ] **Balance.** In Attack / Defend, does attacking or defending feel easier, and which lane do the bots pick? In
  Elimination, does either end feel stronger over a half?
- [ ] **The look by day.** A low warm sun with long shadows, a blue sky, light bouncing into the shade; precast
  concrete, gabions, rust and rain streaks, ground stains (Medium and up).
- [ ] **Set dressing (Medium and up).** Dirt, junk and litter against walls, glossy puddles, logos and warning signs:
  nothing new to hide behind and no new long sightline.
- [ ] **Dust and signs.** Sprinting and landing kick up a little dust. Bay numbers, hazard chevrons and SAFE ZONE by
  each dead zone read properly, never mirrored or half inside a prop.

### Woodland (dev content)

A wide wood at night: 120 × 80 m on a gentle slope up to the Knoll and its log fort, with three lanes (Pine Belt,
Meadow, Creek with the cabin). 5v5 by default, or 6v6. Turn on Settings › Dev › Dev content, then pick it on Play.

- [ ] **Hidden starts (M88).** From either camp, and for the first steps out of it, you can't see the other team (the
  West Rise hides the west camp, the Knoll the east). Play both halves.
- [ ] **The night.** A dark sky under a low moon, flickering camp fires, glowing lanterns; on Medium and up the
  nearest ones light players too.
- [ ] **Bushes** hide you from bots when you're deep in or behind one; you walk through them; the minimap draws them.
- [ ] **Bushes stop BBs (FO1).** A BB into a bush's middle never comes out, with a leafy rustle and falling leaves;
  through the edge it comes out off its line and slower. Fire from deep inside: "Leaves in the way · step clear to
  shoot". A Normal bot holds fire until it has a clearer line; an Easy one fires into the leaves.
- [ ] **Night sight.** Bots see about 40 m into a light pool, 25 m in the open and 10 m under the trees; fires and
  lanterns give you away.
- [ ] **The look and sound.** Bark trunks, log walls and log piles, plank fences, a gravel ravine bed; wind in the
  pines, insects, a distant owl, a crackle at each fire, and footsteps that sound like the ground, as loud as on
  concrete.
- [ ] **The meadow and the fort (WL2).** No lone oak in the middle and no boulders anywhere: the meadow has fallen
  trunks and the three climbs to the fort have log piles you can stand behind. The fort's outer walls are chest high
  (1.5 m): stand to shoot over, crouch to hide. The hut is taller, under a grey tin roof like the cabin's, and the flag
  still shows over the walls from the meadow.
- [ ] **West Hill and the ravine (WL3).** From the Knoll by the east camp you can't see over West Hill into the west
  camp. The meadow has one low swell. The creek lane runs along a dry ravine, deeper from the middle of the field east;
  every slope walks, none needs a jump.

### Neon Heights (the Maps Update)

A small three-floor market city with stairs, a Sky Bridge and a balcony, 4v4 to 5v5, Day or Night. It comes back with
the Maps Update, in a new look with doors and interiors (`docs/ROADMAP.md`); these checks carry over.

- [ ] **By Night.** The avenue, the atrium and the shopfronts sit in lamp light; stairwells and Level 1 rooms are
  dark. In a dark room a bot spots you only close up (about 15 m), in lamp light from far off. Fair next to the
  moonlit street (25 m)?
- [ ] **Balance.** Play Elimination by Day and by Night: are the two ends even?
- [ ] **The stairs.** Walk up an outdoor stair without jumping: you reach the landing without stopping. Sprint down
  it: no drop.

## Bots

You're on Alpha (blue) with two bot teammates against three Beta (orange) bots by default; Your team puts you on Beta.

- [ ] **Hit a Beta bot.** It raises its hand, walks off to the dead zone, and you get a clear sign of the hit.
- [ ] **Watch the bots for a few rounds** (spectate once you're out). They patrol, take cover, crouch behind crates
  and lean round corners; note any bot stuck or walking into a wall.
- [ ] **Run near a bot, then walk past one with Shift.** Running gets you heard; walking lets you sneak closer. Behind a
  wall they notice you later: do they hear through walls like a wallhack, or too little?
- [ ] **Shoot near a bot from past 22 m, unseen.** It ducks and comes looking or takes cover; a search that finds
  nobody ends with a crouched look round.
- [ ] **Noisy props (NP1).** Run (not walk) into a skip, container, crate stack or rack: a boom or rattle where you
  hit it, and an idle bot 15 m off turns to look. Walking or crouching into it is silent. A BB off steel near an idle
  bot draws its look; sprinting over gravel or a steel ramp is louder. Does a knock feel fair?
- [ ] **Fight a bot beside a wall or container.** It sidesteps away from the wall and keeps you in sight; on the
  dock's edge it never steps off. Bots by door frames don't fire into the frame.
- [ ] **Every level hunts (M87).** Once their lane is swept, bots hunt the map's middle without walking into corners
  they already saw empty; a round shouldn't drag to the clock.
- [ ] **Up close, a fair moment.** Walk into a Normal bot at 5 to 10 m: its first BBs go wide and walk in (its first
  hit takes about 1.5 s).
- [ ] **The bots' kits (BG1).** Opponents carry kits from `bot-kits.md`: Easy mostly plain, each level up more scoped,
  silenced or red-dot, Pro never plain. Spectate a few: the optic shows on their rifle and a silenced bot is heard
  nearer. Does gear make Normal unfair or Hard too easy?
- [ ] **Bot names and personalities (BN1).** Every bot has a name and plays the same way every match: a **Rusher** is
  first through the gap, an **Anchor** holds one spot aiming over cover, a **Flanker** takes a lane of its own, a
  **Careful** bot clears each corner. Can you tell them apart?
- [ ] **At night** (Woodland, Neon Heights by Night): Normal, Hard and Pro bots hold posts out of lantern light.
- [ ] **Anchors (BP5).** In Elimination with over a minute left, give an anchor teammate Follow me (F), then end it
  with F again: it goes hunting.

## Modes

### Attack / Defend

- [ ] **Raise the flag.** Stand in the painted ring at the pole for 5 seconds; the strip under the score shows how far
  up it is and a marker shows the pole. Sides swap after round 4.

### Custom matches and rules

Play › Match. The Rules row comes first: Skirmish (the standard match) or Custom, which
opens every row (the Modes Update adds the other rule sets).

- [ ] **The rows.** Rounds to win (3 to 10), Round time (1:30 to 5:00), Team size (1v1 to 3v3; larger on Neon Heights
  and Woodland with Dev content), Opponents, Teammates, Friendly fire and Ricochets count.
- [ ] **A 1v1, a 2v2, first to 3.** The scoreboard and pips match the sizes; first to 3 swaps ends after round 2 and
  ends at 3. Do rounds feel too long or quick at that size?
- [ ] **Opponents Easy, Teammates Hard.** Your teammates win clearly more often. The rules text says this match won't
  go into your records.
- [ ] **Friendly fire off.** A BB at a teammate passes by. **Custom** gives XP at most ×1.5 and never counts for
  records.

### Practice range

The Match screen's Practice card, then Start practice.

- [ ] **The range.** Alone behind a painted line facing three lanes: steel plates, standing figures, crouched ones, 10
  m to 60 m marked. No whistle, clock or score.
- [ ] **Reload and Esc › Loadout.** The spare gauges never run down. Change the BB weight or hop-up, go back and
  Resume: you're where you stood with the new setup. Walk downrange: nothing stops you.
- [ ] **Dev help isn't a best (BP5).** Switch Timed challenge on, then set Game speed or Bottomless magazines before
  the START plate: the result says "not kept (Dev settings)".

### Tutorial

- [ ] **The title screen** offers Tutorial under START on a clean save until you finish it or start a first match.
- [ ] **Play it through.** The coach says "Tutorial · 1 of 16 · Look around" and moves on as you do each thing (look,
  walk, ring a plate, knock down a figure at 50 m, reload, selector, aim, crouch, lean, sprint-fire, vault, switch
  replica, then four cards to read); finished steps tick green. Does any step feel stuck or unclear?
- [ ] **Lean (TT2).** After Crouch, the Lean card names Q and E (your bindings); it ticks only once you have peeked
  both ways, in either order.
- [ ] **Short and quick (TT1, TT2).** Every card is a sentence or two; the four read cards fill a thin bar and move on
  after 10 s.
- [ ] **Esc mid-tutorial.** The pause menu names your step and offers Skip step and Skip tutorial; quitting at step 5
  and starting again resumes there. Rebinding reload changes the coach's key.

### Extraction (the Modes Update)

Your squad against a home team on a timed run, rebuilt with its rework for the Modes Update (`docs/ROADMAP.md` ›
0.3 · Modes Update). The browser game's checks for it are in `legacy/browser/docs/`.

## Pro difficulty (dev content)

Turn on Dev content, then Play › Match › Opponents › Pro; play each map once in Elimination and once in Attack /
Defend. Pro pays XP ×2 but counts for nothing while it is dev content.

- [ ] **Slow down.** Pro bots hold still aiming at corners and doorways and walk quietly towards where they heard you.
  Run past a corner and you lose; slice it a step at a time and you win.
- [ ] **What got you.** After you're hit a card shows, for example, "Beta 2 · from your left · 14 m", whether that bot
  held the angle and whether you moved.
- [ ] **Teammates on Pro** hold angles, trade your hits and win their duels. Is any approach unfair on a map, or does
  one end win far more?

## Menus

- [ ] **The title screen.** Only "AIRSOFT", the tagline "Call your hit. Go again." and **START**; on a clean save a
  **Tutorial** button under START. The build sits small at the bottom right with **Licences** over it, a
  **Fullscreen** button at the bottom left. Licences shows Godot's licence and every add-on's.
- [ ] **The top bar** on every screen after the title: MATCH, LOADOUT, ARMORY, SETTINGS, your level and XP bar on the
  right, the current place marked.
- [ ] **The Match screen** (START). 01 Map as picture cards (a Day | Night switch where a map has both), 02 Mode as
  cards with **Practice last**, 03 Match rules; on the right Your match with the Loadout's Change and **Start match**
  (**Start practice** for the range).
- [ ] **Your team** (M98). Alpha or Beta, each with its colour dot, kept after you leave; Extraction hides the row. On
  Beta you start at Beta's end with the orange armband and an orange HUD (YOU tag, markers, minimap, wheel); bot
  opponents are "Alpha 1…3"; ends swap at half-time. Play each mode and map once on Beta.
- [ ] **Pause (Esc).** Everything freezes, the mouse is freed, and a solid screen shows the round and score with
  Resume, Settings and Quit ("Round 2 · Alpha (you) 1 – 0 Beta · first to 5"; Attack / Defend says "you attack" or
  "you defend").
- [ ] **The result screen.** MATCH OVER, YOU WIN! (or YOU LOSE), the score, and Play again, New game, Summary and Quit.
- [ ] **The look.** All text is Inter (numbers keep their width), headings in capitals, tidy at 1280×720 and
  1920×1080; a button lifts when pointed at; Tab shows an orange focus ring; with reduced motion no fades.
- [ ] **Window sizes (UX1).** At 4K with 100 % Windows scaling the menus are about 1.5× their 1080p size, and the
  saved loadouts' menu opens at the pointer. At 1280×720 the top bar, heading and main button always show; the long
  list scrolls, fading at its foot (Settings › Gameplay and Controls scroll a long way, even at 4K: tell me if that
  grates). At 900×600 Start match is in sight.
- [ ] **The loading screen** on the first start after installing: it shows progress, never a frozen window.

## HUD and match info

- [ ] **Hop-up mid-match.** 4 turns the hop-up down and 5 up (Page Down / Up too). The readout over the ammo panel
  shows the dial, a tick at the best setting for your BBs and how far they stay flat ("Flat to 39 m").
- [ ] **Round end stamp.** WON, LOST or DRAW stamps at the end of a round and stays 2 s, then the round's table holds
  about 4 s before the next round (RE1); a click after half a second moves on. Long enough to read, never a wait?
  A click held through the skip fires nothing until you let go; at 720 px the word sits clear of a two-line banner.
- [ ] **Feed position** (Settings › HUD). Bottom left moves the feed there; top right is the default.
- [ ] **Hit feed.** Hits and callouts share one feed, top right, newest on top: "Beta 2 called HIT · Alpha 3" with names
  in team colours; lines about you say "You"; friendly fire says FRIENDLY and a ricochet RICOCHET.
- [ ] **Teammate markers.** A name tag and arrow in your team's colour over each teammate, also through walls; grey
  and "hit" once hit; enemies never. Holding Tab hides them; tags stack, never on top of each other (BP5). Helpful, or
  too much?
- [ ] **Hold Tab.** The scoreboard: hits, times hit, friendly hits, BBs fired, accuracy and time alive, your team
  first, your line highlighted, players hit this round greyed.
- [ ] **The Match summary.** The result, everyone's numbers and Your records (wins and losses per difficulty and mode,
  best accuracy and wins in a row, NEW RECORD on a best you beat).
- [ ] **What got you** (Settings › Gameplay): Auto shows the card against Pro only, On on every level, Off hides it.
- [ ] **Crosshair** (Settings › Gameplay › Crosshair). Previews, Shape, Size, Thickness, Gap, Colour (no blue or
  orange), Opacity, Spread and Outline; in a match it looks the same and opens as you move.
- [ ] **Hit marker** (M97). Off by default: the hit tick sounds but no X. On: a bold red X
  pops over the crosshair and fades; scale, thickness, outline and colour change it at once. Is the default easy to
  see on every map?
- [ ] **Replay tutorial** (Settings › Gameplay, M97). Starts the tutorial at its first step, even after you finished
  it; from a match's pause menu it asks first, then leaves the match (not recorded).
- [ ] **HUD size and opacity** (Settings › Gameplay › HUD). 150 % scales the replica panel, score bar, minimap, feed,
  banners, wheel and markers with nothing overlapping at 1280×720 (the minimap grows a little less there, so an
  Attack / Defend score bar stays clear of it, UX1); the crosshair keeps its size.
- [ ] **The layout.** A score bar top middle (team blocks, the clock, "First to N"); the replica panel bottom right
  (UI2: S / B / A chips over a small box per spare magazine, the count and "/ N" at the right; no picture, no name, no
  reload hint); no squad cards or key hints; "ROUND 1" shows large; corners keep their margin at 1920×1080 and on 21:9.
  Is the panel compact enough, and are the magazine boxes easy to read at a glance?
- [ ] **Ammo counter** (Settings › Gameplay › HUD, AC1). On by default. Off: no BB count and no "/ N · M spare" line;
  each magazine box stays full until empty, then hollow.

## Squad orders and minimap

- [ ] **Follow me (F).** A radio double-click answers. Teammates keep up a few metres behind, sprinting to catch up;
  stop and one looks back, the other to a side; walk or crouch and they do too.
- [ ] **Hold here (X).** Look at a spot and press X: both go there, watch the way you looked and stay when you walk
  off; a diamond marker shows the distance. X at the sky: each holds where it stands.
- [ ] **Regroup (V).** They sprint back to you, then follow. Get hit: the order ends and order keys say "Orders wait
  for the next round".
- [ ] **The order wheel (hold Z).** Five items round the crosshair (Need a Mag upper left), each with its key. The
  view stays still while a pointer lights the order it's on; let go on one to give it, or without moving to give none.
  Walking continues; firing needs a new pull after. Orders > Click points and clicks instead.
- [ ] **Pings (middle mouse).** Ping the floor or a wall: a team-coloured ring with "Ping · 24 m", on the minimap too,
  fading after about 8 s. A teammate answers once and one goes to look, each its own way; ping the sky: nothing. A
  visible opponent gets an orange "Contact" diamond (one hidden in a bush or the dark isn't marked). Settings › HUD ›
  Ping markers Off hides the markers only.
- [ ] **Ask for a mag (H).** With less than one full magazine in your pouch the line under the crosshair says "Low on
  BBs · H to ask for a mag". H: the nearest teammate says "Mag coming!", comes and tosses a magazine you see arc into
  your hands ("+1 mag from Dash · 60 BBs"). With a full spare, or nobody near, it says why not.
- [ ] **A teammate asks you.** Settings › Dev › Bots run low on BBs: 8 s into each round a bot of each team is on its
  last magazine and calls "Need a mag!". When that is you, the line says "Dash needs a mag · 12 m", then "H · Toss
  Dash a mag" in reach; H tosses it and they say thanks. A pistol only gets a pistol's magazine.
- [ ] **The minimap.** Top left, the way you look always up, you the white arrow; teammates are team-coloured dots
  (pinned to the edge when off it), grey once hit; an opponent you hear shows as a patch roughly where (dashed for
  steps, a dot for a shot) for a few seconds. Gameplay › HUD › Minimap Fixed keeps north up (M83). On Neon Heights it
  shows your floor.
- [ ] **Markers off the minimap (BP5).** A ping, the overtime flag, an Extraction exit or a hold marker off to your
  left sits under the minimap, never behind it.

## Settings and controls

Settings opens on Display, with groups down the left (Display, Graphics, Gameplay, Looks, Audio, Controls,
Accessibility, Save file) and a "Dev settings" box that shows the Dev group.

- [ ] **Search and notes.** Typing "shadow" shows only matching rows with "N settings found"; pointing at a row says
  what it does, and in Graphics what it costs.
- [ ] **Mouse.** Under the sensitivity, Turn distance (cm/360) with a cm box and a DPI box (800 at first), and the
  same sensitivity for CS2 and Valorant.
- [ ] **Aim button and Sprint key: Toggle.** One right click keeps the sight up; sprint or a switch to the pistol
  drops it.
- [ ] **Keys** (Settings › Controls › Keys). Each action has a main and a second key box. Binding a used key swaps the
  two ("R was Reload: Reload is now Space"); Backspace clears (Move forward keeps one); the wheel and side buttons
  bind; Reset All asks first. By keyboard only: Tab to a box, Enter, press a key.
- [ ] **Your keyboard layout** (AZERTY or QWERTZ). Move forward shows as Z (AZERTY) and the order
  wheel as W or Y; the tutorial and reload hint use the same letters.
- [ ] **Display.** Field of view starts at 90° (120° shows more at the sides, 80° less). Fullscreen (or F10) goes
  fullscreen and back with play carrying on ([Builds and the desktop](#builds-and-the-desktop)). No Tone mapping row
  here or in Graphics.
- [ ] **Dev group.** Debug info, BB paths, Game speed (25 % to 200 %), Bottomless magazines and Ghost (BBs pass
  through you) change play; with any on, the summary says Dev settings kept the match out of your records.
- [ ] **Settings › Dev › Tone mapping** (RV2). Neutral by default; AgX and ACES change the colours at once. Untick the
  Dev settings box and the colours go back to Neutral at once; a match played with AgX still counts.
- [ ] **Dev playtesting aids** (M90). **+500 XP**, **Level up** and **Reset level** change your level at once and
  survive a reload. **Time of day** plays the map under the other light; **Bots hold fire**.
- [ ] **Settings › Dev › Retro look** (M96, back on the Dev tab since ST1). Off by default; On gives chunky pixels and
  a small dithered palette at once, with Pixel size and Colours; the HUD and menus stay sharp.

## Sound

Headphones help: direction (in front, behind, above) comes through best on them. Every sound is made by the game.

- [ ] **The rifle.** Each shot is a gearbox cycle (a whirr, a plastic slap, a puff of air): a toy, never a gunshot. A
  burst starts with the motor winding up and coasts down after you let go.
- [ ] **The pistol.** A sharp pop of gas, a short hiss and the slide clacking: clearly another replica with your eyes
  shut. Empty, the rifle still whirrs and the pistol only clicks; the reloads sound different too.
- [ ] **Impacts and steps.** A ringing ping off steel, a hollow knock on wood, a dry tick off concrete; a clank on
  steel ramps, a scuff on concrete, louder with kit rattling when you sprint and land; crouching and leaning rustle
  softly.
- [ ] **Bots by ear.** Close your eyes: you can point at one, behind you too. Behind a container it sounds duller and
  quieter. A bot sprinting at you from about 20 m is heard most of the way, quieter than any shot.
- [ ] **The field.** A very quiet outdoor bed with no audible loop and a small bird now and then; each field has its
  own echo. Rare far-off extras (M86: a crow and a dog on Depot, a creaking branch on Woodland, pigeons on Neon
  Heights): does any make you turn round?
- [ ] **Getting hit.** The tick stands out and the world dips; while you walk off the field sounds muffled, the whistle
  stays clear. Pausing mid-burst and resuming makes no click.
- [ ] **Settings › Audio.** Master, Effects, Power source volume (each replica's motor, gas and spring, yours and the
  bots'), Ambience and Interface (hit tick, marker, whistle), each at once and kept.
- [ ] **Output devices.** F3 shows the audio latency (about 10 to 40 ms). Anything that sounds like a firearm, harsh, or
  too loud? Say which.

## Graphics and performance

Settings › Graphics › Quality: Low, Medium, High, Ultra or Custom.

- [ ] **First start.** With nothing saved (a fresh install) integrated graphics starts on Medium, a discrete card on
  High, never Ultra; the debug panel's quality line ends "(auto)".
- [ ] **The ladder.** Switching presets mid-match applies at once and the mouse stays captured after Resume. **Low:**
  80 % resolution, no shadows, plain surfaces, a soft disc under players.
- [ ] **Custom.** Changing a Medium row (Shadows Off) jumps the picker to Custom; back On returns to Medium. Render
  scale 60 % softens the picture, not the HUD.
- [ ] **Shadows on High.** Rails, posts and arms throw crisp shadows close by; edges stay still as you turn. About 25
  m ahead they stop: does the line bother you?
- [ ] **The sky and BB streaks.** A pale haze at the horizon, blue above, no sky through wall edges. BB streaks read as
  thin bright lines at 20 to 30 m on a high-DPI laptop and a monitor.
- [ ] **Debug panel (F3).** "frame ms (sim / draw / GPU)", the antialias line, draw calls.
  Note the frame rate and draw calls on each preset in the open yard and in the office.
- [ ] **Load time.** Play from the title after a moment: no long hitch; on the laptop Medium starts within about half
  a second of Low.
- [ ] **No shader hitches (PF1).** Start the game with `--perf` on Medium, High and Ultra in turn, the first time
  after installing. The first picture of the field holds a moment before round 1 while shaders build: note how long.
  Then turn round, face the sun, switch replicas, reload, aim the 2x scope, watch an eliminated figure fade and let
  overtime raise the flag. No hitch shows in the perf log.

## Accessibility

- [ ] **Team colours › High contrast.** Light blue and dark orange on the figures, flag, armband, scoreboard, feed and
  markers, from the next match.
- [ ] **Spare magazines.** A nearly empty spare is striped as well as orange; the one a reload takes has a yellow caret.
- [ ] **On-screen sound cues** (Off by default). A marker round the crosshair points to enemy footsteps, shots and hit
  calls, fainter further away; your own and teammates' sounds show nothing. Size 200 % and colour Yellow make them big
  and yellow.
- [ ] **Reduced motion.** The replica stops bobbing and swaying, shots kick half as much, leaning tips the view only
  slightly and the dust goes.
- [ ] **A screen reader** (NVDA on Windows, Orca on Linux) reads out being hit, the round result once and each squad
  order.

## Save

Settings › Save file. Everything saves as it changes; nothing to press.

- [ ] **Saved automatically.** Change the field of view: "Last saved just now"; quit, start again and your settings,
  Loadout, level and records are as you left them. Closing the window mid-match loses nothing saved before it.
- [ ] **Save to file and load.** Save to file writes `airsoft-save-<today>.json`, readable JSON. After Delete (or on
  another computer) Load file, or dropping the file on the window, shows both saves side by side; Replace loads yours;
  Undo brings back what was there.
- [ ] **An edited file.** Change `xp` in a saved file and load it: the pop-up warns and the button reads Load anyway; any
  other file says "That file isn't an Airsoft save".
- [ ] **Mid-match.** Save to file works; Load, Restore, Undo and Delete are greyed with "Leave the match to load a
  save."
- [ ] **Restore points and Delete.** One restore point per day you play (three at most), with the same pop-up and an
  Undo.

## Builds and the desktop

Play a release build (installer or zip) for these; running from the Godot editor behaves a little differently.

- [ ] **Install and uninstall (Windows).** The installer adds a Start menu entry and runs the game; uninstalling
  removes it and keeps your save. Installing a newer build over it keeps your save and settings.
- [ ] **The zip and the Linux build** run from their folder and boot to the title with no error.
- [ ] **Window modes.** Settings › Display: Windowed, Borderless fullscreen and Fullscreen each apply at once and are
  kept after a restart; F10 goes fullscreen and back with play carrying on. A window can be resized and moved, and
  the picture and HUD follow.
- [ ] **Mouse capture.** Play captures the mouse; Esc pauses and frees it; Resume captures it again with no jump on
  the first move. The pointer never leaves the window while captured; the back and forward side buttons do nothing
  unless bound.
- [ ] **Raw mouse input.** Mouse look follows the mouse one to one: Windows pointer speed and acceleration change
  nothing in a match.
- [ ] **Alt-tab and focus loss.** Alt+Tab, the Windows key, clicking a window on a second screen or a notification
  stealing focus mid-round pauses the match and frees the mouse; nothing happened while you were away; away while
  running forward, you stand still on Resume.
- [ ] **Resolution and scaling.** At 1280×720, 1920×1080 and 4K, and at Windows scaling 100 % and 150 %, the menus
  and HUD keep their size and layout as described in [Menus](#menus); text is sharp, never blurred.
- [ ] **V-Sync and the frame-rate limit.** V-Sync On holds the screen's refresh with no tearing; Off with a limit of
  60 on a 120 Hz screen reads about 60 in F3; Off and Unlimited runs as fast as it can.
- [ ] **Multiple monitors.** The game opens on the monitor it was last on; fullscreen fills that monitor only; moving
  the window to another and back keeps the picture right.
- [ ] **Graphics problems.** A graphics card or driver the game can't use gets a message, never a black window.

## Old bugs to recheck

Bugs the browser game had and fixed; a bug pass checks the rebuild doesn't bring them back.

- [ ] **Hit a bot, press Esc and resume** (also after Play again): no hit marker or white flash replays.
- [ ] **At the start of each round** the replica in your hands stays still; it doesn't swing in from the side.
- [ ] **Empty the AEG with the trigger held, press 2 then 1 while holding:** it clicks dry and starts a reload.
- [ ] **Customise › Muzzle** with nothing fitted reads "Bots hear your shots from 22 m."; with a silencer "… from 11 m
  (22 m without a silencer)."
- [ ] **New game at 1920×1080 and 2560×1440:** "Elimination" stays inside its card.

## Reporting what you find

Post each problem in the project chat, one message per problem. These four things let it be fixed without guessing:

1. **What you did,** step by step ("crouched behind the crate by the office door, leaned right with E").
2. **What happened,** and what you expected instead.
3. **The seed** from the F3 box, with the map, mode and difficulty.
4. **A screenshot or short clip** if you can (Windows: Win+Shift+S; Mac: Cmd+Shift+4).
