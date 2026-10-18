# game/play

A match, played: `PlaySession` builds the level, steps the simulation once a physics tick with the player's command
and hands the tick's events on; everything else here draws the state every rendered frame, between the last two ticks
(docs/ARCHITECTURE.md › Contracts 1 and 3). Nothing here writes simulation state.

| File | What |
|---|---|
| `play_session.gd` | `PlaySession`: the map, the simulation, the views; Esc and focus loss pause; `left` back to the title; the smoke test's autopilot |
| `first_person_view.gd` | `FirstPersonView`: the camera at the eye, turned by the mouse every frame, lifted by recoil, zoomed by the sight |
| `replica_view.gd` | `ReplicaView`: the replica in hand from its model: hip and sights, draw, sprint carry, reload cant and clip, kick, sway, pulled back from walls |
| `bb_view.gd`, `puff_view.gd` | BBs in the air and the puffs where they land, each one MultiMesh |
| `figure_view.gd` | `FigureView`: another player as a greybox figure in its team colour, arm up and "HIT!" while calling a hit |
| `sim_audio.gd` | `SimAudio`: every sound from the events, positional for others, plain for you, on the bus layout `default_bus_layout.tres` |
| `field_lighting.gd` | `FieldLighting`: the sun, the sky and the environment |

Until bots come, you play Alpha alone against a team of stand-ins: Beta characters with no controller, who wait at
their end and call their hits. Tuning: `PlayTuning` (`game/config/play_tuning.tres`). Tests:
`tests/unit/test_play_session.gd`.
