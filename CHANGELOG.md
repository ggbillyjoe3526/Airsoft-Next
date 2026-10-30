# Changelog

What changed in each version of Airsoft, newest first, in plain words. Each release's section becomes its GitHub
Release notes, so headings look like `## 0.1 Dev 2 (2026-10-18)`: the version name from `docs/PROCESS.md` ›
Versioning.

Don't edit this file for a change: add a note to `changelog.d/` instead (its `README.md` says how). At release time
`tools/changelog.sh release` gathers those notes into a new section here.

The browser game's changelog is `legacy/browser/docs/CHANGELOG.md`.

## 0.1 Dev 1 (2026-10-30)

### Compact, steady menus
- Every menu is tighter: buttons, choices and switches share one height and one type size, and the long lines of help under rows, bot levels, modes, maps, the replica list and the Performance panel are now tooltips (rest the pointer on them). Help a player needs to get by stays on screen.
- An On / Off setting is a switch: a pill that turns yellow with the knob at the right. Clicking any switch or choice, anywhere, no longer moves or resizes anything else on the screen.
- Holding the mouse down on Customise's **LOADOUT** button no longer cuts it to "LOADOU", and no other button cuts its words when pressed, hovered or greyed.
- The Graphics tab's **FOR YOUR CARD** tag sits above its preset instead of over it.
- The bots' XP multiplier shows after **OPPONENTS**; Attack / Defend's "attacks first" line no longer pushes the bots down; **PLAY** keeps one width when it becomes **PRACTICE**.
- The Match screen reads as one screen: the maps in a row across the top, and Mode, Rules, Your team and Bots in columns under them; the modes are short buttons like the rest, the team buttons smaller and **PLAY** narrower.
- On a 4K screen the menus draw exactly as on a 1080p one, twice the size, instead of smaller with most of the screen empty.
- Customise's BBs page, the Armory's XP panel, the order wheel and the Dev tab keep their explanations in tooltips; the Graphics tab heads its squares **GPU COST**.
- Settings says less: the line under Graphics' preset, the squares' key, the render scale's size and Display's F11 / Alt+Enter hint are tooltips now, and the renderer just says **Applies on restart**. The squares explain themselves when you point at them.
- **Show FPS** puts the figure in the bottom-right corner, where it covers neither the level chip in the menus nor anything in a match.
- Five saved loadouts with long names fit the Loadout screen: a long name ends in "…" and shows whole when you point at it.
- Dragging the BB weight no longer makes the Performance panel grow and shrink: what got better and worse is its tooltip. The save folder's path on Save File shows whole, however long.
- The Armory's starting kit wraps onto a second line instead of running off the right of the screen, and the Loadout's Performance panel no longer runs down onto **CUSTOMISE**.

### Leaving a match, the score bar and the sight
- Leaving a match or the range takes you back to the Match page with Play ready, not the title screen. Click AIRSOFT
  for the title.
- Your team is always on the left of the score bar, in its own colour: playing Beta it reads BETA, then ALPHA, through
  half time too. The scoreboard, the round's table and the match summary list your team first as before.
- Aiming down sights comes up smoothly at every Dev game speed: at 25 % it no longer stutters, and at 150 % and 200 % it
  no longer jumps unevenly.

### Manual reloads
- Your replica no longer reloads by itself when its magazine runs dry: a trigger pull only clicks, and a small RELOAD prompt with your Reload key (R unless you rebound it) shows under the crosshair until you reload.
- Prefer the old way? Settings › Controls › Reload: Automatic reloads on an empty trigger pull, as before. Bots reload just as they did.

### Hit call and banners
- When you are hit, "HIT!" and the walk-off line no longer cover the score bar and the clock, even when your hit ends
  the round and LOST or WON shows with it.
- HIT!, the walk-off line and the round banners now sit just under the score bar and stack neatly at every window size
  and HUD size, and the banner stays still when the hit call ends.

### Bots' replicas stay out of walls
- A bot or teammate standing at a wall, a stack of crates or other cover lifts its replica muzzle up, both hands
  still on it, and brings it back level as it steps away: the barrel no longer pushes through the wall. It still aims
  level to fire.
- Calling a hit, a player's replica hangs straight down from the hand, no longer poking forward into a wall.

### GBB Pistol
- Reloading the instant you fire the GBB Pistol's last BB no longer leaves the slide forward: it locks back and
  closes near the end of the reload, as it does for a slower reload.

### Magazine hand-off
- A bot bringing a magazine no longer stops short where something at head height, like the top of a window, blocks its toss: it keeps walking up until it can throw. A bot waiting for yours does the same.

