# game/play

A match, played: `PlaySession` builds the level, steps the simulation once a physics tick with the player's command
and hands the tick's events on; everything else here draws the state every rendered frame, between the last two ticks
(docs/ARCHITECTURE.md › Contracts 1 and 3). Nothing here writes simulation state.

| File | What |
|---|---|
| `play_session.gd` | `PlaySession`: the map, the simulation, the views, built in four steps (map, level, teams, views; one a frame while `staged`, reported by `progressed` for the loading screen, then `started` once drawn); you play `player_team` (Alpha or Beta); Esc and focus loss pause (the pause menu names the map, mode, round and seed); `left` back to the title; the smoke test's autopilot; a counted match's XP goes to the HUD (`Hud.show_xp`) when it is settled |
| `first_person_view.gd` | `FirstPersonView`: the camera at the leaned eye (`Lean.offset`), rolled a little in a lean and eased out of one a wall cuts short, dipped and tipped over a vault, turned by the mouse every frame, lifted by recoil, zoomed by the sight |
| `replica_view.gd` | `ReplicaView`: the replica in hand from its model: hip and sights, draw, the holster, sprint carry, reload cant and clip, kick, sway, pulled back from walls, a gas pistol's slide locked back on empty, the fire selector at its mode (`SelectorPose`), in the Kit's paint for its slot, with its parts; aimed along an optic's sight line |
| `replica_parts.gd`, `sight_fold.gd` | `ReplicaParts`: a replica's parts fitted from their models (`assets/models/replicaParts/`), the one way the hands, the figures and the menu pictures do it: the standard magazine or flash hider replaced, a longer barrel carrying the muzzle out, the iron sights folded under an optic (`SightFold`, held over the clips in hand) |
| `optic_glass.gd`, `optic_glass.gdshader` | `OpticGlass`: the red dot's and the scope's glass in hand, the view through it drawn by a second camera without your replica (the scope's magnified, only inside its glass), with the lit dot or the reticle; draws only while a sight is raised |
| `bb_view.gd`, `puff_view.gd` | BBs in the air and the puffs where they land, each one MultiMesh |
| `flag_view.gd`, `flag_cloth.gdshader` | `FlagView`: Attack / Defend's pole at the map's flag spot, visual only (no collider): the flag climbing the rope with the progress in the attackers' colour, waving in a shader, and the reach ring coloured by who works the rope (white idle, attackers raising, defenders lowering, yellow contested) |
| `figure_view.gd` | `FigureView`: another player as a greybox figure in its team colour (legs, and a torso, head and arm that tilt about the hip pivot in a lean), holding the replica it has out in its team's paint with its parts' figure copies, arm up and "HIT!" while calling a hit |
| `replica_paint.gd` | `ReplicaPaint`: a `ReplicaSchemes` paint put on a replica model's Body, Furniture, Detail, Accent and Metal surfaces (the Cyber Pistol keeps its own, plain grey with no glow under Realistic colours); one shared material set per paint, built once; the paint a bot wears by team |
| `selector_pose.gd` | `SelectorPose`: holds a replica model's fire selector where its Selector clip puts the fire mode, over whichever clip plays (a skeleton modifier) |
| `sim_audio.gd` | `SimAudio`: every sound from the events (a replica's by its sound profile: its power's, or its own, the Cyber Pistol's) (a vault's hands and kit too), positional for others, plain for you, on the bus layout `default_bus_layout.tres` (Effects, with Footsteps, the shot's Power part and Muffled (a silenced shot, low-passed) under it, Ambience and Interface; each but Muffled has a volume in Settings) |
| `wind_dust.gd` | `WindDust`: specks of dust round the eye drifting with the match's breeze, one GPU particle box |
| `field_lighting.gd` | `FieldLighting`: the sun, the sky and the environment |
| `tick_pacer.gd` | `TickPacer`: how many fixed ticks each physics tick runs at the Dev settings' game speed (or the smoke test's speed-up), and the drawing fraction between them |
| `spectate.gd` | `Spectate`: the next bot in play Spectate any bot follows |
| `bot_intent_view.gd` | `BotIntentView`: the Dev settings' Bot intentions, a label over each bot saying what it is doing |
| `retro_pixels.gd`, `retro_pixels.gdshader` | `RetroPixels`: the Dev settings' Retro pixels, a full-screen filter under the HUD |
| `shader_prewarm.gd` | `ShaderPrewarm`: draws the late materials (a fading figure, a BB, a puff, the sign) as specks for the first frames, so nothing compiles mid-match |

You play the team the Match page picked (Alpha by default) with bot teammates against bots on the other. Tuning: `PlayTuning` (`game/config/play_tuning.tres`). Tests:
`tests/unit/test_play_session.gd`.
