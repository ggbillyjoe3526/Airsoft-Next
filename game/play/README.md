# game/play

A match, played: `PlaySession` builds the level, steps the simulation once a physics tick with the player's command
and hands the tick's events on; everything else here draws the state every rendered frame, between the last two ticks
(docs/ARCHITECTURE.md › Contracts 1 and 3). Nothing here writes simulation state.

| File | What |
|---|---|
| `play_session.gd` | `PlaySession`: the map, the simulation, the views; Esc and focus loss pause; `left` back to the title; the smoke test's autopilot |
| `first_person_view.gd` | `FirstPersonView`: the camera at the leaned eye (`Lean.offset`), rolled a little in a lean and eased out of one a wall cuts short, dipped and tipped over a vault, turned by the mouse every frame, lifted by recoil, zoomed by the sight |
| `replica_view.gd` | `ReplicaView`: the replica in hand from its model: hip and sights, draw, the holster, sprint carry, reload cant and clip, kick, sway, pulled back from walls, a gas pistol's slide locked back on empty |
| `bb_view.gd`, `puff_view.gd` | BBs in the air and the puffs where they land, each one MultiMesh |
| `figure_view.gd` | `FigureView`: another player as a greybox figure in its team colour (legs, and a torso, head and arm that tilt about the hip pivot in a lean), arm up and "HIT!" while calling a hit |
| `sim_audio.gd` | `SimAudio`: every sound from the events (a vault's hands and kit too), positional for others, plain for you, on the bus layout `default_bus_layout.tres` (Effects, with Footsteps and the shot's Power part under it, Ambience and Interface; each has a volume in Settings) |
| `wind_dust.gd` | `WindDust`: specks of dust round the eye drifting with the match's breeze, one GPU particle box |
| `field_lighting.gd` | `FieldLighting`: the sun, the sky and the environment |
| `tick_pacer.gd` | `TickPacer`: how many fixed ticks each physics tick runs at the Dev settings' game speed (or the smoke test's speed-up), and the drawing fraction between them |
| `spectate.gd` | `Spectate`: the next bot in play Spectate any bot follows |
| `bot_intent_view.gd` | `BotIntentView`: the Dev settings' Bot intentions, a label over each bot saying what it is doing |
| `retro_pixels.gd`, `retro_pixels.gdshader` | `RetroPixels`: the Dev settings' Retro pixels, a full-screen filter under the HUD |
| `shader_prewarm.gd` | `ShaderPrewarm`: draws the late materials (a fading figure, a BB, a puff, the sign) as specks for the first frames, so nothing compiles mid-match |

Until bots come, you play Alpha alone against a team of stand-ins: Beta characters with no controller, who wait at
their end and call their hits. Tuning: `PlayTuning` (`game/config/play_tuning.tres`). Tests:
`tests/unit/test_play_session.gd`.