### Menu fixes from the first playtest
- Pressing an On / Off switch in Settings no longer moves or resizes anything around it, and the Graphics tab's preset line keeps its height when a switch turns the preset to Custom.
- The "For your card" tag on the Graphics tab is no longer cut off by the preset button beside it.
- The "LOADOUT" button at the top left of Customise works again, and so does the LOADOUT tab in the top bar.
- Buttons are as wide as their words, and the buttons in a group (a row, the pause menu, the top bar's tabs) share the widest one's width, instead of stretching across the screen.
- Settings' **Back** is a small button at the bottom left. The Display tab is one column to fit its wider choices.
- Click **AIRSOFT** at the top left to go back to the title screen.
- **Esc** in the menus, the title and Settings asks "QUIT GAME?" with **Quit** and **Cancel**; Esc again or Cancel closes it. A dialog, a key being rebound and the Loadout's rename still take Esc first, and in a match Esc is still the pause menu.

### Playtest fixes: firing on the run, walls and seeing your BBs
- Firing while you sprint brings your replica up out of the carry at once, pointing where you aim; it drops back a
  moment after your last shot.
- Holstered, your sprint is a little faster than with your replica out (a tenth), for bots too.
- Your replica no longer sinks into a wall you stand against: it draws over the wall, and aimed, the sight stays at
  your eye.
- White BBs are easier to see: a little larger at range, with a darker edge and a faint short trail.
- Your own BB no longer seems to go into a wall up close: it is drawn leaving from beside the barrel, never ahead of
  where it really is, so it vanishes at the wall's face.

### Fixes before 0.1 Dev 1
- The Match screen opens on the map and team you last played, even after quitting the game.
- A middle click while the order wheel is open no longer drops a ping where you were looking before you opened it.
- Hold Here's marker no longer stays on screen over the match results.
- Leaning against a wall while turning back and forth no longer rustles on every turn.
- Bots now hunt inside Woodland's hut, not only round it.
- Woodland's map card and loading picture show its bushes.
- A bug report now hides a user name and password written into a web address.

### New first-start settings
- The game now launches in exclusive fullscreen, on the screen it opens on.
- V-Sync and edge smoothing are off to begin with, on every graphics preset. Turn either on in Settings if you want it.
- The title and menus draw no more frames than your screen's refresh rate, so they stay cool and quiet with V-Sync off.
- New volumes: master 100 %, effects 70 %, power source 100 %, ambience 30 %, interface 40 %.
- If you already have a save, any of these you never changed moves to the new value once. Anything you set yourself stays as it is.

### Dev tab always there
- The Dev settings box under the Settings tabs is gone: the Dev tab is always there, and each of its switches works as soon as you turn it on. Every switch starts off, so the game plays as before until you change one, and a match with a cheat on still stays out of your records and gives no XP.
- A save from before with the box unticked comes back with every Dev switch off, so nothing set long ago suddenly applies.
- Bot callouts, Elimination's overtime flag, pings and the magazine hand-off are no longer in development: they are part of the game, each with its own switch in Settings › HUD.
- A bug report's Dev settings line lists the switches you changed, or "none".

### Bots share magazines
- A bot running low on BBs now asks the nearest teammate with a magazine to spare ("Need a mag!"), and a bot asked comes over and tosses it ("Mag coming!"), sprinting while far off; the catcher may say thanks.
- A fight or cover comes first, then bringing a magazine, then a squad order. A bot never gives away its last full spare of the replica it fights with, but hands over its unused pistol's.
- Dev settings › Bots run low on BBs puts one bot a team on its last magazine early in each round, to watch it happen; Bot intentions shows a bot bringing or waiting for a mag.
- Need a Mag on H, and as the order wheel's fifth item: toss a magazine to a teammate who asked you and is in reach (the item then reads Toss a Mag), or ask for one when you are low, with a radio click when your ask is heard. The magazine arcs and spins from hand to hand, with its own toss and catch sounds.
- A line under the crosshair says who needs a mag and how far (underlined in your team's colour once in reach), whose is coming, what you caught and why a press did nothing, never which key to press; a small magazine sits by the chevron of a teammate asking you or bringing you one. Settings › HUD › Mag hand-off turns them off, and Screen reader messages read the line's notices.

### Neon Heights removed, Woodland public
- Neon Heights is gone from the game. The fields are Depot and Woodland.
- Woodland is on the Match screen for everyone, beside Depot, and plays by night.
- The Weapon Torch is no longer Dev content: anyone can fit it in Customise's Light slot, and bots carry it at night.
- A night match on Woodland counts towards your records.
- Your other records are kept as they were.

### Magazine hand-off
- Running low on BBs, you can ask the nearest teammate within 30 m who has a magazine to spare for one, and toss one of yours to a teammate who asked you from within 6 m. A tossed magazine flies a moment and lands in their pouch; it is lost if they are hit or the round ends first. The key and the screen come next.

### Links use the new repository name
- The game's GitHub links now point to the renamed repository, ggbillyjoe3526/airsoft: the bug report's link to open an issue, the installer's publisher and support and updates links, and the wiki.
- Nothing in play changes.

### Pings
- Press the middle mouse button (Squad: ping a spot in Settings › Controls) to mark where your crosshair meets the field, up to 120 m away, for your bot teammates. An opponent you can see under the crosshair is marked as a contact instead; the sky marks nothing.
- Your teammates take a ping as somewhere worth a look for 20 s: one sets off to check it the way it plays, or watches it when it is under your order or holding a post, and one of them answers in the feed ("Going to your ping", "Watching your ping"). A teammate in a fight carries on.
- One ping each at a time, a double click is one ping, and pings clear each round. They do nothing while you are out or on the range. A teammate calling Contact may also mark that enemy for you.
- A ping shows as a ring in your team's colour with "PING · 9 M" under it, with a soft pip in your ear; a teammate's Contact mark is a diamond in the other team's colour over where the enemy was seen, and it never follows them. Markers pop in, stay 7 seconds and fade over the last one, sit under the minimap when off screen, and show on the minimap too.
- Settings › HUD › Ping markers (On by default) hides the markers only: pings, the pip and the answers go on.

### The overtime flag on screen and in sound
- When Elimination's overtime flag goes up, three quick whistle blasts sound and a banner says OVERTIME · TOUCH THE FLAG for a couple of seconds.
- The flag rises out of the ground at its spot: a chequered off-white and dark cloth on a short pole, always turned to face you, with a ring on the floor a metre round it. It is only drawn: BBs pass through. With Reduced motion on it is simply there.
- The clock and the scoreboard's heading read OT and the flag's time left. A FLAG marker with a chequered flag and the distance sits over it, seen through cover and pinned under the minimap when it is off screen, and the minimap shows the chequered flag at its spot.
- The ring turns yellow while both teams are at it. Once a team touches the flag its cloth and ring take that team's colour, and the round ends FLAG TOUCHED with that team's line; the round's table counts the overtime played.
- With Screen reader messages on, the overtime and a round won at the flag are read out.

### Bots go for the overtime flag
- When Elimination's overtime flag goes up, every bot now sets off to touch it a moment after the clock runs out: about a second on Easy, half a second on Normal, a third of a second on Hard. Anyone it sees on the way still comes first.
- Anchors and careful bots first watch the flag from cover close by, aiming at it (an anchor about 12 s, a careful bot 5 s), then go in; every bot goes in for the overtime's last 10 s, and the last of a team goes at once. A flanker far out may come at it round one side.
- A bot you gave an order keeps to it, as at Attack / Defend's pole. On each team the bot nearest the flag calls it in the feed, naming where it stands.

### Elimination's overtime flag
- When an Elimination round's clock runs out with players left on both sides, it now goes to overtime: a flag goes up near the middle of the map, and the first team with a player within a metre of its foot wins the round at once.
- Players of both teams at the flag hold each other off, and a team knocked out while it is up still loses. Untouched for 30 s, the round is a draw, played again as before.
- Depot's flag stands by the Box's east wall and Woodland's in the east meadow, each about as far from both ends' spawns. Attack / Defend and practice have none.
- Dev settings › End the round now ends an overtime as a draw, unless a team has a hand on the flag at that moment: then that team wins.

### Callouts in the hit feed
- Your teammates' calls now show in the hit feed with the hits, newest on top: their chevron and name in your team's colour, a radio and the words ("Rook: Two, Crate yard!"). A call stays as long as a hit line and fades the same way; on Keep the hits stay and the calls still go: a call shows on top and the oldest hit comes back into view when it goes.
- Each call clicks over the radio, panned toward the teammate who made it. You never see the other team's words, but an enemy within 15 m is heard keying their radio from where they stand, muffled through walls.
- The calls go at the start of each round.
- Settings › HUD › Callouts, On by default: Off hides the calls and their clicks at once. A squad order a teammate takes still clicks.
- With Screen reader messages on, each call is read out politely ("Rook: Two, Crate yard!").

### Bot callouts
- Bots now decide what to call to their team as they play: "Contact, Dock!", "Two left!", "Last one!", "Movement, Crate yard.", "Reloading!", "Pushing Bay!", "Holding Dock.", "They're on the flag!" and more.
- Calls come one at a time for each team, never a stream: about 10 to 12 a team a minute.
- Each personality has its own lines and talks more or less: rushers and careful bots chatter, anchors and flankers keep quieter.
- Hit players never talk, and what a bot says never changes how anyone plays: a match with the same seed plays the same.
- The lines, how often each is called and the pace are in `data/callouts.md`, which the game reads at start; a row it can't read is skipped, with a warning naming its line.

### Three bot levels
- The bots now come in three levels, Easy, Normal and Hard, and Pro is gone: each level moved up a name.
- Easy bots play as Normal bots did, Normal bots as Hard bots did, and Hard bots as Pro bots did: they hold angles, clear corners, trade hits and play as a team.
- The old Easy is gone, with its habits of shooting into bushes and standing in the light at night.
- XP stays with the names: Easy ×0.5, Normal ×1, Hard ×1.5. A new player still starts on Normal.
- The Pro tips on the scoreboard and the What got you card on Auto now come with Hard bots.
- Your teammates follow the opponents' level at every level, Easy included.
- Your records keep the bots they were won against: the old Easy's and the old Normal's both show under Easy, the old Hard's under Normal and the old Pro's under Hard.

### Depot looks like an airsoft site
- Depot now looks like a real airsoft site instead of grey boxes, with temporary stand-ins until the final models arrive.
- Painted shipping containers, plywood barricades, breeze-block walls, gabions and sandbag stacks fill the site.
- Zone names are stencilled on the walls: HALL, STORES, WEST ROOM, DOCK, BOX, EAST YARD and CAR PARK.
- The loading dock has a hazard-striped lip and a shade sail, and the watch tower has a camo net and flag.
- Wrapped pallets, crates, gravel beds and a concrete slab with yellow bay lines make up the yards.
- Container paints stay clear of the team colours, so they never read as a side.
- By day the sky has cumulus clouds drifting over a soft haze.
- The practice range in Depot gets the same look, with its layout unchanged.
- Cover and paths are as before, and Low keeps the look, dropping only the fine surface relief.
- Woodland looks the same as before. At night only the new surfaces change.

### Woodland checks
- Bots hold their fire when a teammate could step into the shot before the BBs arrive: one turning a corner on its way, or one fighting near the enemy who might strafe or dash into the line. They also remember that a miss flies on: a teammate far beyond the enemy, still within a BB's carry, counts too.
- A vault begun right against a low wall no longer leaves you or a bot standing on top of it.
### Internal
- Every change now plays 80 bot-only matches on Woodland at 5v5 at night, in Elimination and Attack / Defend at every difficulty. The balance report covers Woodland too.

### Practice on any map
- Practice is now offered on every field, not just the range: no bots, no score, and you start at Alpha's first spawn.
- The targets stand where the other team would play, worked out from the map itself: on lane points watching back down their lane, at the other team's spawns and along the lanes, crouched behind low cover, with steel plates, movers and swingers where they fit.
- The timed challenge works there too: its START plate stands a few metres ahead of you, it lights only targets you can see (none past 50 m), and each map keeps its own best. A run with a play-changing Dev setting is still never a best.
- On a field the readout says how far from you a BB landed, and the minimap reads "Practice" instead of a round.
- Practice on Woodland plays at night with your weapon torch.

### The range moves into Depot
- The practice range is now part of the Depot site: Depot's masts, watch tower, cranes, sheds, water tower and chimneys stand round it instead of hills and pines. Its lanes, plates, figures, movers, swingers and timed challenge are exactly as before, and your best carries over.

### The game's wiki
- Airsoft now has a wiki on GitHub: getting started, controls, how to play, every replica's and part's stats, levels and unlocks, maps, modes, bots, squad orders, the HUD, settings, accessibility, saving and bug reports, a FAQ, patch notes and the roadmap.
- Its tables (stats, unlocks, maps, keys, graphics presets, bot kits, match rules) and its patch notes are read straight from the game's own files, and it is published again every time the game changes, so it always describes the game as it is being built.

### Glowing BBs
- Customise › BBs has a Glowing BBs row under BB weight: At Night (the default), Always or Off, for each replica, kept with your loadout.
- A glowing BB is drawn green, a little larger at range, with a longer green streak, so you can follow a shot all the way; white BBs look as they did.
- Every bot loads glowing BBs at night. They fly exactly like white BBs: only how they look changes.

### Weapon torch
- Customise has a Light slot: fit the Weapon Torch to any replica. It's kept with your loadout, and only fitted on a field played at night.
- T switches it on and off with a click (rebind it under Settings › Controls › Keys). It goes out when you holster, switch to a replica without one, are hit, and at the start of each round.
- On Medium and up your torch is a real light from the rail, with shadows on High and Ultra while sun shadows are on; on Low it is a soft haze.
- Everyone else's lit torch shows as a pale beam, a glare at the lens and a lit spot where it lands.
- Every bot carries one at night and switches it on in a close fight and at the end of a search, never flickering it.
- Bots see anyone standing in a lit beam from about 40 m, and anyone pointing a lit torch near them from as far: a torch lights the way and gives you away.

### Bots by night
- At night bots see only as far as the light lets them: about 40 m if you stand in the light of a fire or lantern, 25 m in the open under the moon, 15 m indoors and only 10 m under the trees. This counts on any map played at night.
- Bots on Normal and up keep out of the light pools when they hold a spot or hunt for you. Easy bots stand wherever their lane takes them, light or not.

### Woodland's bushes
- Bushes on Woodland now hide you and stop BBs. You walk straight through them, but bots can't see you through more than about half a metre of leaves.
- A BB that pushes 0.6 m into a bush stops there. One that clips an edge flies on, slower and thrown off its line, so a shot through the edge of a bush is a gamble.
- Bots hold fire when more than a quarter metre of leaves is in the way. Easy bots fire into bushes anyway.
- A BB in the leaves rustles and throws a green puff and a few leaves. One through an edge rustles more quietly and knocks off a leaf or two.
- "Leaves in the way · step clear to shoot" shows when your own BB stops in leaves right in front of you.
- Bushes are marked on the minimap.

### Woodland's look
- Every pine on Woodland has a crown over your head. It is only for looks, so you see and shoot under it as before.
- A forest and treelines stand beyond the fence and fade into the sky.
- From Medium detail: grass tufts in the meadow, puddles and mud that look wet, leaves by the trunks, fallen branches and twigs, and moss on the logs.
- At night fireflies hang by the logs and the water, and specks drift in the air. The Wind dust setting sets how many, and Reduced motion holds them still.
- Woodland's ground is drawn in pieces, so the parts you can't see cost nothing.

### Night play
- Woodland is played at night: a low moon, stars, haze and a dim fill, with fires and lanterns lighting the ground round them. Fires flicker.
- Settings › Dev › Time of day plays any map by day or by night; a Dev night match stays out of your records.
- Depot by night keeps its baked shade, and the light masts round the site glow.
- Figures, logs and the ground stay readable at night in both team colour sets.

### Team sizes for each map
- Each map has its own team sizes. Depot plays 1v1 to 3v3.
- Woodland plays 5v5, or 6v6 under Custom rules.
- Skirmish plays the map's usual size. Under Custom rules the Team size row shows only the sizes the picked map offers, and your pick is kept when you switch maps and back.
- Big matches load more smoothly: the loading bar keeps moving while the bots learn the map.

### Woodland, a rolling wood
- Woodland plays now, beside Depot on the Match page.
- Its ground rolls, with hills, a knoll and a ravine. You can walk, run and crouch up and down the slopes, and stand still on them.
- Footsteps on Woodland sound like grass or leaf litter. A BB that hits the ground puffs like earth and never bounces.
- Bots play Woodland. They walk every lane and hunt over the whole wood.

### Nobody slides on spawn
- Spawning on a slope or a stair edge no longer slides you a few centimetres.

### Human figures
- Everyone in a match is drawn as a human figure.

### Puffs and dust
- Gas pistols puff a short, faint cloud from the muzzle and a smaller one from the ejection port on each shot, for you and other players.
- Electric and spring replicas don't puff, and neither do shooters more than 35 m away.
- Sprinting kicks up a low, faint puff of dust at each footfall, and landings raise a bigger one.
- Dust takes the colour of the ground and is lit by sun or shade. It stays below knee height, so it never hides anyone.
- Dust is off when Wind dust is set to 0 %.
- Wind specks glint in sunlight, vanish in shade and fade out near your eyes.
- On Low graphics, where sun shadows are off, every player has a soft shadow under their feet.

### Noisy props and loud ground
- Running or sprinting into a noisy prop knocks it, with its own sound and a puff of dust.
- Steel skips and containers carry furthest, then generators, IBC tanks, racks, plastic toilets, and wooden crates and wrapped pallets.
- Walls, barriers, sandbags, plywood and floors stay silent; walking and crouching never knock anything.
- Each prop knocks at most about once a second.
- Bots hear a knock as footsteps from whoever made it, muffled by walls; an enemy's knock shows as a step on the sound cues and minimap.
- A BB hitting steel hard makes it ring; the ring is faint and only turns an idle bot's head.
- Running, sprinting and landing on gravel or steel is louder and carries further.

### Skylines on Depot and the practice range
- Depot has a skyline beyond its walls: a concrete watch tower to the north, and an old aircraft fuselage past the east wall with its fin showing.
- Four light masts stand at the corners of Depot. They are not lit yet.
- Chimneys, a crane, silos and sheds sit further out, faded toward the sky. You cannot reach them.
- On Medium graphics and up, three chimneys smoke, and the smoke bends with the wind.
- With Reduced motion on, the smoke hangs still.
- The practice range has a skyline too: hills, sheds, a water tower and a power line.

### Baked light in Depot
- Depot has soft baked light on Medium graphics and up.
- Corners, wall feet and the inside of the Box are shaded by the sky they can see.
- Sunlit walls bounce a little warm light onto the ground beside them.
- A new Baked light row on Settings › Graphics turns it on or off. It is off on Low.
- You can switch Baked light on or off mid-match.

### The Box, port walls and gravel on Depot
- Depot's middle container is now the Box, a roofed container you can fight inside, with offset doors and ports.
- Four plywood walls on Depot have a port at standing height: stand to see and shoot through, crouch and you're hidden. They can't be vaulted.
- Gravel beds at the Office doors crunch underfoot.

### Internal
- Every field's longest sightline, whether the spawn areas can see each other, the walks to the middle and the defenders' head start to the flag are now tested. Nothing changes in play.

### Accessibility settings
- Accessibility choices now have a place in your settings file, ready for the settings to come, and keep what you have already set.
- A crosshair at its lowest opacity now stays there after a restart instead of going back to the default.

### Armory
- The ARMORY tab shows your level out of 10, the XP bar and what the next level takes.
- It shows the XP you have earned in all, and how many of the 19 items are unlocked.
- It shows the next unlock with its picture, and how XP is earned with the difficulty multipliers.
- Every level lists its items with their pictures, marked unlocked, next or locked.
- With Disable levelling on, the Armory says everything is unlocked.
- If your level or records file can't be read, the Armory says so at the top.
### End-of-match XP
- The XP from a match shows under the win banner, line by line, with the total.
- A level-up card names what you unlocked, with its picture.
- A match that gave no XP says why.
- The card stays up until the next match starts.

### Parts that change how a replica plays
- Replica parts now change how a replica plays. You can't pick them on screen yet; the Customise part tabs come next.
- The AEG Rifle's red dot (1.25x zoom) and 2x scope (2x zoom, slower to raise) change how you aim.
- A vertical grip is slower to bring up but steadier after a sprint. An angled grip is quicker but shakier.
- Hi-cap magazines hold twice the BBs in fewer magazines, but they rattle, so bots close by hear you even when you walk.
- Low-cap magazines hold fewer BBs but change and draw quicker. The pistol's extended magazine holds more.
- A tight-bore barrel gives tighter groups. A long barrel gives more energy but is front-heavy.
- A silencer means bots hear your shots from half as far, with a little less energy.
- The pistol's red laser gives tighter groups.
- Barrels and silencers count toward the field's energy limit.
- A replica with no parts plays exactly as before. Bots carry their replicas as they come.

### Part tabs on the Customise screen
- The Customise screen has part tabs. On the AEG Rifle pick an optic (red dot or 2x scope), a grip, a barrel, a muzzle part and a magazine.
- On the GBB Pistol pick a laser, a silencer and the extended magazine.
- A tab the replica can't take shows greyed out, with the mount it needs.
- The light waits for night fields.
- Each card shows the part's picture and what it changes against the replica, better in green and worse in red.
- The replica's picture shows the parts fitted.
- The Performance sheet adds Zoom aimed, Aim in and a Rattles warning for hi-cap magazines.
- Parts don't show on the replica in your hands yet; that comes next with looking through the sights.

### Internal
- Attack / Defend's flag rules are in but not playable yet: attackers raise the flag in 5 s, defenders pull it down in 3 s, a time-out goes to defenders.

### Attack / Defend in play
- Attack / Defend can be picked on the Match screen on Depot or Woodland; a map without a flagpole says it needs one.
- The team you pick attacks first, and sides swap at half time. The Match card says who attacks first.
- A flagpole stands at the defenders' flag spot, with a ring on the ground showing its reach.
- The ring is white with nobody on the rope, the attackers' colour as they raise, the defenders' as they pull down, and yellow when both are there.
- The flag climbs the pole in the attackers' colour, and the rope ratchets as it goes up or down.
- The HUD shows ATK and DEF tags over the scores, and a FLAG gauge with 12 notches that fill as the flag rises.
- "OT" on the clock shows the overtime left once time runs out while attackers are on the rope.
- "Their flag is going up!" pulses when you defend and are away from the rope. A "FLAG · 24 m" marker sits over the pole and hides within 5 m.
- Rounds open with "ROUND 1 · ATTACK / TAKE THE FLAG" or "ROUND 1 · DEFEND / HOLD THE POLE".
- Rounds end with "FLAG RAISED / ALPHA TAKE THE ROUND" or "DEFENDED / TIME'S UP · BETA HELD THE POLE".
- Attack / Defend matches give XP and count for your records, as Elimination does.

### Internal
- A new balance report plays 32 seeded bot-only matches on Depot, and more on Woodland, showing win shares, clock-outs and first-hit timing. It never fails a build.

### A breeze in every match
- Each match has a light breeze, from calm to about 2 m/s with gusts, and a new one each match.
- The wind pushes BBs, never players. BBs drift downwind, lighter BBs and longer shots drift more.
- Specks of dust in the air drift with the wind, so you can read it.

### Hop-up dial
- Press 4 (less) or 5 (more), or Page Down and Page Up, to turn your replica's hop-up dial during a match.
- The replica panel briefly shows the setting and how far a level shot stays flat, or where an over-hopped BB starts to climb.
- Each replica keeps its own setting until the match ends. Bots keep their factory dials.

### Ricochets
- BBs bounce off concrete and steel containers. Crates and the ground stop them.
- By default a bounced BB that hits you doesn't count. You hear a tick, see "Ricochet: play on" and keep playing.
- A match rule makes ricochets count, so a bounce can take out anyone, its shooter included. There is no menu for it yet.

### Bot difficulty
- The BOTS row on the Match screen now offers Easy, Normal and Hard; Pro still says LATER.
- Easy bots react slower, aim shakier and never flank.
- Hard bots react faster, aim steadier, lead moving targets more, take cover more and flank more often.
- Your teammates play at the other team's level, except against Easy, where they play Normal.
- XP uses the lower of the two teams' multipliers: Easy ×0.5, Hard ×1.5.
- Records count a match only when your teammates are at the other team's level or the one they follow by default.

### Bots carry kits
- The other team's bots now carry kits: Factory, Rifleman, Marksman, Support, Stealth, Pointman and Cyber, each with its own parts and power source.
- Kit parts work as they do in your hands and show on the bots' figures: red dots, the 2x scope, grips, hi-cap magazines, LiPo batteries and the Silencer.
- Each bot picks its kit by difficulty: Pro bots never carry the stock rifle, and the Cyber Pistol kit never appears at Normal.
- The same match seed gives the same kits, so a replayed match plays out with the same loadouts.
- Your teammates still carry the stock AEG and pistol.
- Bots fire on full auto wherever their replica has it.
- Dev gear appears in a bot kit only while Dev content is on.
- A row in the bot kit table that the game can't read is skipped, with a warning naming its line.

### Bots have names and personalities
- Every bot now has a name and a personality. A name always plays the same personality, and each team gets different ones while there are enough.
- Rushers push in and run at where someone was.
- Anchors hold their point short of the middle until late in the round, watching from cover, and only go after noises nearby on their own floor.
- Flankers take a lane of their own and go round more often.
- Careful bots pause longer and watch where you ducked out of sight.
- Personalities change how a bot plays, never how well.
- Bots' kits lean towards their personality.
- Names show in the Dev tab's bot intentions and, while spectating, on a WATCHING line at the bottom of the screen. Never over heads.

### Opponents and teammates
- The Match screen's Bots section has two rows, Opponents and Teammates, each set to Easy, Normal, Hard or Pro, with a line on how that level plays.
- Your teammates follow the opponents' level (Normal against Easy) until you pick one; "Follow opponents" puts them back.
- The XP line shows what the match will pay: the lower of the two levels, so Hard opponents with Normal teammates pay ×1; at most ×1.5 in a Custom match.
- A Custom 1v1 greys out the Teammates row, as there are no teammates; your pick comes back at 2v2.
- The summary line names your teammates' level when it differs from the opponents'.

### Bots and elimination rounds
- Alpha plays with two bot teammates against three bots on Depot, in Elimination rounds, first to five wins.
- Bots walk the lanes, hold corners, hunt, fight, take cover behind crates and sandbags, and sometimes flank.
- Bots peek over low cover and lean out round tall corners, and search where they last saw or heard you.
- Bots only know what they see (a 120 degree view, no seeing through walls) or hear, and walls muffle sound.
- Walking and moving crouched are silent, so sneak up on them if you can.
- Bots react after a moment, their aim settles, and they never shoot with a teammate in the way.
- Bots call their hits honestly, the same as you.

### Lean and vault
- Hold Q or E to lean left or right round a corner. You slow to a walk while leaning.
- Press Jump at a low wall to vault over it.
- Bots don't vault yet.

### Dead zone
- When you're hit, you walk off to the dead zone round cover instead of through it.
- In the dead zone you watch the round through a teammate's eyes.

### Not yet
- Only one bot difficulty, Normal, is in.

### Bots play Attack / Defend
- Attacking bots walk their lanes to just past the middle, then make for the pole.
- The nearest attacker raises the flag crouched at the rope while the others guard it from cover close by.
- Defending bots hold the first or second point of their lane near the pole.
- Defending bots go after only what they see or hear within 12 m of the pole, on its floor.
- The two defenders nearest the pole run to pull the flag down once it is off the bottom.
- An anchor holds by the pole on defence, like every defender.
- Attack / Defend is not playable yet: the mode stays greyed out on the Match screen until the pole, HUD and Match card are built.

### Internal
- Match guards and the balance report now run Attack / Defend on Depot and Woodland, and the Dev tab shows bots "At the flag".

### Bots vault low walls
- Bots now vault low walls the way you do, pressing Jump to go over.
- Bots go over a low wall when that saves them a long walk round it.
- On Depot, bots now come over the office hall's low wall in both directions.
- A bot held up at a wall goes round for a few seconds instead.
- Players walking off after being hit still go on foot and never vault.

### Bug report text
- A bug report now lists the map, the mode and the rules, your system, your graphics preset and the settings you changed from the defaults.
- It also lists the last shots and hits of everyone in the round, the round's start and end, and your reloads, draws and squad orders.
- It notes frame timing for the play before it, and the recent errors, so a fix has more to go on.
- A crash report keeps the errors from the run that crashed.
- Personal details are taken out first: your user folder names, your computer's name, and any IP, MAC or e-mail address become placeholders.
- A long report is cut to fit, and the cut is marked in the text, such as "(left out to fit)".

### The crash screen
- If the game closes unexpectedly, the next start shows a crash screen once, before the title: "Sorry about that. Your save is fine."
- It says what you were doing: the match, the round and the seed.
- It shows the report, with a box for an optional note of up to 500 characters.
- Report a Bug opens a filled-in public GitHub issue in your browser. Nothing is sent until you press Submit there.
- Open log folder opens the folder that holds the game's logs.
- Continue goes to the title. Esc is Continue only while the note box is empty.
- Dev tab, Actions: Log a test error writes a test error to the log.
- Dev tab, Actions: Crash the game now closes the game, after a confirm.

### Crouch is held
- Crouch works while you hold C or Ctrl, the same as aiming with right mouse.
- Let go of C or Ctrl to stand up.

### Custom matches
- Custom matches are here: a Custom rule set sits beside Skirmish, the match as you know it.
- Set the team size (1v1, 2v2 or 3v3) and the rounds to win (first to 3, 5, 7 or 10).
- Set the round time (1:30 to 5:00, in half-minute steps), friendly fire, and whether ricochets count.
- Your Custom setup is saved and kept for next time.
- Custom matches never go into the records, and their XP tops out at ×1.5: Pro bots pay like Hard, the other levels as before.
- In a long match the ends swap one round before the win (first to 7: after round 6), so the deciding round is played in the second half.
- The Match screen has a Rules section under the modes, where you pick Skirmish or Custom.
- Skirmish shows its rules as chips, now including Friendly fire.
- Custom shows a row for each switch, each with a line saying what it does, and saves as you change it.
- The Elimination card and the summary line follow your Custom rules (for example "First to 7" and "Custom 2v2").

### The Cyber Pistol
- The Cyber Pistol unlocks at level 10: a futuristic electric pistol with semi, burst and auto.
- It fires 14 BBs a second from 50-BB magazines, and you carry 3 of them, with almost no kick.
- Its battery is built in, so no power source fits it.
- It keeps its own white, cyan and magenta colours, and Realistic colours turns it plain grey with no glow.
- It has its own shot, dry-click and magazine sounds.
- The fire selector on the AEG Rifle and the Cyber Pistol now shows the mode you are in.

### Debug views while playing
- Press F4 to show every BB's flight path in the world, so you can see the hop-up lift and the drop.
- Press F5 to show the hit areas on every character, visible through walls.
- Both views are off by default and cost nothing while off.
- The F3 performance readout now also shows the match seed, your position and how many things are in the world.
- Every Play starts a fresh random match seed.
- Launch with `-- --seed 1234` to replay the exact same match.
- F3, F4 and F5 are reserved, so Settings won't let you bind them.

### Defenders hold lanes side by side
- In Attack / Defend, two defenders on the same lane now stand side by side, facing the enemy, instead of on one spot.
- Pro defenders on a shared lane set up a crossfire: the second one moves round to cover the lane's next point from
  another angle, and neither ducks into cover while they hold it.

### Dev tab
- Settings has a Dev tab, always there, with every switch off until you turn it on.
- The Dev tab has Game speed, from 25% to 200%.
- Dev content shows maps that are still being built.
- Bottomless magazines, Ghost (BBs pass through you), Bots hold fire and Retro pixels (chunky pixels and a small dithered palette).
- Spectate any bot: your view follows a bot, and the fire key moves on to the next one.
- Bot intentions puts a label over each bot saying what it is doing.
- End the round now is in the pause menu during a match. Reset the save asks first.
- A match with any cheat on, or on a dev map, is kept out of your records.

### Map choice
- The title screen has a Map choice: Depot or Woodland.

### Installed game starts matches again
- The installed game no longer crashes when a match or the practice range starts, so it plays.

### Internal
- The test suite now checks every field's layout, so a broken map layout is caught before a build ships.

### Field sounds
- People nearby make kit rustle when they crouch or lean, so you can hear someone move in cover. Behind a wall the rustle is muffled.
- Landing from a drop thuds, and the further you fall the harder and lower the thud. A big drop comes with a rustle too.
- The referee's whistle now sounds: two short blasts start a round, one long blast ends it, and several long blasts end the match.
- The range's Time is a long blast.
- Each field has its own background calls that come from around you. Depot has birds, a crow and a dog.
- Woodland has birds and creaking pines by day, and owls by night.

### First playable: Depot
- Press Play Depot on the title screen to start on Depot, the greybox field, in first person on the Alpha side.
- You start with the AEG Rifle and the GBB Pistol. Switch between them with 1, 2 or the mouse wheel.
- Walk (Shift), run, sprint (Alt), crouch (C or Ctrl) and jump (Space).
- Aim down sights with right mouse, fire with left mouse, reload with R and change fire mode with B.
- Pause with Esc. Alt-tabbing pauses too.
- BBs fly visibly from the muzzle and puff on what they hit, in its colour: metal, wood, concrete or ground.
- The Beta side is four orange stand-in figures at their spawns. Hit one and you hear the tick, see the hit marker, and it raises an arm with "HIT!", walks off and fades.
- A round ends when one side is out. A match ends and rematches after 8 seconds.
- A first HUD shows the score, round clock, magazine, spares and fire mode, and a crosshair that opens with your spread. Round banners appear.
- Depot has sun, sky, shadows, positional sound and an ambience loop.
- Not yet: bots, lean and vault. The stand-ins never shoot, so you can't be hit yet.

### First start picks your graphics
- The first start shows your graphics card, your screen and the preset picked for them, with OK or Graphics settings. It shows once.

### Graphics step down when frames run slow
- While graphics are on "For your card", slow frames in a match step the preset down one at the end of the round, never mid-round and never below Low.
- The step is for this run only and isn't saved. A line under the score says "Set to Medium to keep the game smooth" for 5 seconds.
- A preset you picked yourself never steps down.
- Dev settings has "Pretend slow frames" to try the step on a fast machine.

### Gauge patterns
- Settings › Accessibility has Gauge patterns, on by default.
- Beta's score pips, score block and flag gauge fill are striped. Alpha's stay solid, in both team colour sets.
- Beta's score number gets a dark edge, so it stays readable on the stripes.
- A low magazine turns yellow and striped.
- The switch applies at once, even mid-match. The Accessibility tab shows a live sample.

### A fresh start in Godot
- The game is now an installable desktop game built with Godot, starting again at 0.1 Dev 1.
- It opens on a title screen showing its version, with a Credits screen listing the licences of everything it ships.
- Press F3 for a performance overlay (frame rate, frame time, draw calls).

### Graphics presets picked for your card
- The game picks a starting preset for your graphics card: Medium for built-in graphics, High for a separate card, Low on the simple renderer, never Ultra.
- Your settings file keeps everything you have already set alongside the new graphics, window and frame-rate choices.

### Graphics presets
- Settings › Graphics has Low, Medium, High, Ultra and Custom presets. The game starts on the one picked for your graphics card, marked "For your card".
- Every row applies at once, even from the pause menu in the middle of a match.
- Changing a row makes the preset Custom and marks the row you changed. Reset goes back to the pick for your card.
- Low turns off sun shadows, ambient occlusion and wind dust for speed.
- Choices your graphics card can't draw are greyed out.

### Hit feed and teammate markers
- A hit feed in the top right corner shows during a match, newest line on top.
- Each line shows who fired, a BB trail, who was hit, and their red HIT call with a raised hand.
- Names show in their team's colour, and the shooter's team colour runs down the left edge of each line.
- Your own lines say "You" and are framed in yellow.
- A line stays 6 seconds and fades over its last second; pausing holds it. At most 6 lines show.
- Teammates have a chevron in your team's colour over their heads, seen through walls.
- A teammate's chevron is solid when you can see them and hollow when cover hides them, even crouched behind low cover.
- Once a teammate is hit, their marker turns grey with a raised hand while they walk off, then goes at the dead zone.
- Markers never show over enemies and never show names; the same chevron sits by a teammate's name in the feed.

### Hit flinch
- A bot or teammate hit by a BB jolts its upper body the way the BB flew: sideways from the side, forward from behind.
- A BB falling steeply jolts less.
- The figure eases back upright in under half a second while its hand goes up to call the hit.
- Both plain figures and rigged figures flinch.
- When you are hit, your replica jolts and drops out of view over a quarter of a second instead of vanishing at once.
- The camera never moves, so Reduced motion leaves this as it is.

### Holster your replica
- Press 3 to holster your replica. It drops out of view, the panel says "Holstered" and the crosshair goes.
- Holstered, you run a bit faster than with the replica out, but never faster than a sprint. Walking and crouching are no faster.
- A fresh trigger pull, aim, reload or slot key (1, 2 or the wheel) draws it again. Drawing takes longer than a normal switch.
- A trigger or aim you were already holding when you holstered doesn't draw it.
- Bots holster too, on long calm runs in their own half. They draw as soon as there's a threat, a reload or they cross halfway.

### Smoother lean and vault
- A lean that a wall cuts short now eases back instead of snapping, and never shows inside the wall.
- A vault dips and tips your view as you go over.
- "Space to vault" shows under the crosshair whenever Jump would vault.
- A holster or hop-up dial press made mid-vault now counts once you land. The dial turn used to be lost.

### HUD matches the menus
- The match HUD now uses the menus' navy and yellow look.
- The top bar shows each team's score as pips filling toward the win, the round clock, the round number and FIRST TO 5.
- Big slanted banners call the round start, half time with the ends swapped, and who took the round or the match.
- The bottom right replica panel shows your BB count and the fire-mode chips (S, B, A), with the current one lit.
- Magazine boxes show the loaded one first, then the fullest spare.
- HOLSTERED, RELOADING, LAST MAG or OUT OF BBS appear when they apply.
- A low magazine turns yellow.

### HUD tab in Settings
- Settings has a HUD tab after Display, with a live preview of the crosshair as you change it.
- Crosshair: shape (cross, cross and dot, circle or dot), colour (white, green, yellow, cyan, pink or red), size, thickness, gap and opacity.
- Spread can be dynamic or static, and the crosshair can have an outline.
- Hit marker: on or off, with its own colour and size.
- Ammo counter: on or off. When off, no BB counts show, and each magazine box only shows whether it holds BBs.
- Hit feed: top right or bottom left, with each line fading after a few seconds or, on Keep, the last 10 hits staying up all match.
- HUD opacity sets how solid the navy panels are. Text stays solid.
- What got you (Auto, On or Off) lives here.
- Every choice saves with your settings and applies at once, in play and from the pause menu. The defaults keep the HUD as it was.

### HUD size and reduced motion
- Settings › HUD has a HUD size slider from 80 % to 150 %. The whole HUD grows or shrinks and keeps to the screen edges.
- The crosshair, hit marker and sound cue ring keep their size. Markers over teammates, the flag and the Hold here spot stay on what they mark.
- At large sizes the match summary is held smaller so it stays on screen. The HUD tab's preview shows the size, with dashed outlines at 100 %.
- Settings › Accessibility › Reduced motion is On, Off or Follow system, which follows your computer's reduce-motion setting.
- Reduced motion takes out the replica's sway and the wind dust, halves the kick and reload tilt, and softens lean and vault tilt to a quarter.
- Reduced motion holds the flag warning steady instead of pulsing. Recoil climb stays the same, so aiming feels the same.
- Both settings apply at once, even from the pause menu.

### Levels and unlocks
- You now have a level, from 1 to 10, shown in the top bar.
- Matches give XP: for playing, for winning, for each round you won and took part in, and for each hit.
- Shorter matches give less XP. Difficulty multiplies it: Easy is half, Hard is 1.5x, Pro is 2x.
- Levels unlock replicas, power sources and parts. Locked items stay listed on the Loadout and Customise, greyed out with "LEVEL n".
- Locked items can't be picked until you reach their level.
- A new player starts with the AEG, the pistol, the Standard battery and Green Gas.
- Records are kept: wins and losses per difficulty and mode, best accuracy and longest win streak, shown later on the Armory.
- Settings › Dev has "Disable levelling", which unlocks everything and gives no XP, and "Reset level".
- Progress and records save to their own files, so a crash won't lose them.

### Your loadout goes into the match
- Your loadout now carries into the match, so the replicas you set up are the ones you play with.
- The game keeps up to five named loadouts, with one carried into each match.
- Each replica can have its own BB weight (0.20 to 0.30 g), hop-up dial setting, colour and power source.
- A battery changes the AEG Rifle's rate of fire; gas changes the GBB Pistol's power and kick, capped at the field's chrono limit.
- New players start with the AEG Rifle and GBB Pistol, as before.
- Bots keep their replicas as they come.

### Loadout from the range
- On the practice range, press L (or pick Loadout in the pause menu) to open the Loadout on the replica in your hand. Swap or tune your replicas; the screen shows a FROM THE RANGE note.
- Press L again, Esc, or BACK TO PRACTICE to go straight back. You are where you stood, looking the same way, crouched or holstered as before, now with your new replica. A timed challenge run in progress is dropped; the timed challenge switch stays as it was.
- The first-shot readout shows "L Loadout · swap or tune your replica". The Loadout key can be rebound in Settings (LOADOUT (PRACTICE)); in a match it does nothing.
- The pause menu's rows are 2 px taller.

### Loadout and Customise screens
- The LOADOUT tab opens with your saved loadouts. Press keys 1 to 5 to pick one, then make a new one, rename, duplicate, replace or remove it.
- The LOADOUT tab also shows the two replicas you carry, and every replica you can carry.
- The Performance sheet compares your setup with the replica as it comes: better in green, worse in red.
- The Performance sheet says when the field's chrono limit capped the energy.
- CUSTOMISE changes one replica's colour: eight bold schemes, four plain ones, and a Realistic colours switch.
- CUSTOMISE sets its BB weight and hop-up, with a picture of the BB's flight, and its power source.
- Optics, grips and other parts show greyed out, as coming later.
- Replica pictures are drawn from the models in your colours, true to size with each other.
- Edits apply at once, with no Save button.

### Magazine gauges and the pistol's slide lock
- The replica panel shows a small gauge for each magazine you carry: the loaded one first, then your spares, fullest first.
- Each gauge fills by the BBs left in it. An empty magazine shows dark, so you can read them without colour.
- The loaded gauge turns orange when it runs low, like the BB count.
- The GBB Pistol's slide locks back when you fire its last BB and stays back while you reload.
- The slide closes as the new magazine seats, near the end of the reload. The AEG has no slide lock.

### Internal
- Each change now plays 16 bot-only matches on Depot, and fails on stalls, stuck or out-of-bounds bots, or bots knocking out teammates.

### Match screen with map cards
- The Match screen replaces the map list: pick a map from picture cards. Depot and Woodland are there.
- Woodland and the practice range are greyed out for now, and so are Attack / Defend and the other bot levels.
- Pick your team, ALPHA or BETA, and you really play as the team you pick, at its end.
- The rules show as chips: 3 v 3, first to 5, round time, ends swap and ricochets.
- Your picks stay while the game is open.
- PLAY shows a loading screen with the map's picture, name and a progress bar until the match is ready.
- The pause menu is restyled: PAUSED, the map, mode and round, RESUME, SETTINGS, QUIT MATCH and the match's seed.

### Match numbers are kept
- Each player's hits, times hit, BBs fired and time in play are now kept for every round and the whole match.
- Each hit also records where it came from, how far away it was, and whether the bot was holding the angle. Nothing new shows on screen yet.
- A round 1 draw that is played again no longer drops that round's hits and BBs from the match's XP and accuracy.

### The match summary
- The last round's table gives way to a match summary: a WON or LOST stamp in the winning team's colour, with the score, the map and the bots.
- On the left is every player's numbers for the whole match, as on Tab. The XP card stays in the middle.
- On the right are your records for this difficulty and mode. A new record gets a NEW RECORD tag, and a new best accuracy says what it was before.
- Accuracy now counts from 30 BBs fired. A match that doesn't count for the records says "Not counted this match" beside the heading.
- What got you lists the last five times you were hit, with the round, the shooter, their side and distance, and who got you most.
- The Pro tip shows the next one from Tab's cycle, against Pro bots. The score bar, hit feed and replica panel step aside.

### When the next match starts
- The next match starts 15 seconds after the summary appears, or at once when you click. That click never fires a shot.

### Internal
- Maps now read their named areas and storeys, and the minimap's numbers and colours sit in one tuning file, ready for the minimap.

### Internal
- Each map has a top-down layout per storey (walls, low cover, raised dock with a dark edge, darker lower floors), ready for the minimap. Nothing shows yet.

### Internal
- The game now remembers where your side last heard enemy steps, vaults and shots, ready for the minimap; nothing shows on screen yet.

### The minimap
- A minimap sits top left in a match: you are the white arrow and your teammates are dots in your team's colour, grey once hit.
- The field is drawn once a match.
- The other team shows only as patches where your side heard them: a dashed ring for footsteps, a disc for a shot, fading after a few seconds.
- The area you stand in is named at the panel's top left, and the map and round are under it.
- In Attack / Defend the pole shows while the round is live, and so does your Hold here spot as a diamond.
- Rotating (the default) turns the field so the way you look is up; Fixed keeps north up and turns your arrow. Settings › HUD › Minimap picks it.
- What got you moves down under the minimap's caption, and the flag marker pinned to the left edge sits under the minimap, never behind it, and Hold here's marker pinned to a side stacks under it the same way. The card hides while Tab is held, and a hit feed in the bottom left shows fewer lines while the card is up.
- Once you are out the minimap follows the teammate you watch.

### Sounds muffled through walls
- Shots, footsteps and other sounds from behind a wall sound duller and quieter. Behind a low barrier or round a corner they're only half muffled, so you can still tell where they are. A silenced shot behind a wall is quieter still.
- BBs hitting something on the far side of a wall sound muffled too.
- Your own sounds, your hit tick and the referee's whistles are never muffled. Once you're out and watching a teammate, you hear their sounds from where they stand.
- Bots hear through walls by the same rule as before, so how they play doesn't change.

### Order wheel and hold marker
- Hold Z and a wheel opens round the crosshair: Follow Me, Hold Here, Regroup and Team Plan, each with its key. The slice you point at lights yellow, and the order in force wears a blue band and an ACTIVE tag.
- An order that can't be given says so in the wheel's middle ("No teammates in play to order"): with the wheel open, or for two seconds in a see-through hub just after you pick on it, clear of your crosshair. There is no order text anywhere else; the radio click is the confirmation.
- Hold Here puts a "HOLD · 18 M" marker over the spot your squad holds, with a dashed ring on the floor. Turn away and it slides to the screen edge with an arrow, below the flag marker if both are there. A hold where each stood has no marker, and neither does a hold that has ended.
- Settings › Controls has a Squad orders section with Order wheel: Hover or Click.
- The four squad keys now list in the order Follow, Hold, Regroup, Wheel.

### Parts you can see
- The parts you pick on the Customise screen now show on the replica in your hands.
- Red dots, 2x scopes, grips, hi-cap and low-cap magazines, long barrels, silencers and the pistol laser all appear.
- The magazine moves with the reload, and menu pictures show the same parts.
- With an optic fitted the iron sights fold down, and aiming looks through the optic.
- The red dot is a lit dot on clear glass, with the view open round it.
- The 2x scope shows its body round the glass and magnifies only inside the glass; the view round it stays normal, with nothing dark round it.
- A silenced replica's shots sound muffled and quieter.
- A long barrel or silencer moves where BBs leave the replica out to its end.

### Practice from the Match screen
- The Match screen offers the Range as a map with a Practice mode. PRACTICE opens it.
- While Practice is picked, Team, Bots and Rules show NOT USED. Their settings are kept, and picking a field again brings back the mode you had.
- Your last BB's readout names its target and distance, where it landed, or that it flew out ("Aim lower, or turn the hop-up down"). There is no hit marker: steel rings and figures fall.
- Esc in practice opens a pause menu with a Timed challenge switch, remembered between launches. With it on, shoot the START plate for 3-2-1, GO!, then shows a bar with time and hits, then TIME! with hits, shots, misses and NEW BEST (or NOT KEPT when a developer setting was on). Your best is kept.
- Practice gives no XP and no match record. Leaving practice returns you to the Match page.

### Internal
- The practice range is built and playable, with steel plates, figures, movers and a timed challenge, but nothing in the menus reaches it yet.

### Pro bots
- Pick PRO on the Bots row of the Match screen.
- Pro bots are careful, not twitchier: they aim at the corners and doorways you would step out of.
- Step out right where they aim and they shoot back faster; from anywhere else they are no faster than Hard.
- Near your side they walk instead of run, check each corner ahead and lean out past it.
- When you duck out of a fight, they watch that spot for a moment before coming after you.
- Low on BBs with you nearby, they top up from cover.
- Easy, Normal and Hard play as before.

### Pro bots play as a team
- A Pro match pays double XP and counts for your records.
- When a teammate calls a hit, nearby Pro bots run to trade it, peeking from cover if there is some close by.
- A Pro bot that hears you tells its teammates where it heard you.
- Two Pro bots on one lane move in pairs, one covering while the other moves.
- A team that's behind with 30 seconds or less left stops holding and comes looking.

### Internal
- Practice range targets now exist in the rules: steel plates, figures, moving and pop-up targets in three lanes, 10 to 60 m. The range is drawn next.

### Replica colours
- Your replica wears the colours picked in your loadout, in your hands.
- Bots hold their replicas too: Alpha's rifle is Cobalt and its pistol Onyx, Beta's rifle is Signal and its pistol Coral.
- The Cyber Pistol keeps its own colours.
- Realistic colours shows every bold scheme as its plain colour, yours and the bots', from the next match.

### Report a bug
- Report a Bug on the title screen and in the pause menu opens a panel where you can add a note of up to 500 characters.
- Report on GitHub copies the whole report and opens a new public GitHub issue with it filled in. Nothing is sent until you press Submit there.
- Copy report copies the whole report, so you can paste it anywhere else.
- Back, or Esc, closes the panel.
- The pause menu shows how many errors have happened in this match.

### Restore points for your save
- The game keeps up to three restore points of your save, at most one a day. A point is taken at start-up when the save has changed.
- The groundwork is in for Restore, Undo and "Delete and start over". If any part of one of these fails, everything is put back as it was.
- A damaged save file is set aside, never destroyed.
- A save from a newer version of the game is never overwritten.
- The screen to use restore points, the Save file tab, comes next.

### Every bot is a rigged figure
- Every bot now has a rigged human body, not a capsule stand-in.
- The Dev › Rigged figures setting is gone; old saves that still hold it load fine.
- Bot models load behind the loading screen, and every figure material is drawn once in the match's first frames to cut the hitch when a bot first appears.

### Rigged figures hold their replicas
- With Rigged figures on in Settings › Dev, the figures now hold their replica in their hands.
- They aim it up and down where they look, and show a trigger press on every shot.
- They swap between rifle and pistol, the replica changing hands mid-motion.
- Holstered figures sling the rifle across the chest or back, and draw it back off the back.
- A figure calling a hit lifts its left hand and lets the rifle hang from the other, muzzle forward.
- Known: a holstered figure that vaults uses the vault's arms.
- Known: swapping between two replicas of the same kind plays the rifle-to-pistol motion.

### Rigged figures move
- With Rigged figures on in Settings › Dev, the figures now move their legs as they walk, run and sprint, and they step backwards too.
- They crouch and crouch-walk, jump and vault.
- A hit figure raises a hand to call the hit, then walks off with the hand still up.
- At corners, the upper body leans just as far as a shot could hit it, and the same way.
- Figures far away are animated less often, to save time.
- Known: at a run and a sprint, the feet slide a little.

### Rigged figures reload
- With Rigged figures on in Settings › Dev, the figures now reload their replicas.
- The left hand pulls the old magazine out and throws it aside, then brings the new one to the replica.
- Thrown magazines arc through the air, land on their side at the figure's feet and vanish after 3 seconds.
- At most 12 thrown magazines lie on the field at once; the oldest goes first.
- A figure hit mid-reload stops at once and throws nothing more.
- Thrown magazines clear at each new round.
- Known: the replica's own magazine never hides yet, so the new one seems to jump into place at the end.

### Rigged figures
- Settings › Dev has a new Rigged figures switch. It is off by default, so nothing changes until you turn it on.
- With it on, bots and other players are drawn as rigged human models instead of plain capsules. They stand still for now.
- Team colours show on each figure's plate carrier.
- Each human has one of four heads.
- Figures far away are drawn with less detail.

### Round result and the round's table
- When a round ends, the big banner says WON, LOST or DRAW from your side, in the winning team's colour (white for a draw).
- Under it, "ROUND 4 · ALPHA TAKE THE ROUND" says who took the round. On Attack / Defend it also says how: "FLAG RAISED" or "DEFENDED · TIME'S UP".
- Two seconds later the round's table slides in under the banner.
- Each team shows its score. Your team comes first, and you come first on your team.
- Each player shows hits, BBs fired, time in play and who hit them; "Still in" shows in green if nobody did.
- Players who are out get an OUT tag with a raised hand.
- The table stays until the next round starts. Click to start the next round sooner; that click never fires a shot.
- After the match's last round the table says CLICK FOR THE RESULTS; the match's XP and the next match wait 4 seconds or until you click.
- The match's last round keeps its "ALPHA WIN THE MATCH" banner.

### The game remembers how each run ended
- The game now notes whether it closed cleanly, and what you were playing: the map, the mode, the match seed and the round.
- It keeps the last errors and warnings of each run, and can read the end of the last run's log.
- In exported builds, a crash message now asks you to start the game again to report the bug.
- A second copy of the game started beside a running one leaves the first one's record alone.
- The crash screen and Report a Bug will use all of this, coming next.

### Safe graphics
- If your graphics card or driver lacks Vulkan or Direct3D 12, the game switches to a simpler renderer on its own and says so once on the title screen.
- Settings › Graphics › Start-up › Renderer lets you pick Auto or Compatibility, taking effect from the next start.
- Graphics choices the simpler renderer can't draw are greyed out, with the reason shown.
- If the game closed while drawing its graphics, the next start restarts once on the simpler renderer and Low, then asks: Keep safe graphics or Try my settings again.
- The Windows installer adds an "Airsoft (safe graphics)" shortcut that starts the game on the simpler renderer.

### Models, sounds and maps from the browser game
- The AEG rifle, GBB Pistol and Cyber Pistol, their attachments, the batteries and gas bottle, and the human and robot figures with all their moves are now in the Godot project, ready to be drawn.
- Every sound from the browser game (shots, reloads, footsteps, impacts, the hit tick and the ambience of each field) is now a sound file in the game.
- Depot, Woodland and the practice range are in as map layouts, ready to be built.
- The Inter font is in for the menus and HUD; Credits now lists its licence.

### Save file tab
- Settings has a new Save file tab for your save, your save folder and your restore points.
- Your save is saved automatically. The tab shows when it last saved, and your level, XP, items unlocked, matches, saved loadouts and version.
- Save folder shows the folder's path, with an Open folder button.
- Restore points keep up to three days, each with a Restore button.
- Undo takes back a restore or a delete.
- Delete and start over clears your save. Undo can bring it back.
- Restore, Undo and Delete ask first, showing what you have now beside what comes back. Then the game restarts.
- From the pause menu these are greyed out. Leave the match to use them.
- Dev › Reset the save is gone; Delete and start over (with Undo) replaces it.

### Scoreboard on Tab
- Hold Tab in a match to see the scoreboard over the field; the match keeps playing.
- The top line names the map, the mode, the bots' level and the size, such as "ELIMINATION · PRO BOTS · 3 V 3".
- The round and its time left sit beside it; in Attack / Defend overtime the clock counts the overtime down.
- Each team shows its score and how many of its players are still in play. Your team comes first, and you come first on it, in yellow.
- Each player shows this round's hits, then the match's hits, times hit, BBs fired, accuracy (hits per BB) and time in play.
- Players out this round are greyed out, with an OUT tag and a raised hand.
- Against Pro bots, a Pro tip sits under the table, and a new one shows each round.
- Teammate markers hide while Tab is held.
- Tab can be rebound on the Controls screen (Scoreboard).
- Pausing hides the board.

### Screen reader messages
- Settings › Accessibility › Screen reader messages is on by default. A screen reader such as NVDA on Windows or Orca on Linux reads out the match.
- Hit calls from the hit feed are read, such as "Rook called HIT · You", and so is your own hit: "You're hit · Rook".
- Each round's start is read, such as "Round 2 · Attack · Take the flag", half time included. Each round's end gives the winner, why and the score.
- The match result is read at the end. Lines that come close together are read as one message.
- Your hit and the match result interrupt; the rest wait their turn. Nothing new shows on screen.
- Off, nothing is read. The setting applies at once, even from the pause menu. Squad orders and the menus are not read yet.

### Settings screen
- Open Settings from the title screen or the pause menu, which now reads Resume, Settings and Leave.
- Controls: hip and aimed sensitivity, and sensitivity as cm per 360 turn at your mouse DPI.
- Invert vertical look, and set crouch and aim to hold (the default) or toggle.
- Two keys per action, named on your own keyboard layout. Taking a key already in use swaps the two.
- Fire and the move keys can never be left without a key.
- Audio: master, effects, power source (the motor or gas part of a shot), ambience and interface volumes.
- Display: window mode (windowed, borderless fullscreen or fullscreen), V-Sync, field of view and a Show FPS counter.
- Every change applies at once and is saved. A damaged settings file falls back to the defaults, with a message.
- The "Space to vault" prompt names whatever key Jump is bound to.

### Pause menu in the middle
- The pause menu now sits in the middle of the screen, not the top-left corner.

### The game's rules, underneath
- BBs fly with drag, gravity and hop-up lift: the AEG Rifle stays on target to about 38 m, the GBB Pistol to about 26 m.
- One hit and you're out: hand up, then a walk off to the dead zone, unable to shoot or be hit.
- Elimination rounds against the clock, first to 5, ends swapped at half time.
- The AEG Rifle and GBB Pistol fire, reload and handle by their stats in `data/stats.md`.
- Nothing is drawn or playable yet: the next build puts it on Depot.

### Sound cues
- Settings › Accessibility › Sound cues (off by default) shows the sounds you hear as markers on a ring round the crosshair.
- The other team's footsteps and vaults show as two dots, shots as an arrowhead pointing out, and hit calls as a HIT tag.
- The ring turns with your view. Nearer sounds are stronger and far ones fainter; a silenced replica is heard half as far.
- Your own sounds and your teammates' steps show nothing; teammates' shots and hit calls do.
- Markers fade after about a second and a half, and a new round clears them.
- Pick the markers' colour and size. The Accessibility tab shows a live sample and a key of the three icons.
- Turning it off hides the ring at once, even mid-match.

### Sound mix
- When you're hit, the field's sound dips hard, then stays muffled and quieter until the next round, even while you watch a teammate.
- Your own hit tick stays crisp.
- Round and match ends dip the field gently for the whistle.
- Busy fights stay readable: each sound has a limited number of voices.
- Other players' footsteps are heard within 22 m, and field sounds within 60 m.
- Repeated sounds vary a little in level and never play the same variant twice running.

### Internal
- Follow me and Regroup now steer bots in the rules.

### Squad orders on the keys
- F tells your bot teammates to follow you, X to hold here, and V to regroup.
- You hear a radio click when your team takes one of your orders. An order nobody takes is silent.
- Hold Z to aim the order wheel with the mouse instead of turning your view. The wheel isn't drawn yet, so for now holding Z only freezes your view.
- The four SQUAD rows in Settings › Controls can be rebound, including the order wheel key.

### Internal
- Squad orders (Hold here, Follow me, Regroup, back to the team plan) now exist in the rules.

### Team colour sets
- Settings › Accessibility has Team colours: Standard, or High contrast with light blue and dark orange, checked for colour blindness.
- High contrast covers the figures, the flag and the whole HUD. Its figures glow faintly in daylight.
- A new set shows from your next match. The Match page and HUD previews change at once.
- Numbers on light team blocks turn dark, so they stay readable.
- Plywood crates and racks are a duller tan, and the mustard generator, skip and container more yellow, so no prop reads as Beta.

### Internal
- The practice range's timed challenge now has its rules and a best per range, ready to be drawn next. Nothing to play yet.

### New title screen and menus
- A new title screen shows the AIRSOFT wordmark and "Call your hit. Go again." over a blurred view of Depot.
- A big yellow START opens the menus. The version, Licences and Quit sit in the bottom right corner.
- A top bar holds Match, Loadout and Armory (greyed out, marked LATER), Settings, and your level chip, which reads LVL 1.
- The menus, Settings and the credits share one look: navy panels, yellow for the main button and the selected item, and capital headings.
- Main buttons are slanted. The menus grow with a big window, up to 1.5 times the size at 4K.
- Enter starts the game from the title screen, and still works after you close the licences.

### What got you
- When your hit is called, a card on the left shows the shooter's name and side, how far away they were and a dial of the shot's line.
- The card also says whether they held the angle, how long you were in their view and whether you were moving, when known, then that bot's personality note.
- The HUD tab has a What got you setting: Auto, On or Off. Auto shows the card only against Pro bots.
- The card goes when the next round starts. Your hit line stays framed in the feed until then.

### Skip the rest of the round
- Once you're out, hold Jump (Space by default) for half a second and the rest of the round plays at six times speed, with the HUD hidden.
- A hint at the bottom reads "Hold Space to skip the round", using whatever key Jump is bound to. Holding it through the hit or a pause does not count.
- The round's table shows as usual when the round ends.
- The pause menu's Skip to next round shows while you can skip.

### Internal
- The referee's whistle now has short and long blasts. Each map names its background sounds (yard, woods, city; day and night); nothing plays them yet.

### Window modes, monitors and frame rate
- Settings › Display has Windowed, Borderless fullscreen and Exclusive fullscreen. The game opens in the mode you left.
- F11 and Alt+Enter switch between Windowed and your last fullscreen mode. Exclusive keeps your desktop resolution.
- With two screens or more, the Monitor row picks the screen the window opens on.
- V-Sync is on by default. Frame rate can be left Unlimited or capped from 30 to 360 a second.
- In the background the game drops to 30 frames a second, so a match on a second screen stays watchable.
