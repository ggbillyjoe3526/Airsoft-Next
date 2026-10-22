# game/config

Every tuning value the game reads, as typed `Resource` scripts (docs/ARCHITECTURE.md › Contracts 6). Each script's
defaults are the values ported from the browser game, where they were tuned by play; its `##` comments say what each
does and why it is what it is. `sim_tuning.tres` is the instance the game loads (`SimTuning.load_default()`), so a value
changed in the inspector is saved there. The play screen's own tuning (how the game looks, sounds and handles, never its
rules) is `play_tuning.tres` (`PlayTuning.load_default()`), the same way.

| Script | Area |
|---|---|
| `sim_tuning.gd` | Bundles the simulation's configs below |
| `ballistics_config.gd` | BB flight: air, BB size, hop-up spin, lift, spin decay, lifetime, pool size |
| `movement_config.gd`, `accuracy_config.gd`, `body_config.gd` | Paces (the holstered run too), jump, crouch, aiming pace, lean speed and wall clearance; spread by stance and motion; the body's size |
| `vault_config.gd` | Vaulting: the heights and depth vaulted, reach, the path's speed and tuck, the fire lockout after |
| `hit_config.gd` | Hit calling, friendly fire and whether ricochets count, the walk-off, the hit volume (head, chest, hips, legs) and the lean's pivot and tilt |
| `wind_config.gd` | The match's breeze: its speed range, gusts and veer |
| `ricochet_config.gd` | BBs bouncing off hard surfaces: restitution by material, slide, scatter, the most bounces |
| `round_config.gd` | Rounds: clock, score, half time, reset |
| `flag_config.gd` | Attack / Defend's flag: reach, raise and lower times, overtime, rope steps |
| `footstep_config.gd` | Strides and landings |
| `nav_config.gd` | The nav grid: cell size, clearance margin, snapping, the search's greed, line sampling |
| `replica_rules_config.gd` | Recoil recovery, the trigger, BB weight, the hop-up dial's range and notch, the draw from the holster |
| `replica_config.gd`, `replicas/*.tres` | One replica's stats, the built-in values; `data/stats.md` wins over them |
| `replica_stats.gd`, `data_table.gd` | Read `data/stats.md`'s tables, the power sources too (a cell that won't read keeps the built-in value and warns) |
| `bots_file.gd` | Read `data/bots.md`: the bots' roster of names and what each personality changes (a cell that won't read plays neutral and warns) |
| `part_stats.gd` | Read `data/stats.md`'s part tables: optics, grips, lasers, magazines, barrels and muzzle parts (a part with no row changes nothing) |
| `replica_schemes.gd` | Replica colours: the eight bold schemes and four plain colours, each class's default, the bots' team colours, Realistic colours |
| `play_tuning.gd`, `play_tuning.tres` | Bundles the play screen's configs below, and the rematch delay |
| `controls_config.gd` | Mouse turn, sensitivity (hip, and a multiplier aimed), invert, slower while zoomed, crouch and aim toggle or hold; the settings screen writes its values over these |
| `view_config.gd` | Field of view, the sight's zoom, near and far, the view's roll in a lean, a cut lean's easing, a vault's dip and tip |
| `viewmodel_config.gd` | The replica in hand: hip and sight positions, sway, kick, sprint carry, draw, the holster, reload cant, wall pull-back, each optic's glass and eye distance |
| `effects_config.gd` | BB size and colour, the muzzle blend, puffs by surface, the wind dust |
| `sound_config.gd` | Cue and loop folders, gains, distances, voice pools, the ambience, a silenced shot's muffling, the flag rope's ratchet |
| `debug_view_config.gd` | The F4/F5 debug draw: a BB trail's length and colours, the hit volumes' colours and roundness |
| `hud_config.gd` | the low-magazine share, the magazine boxes' sizes, the crosshair, the hit marker, banner times, the hop-up readout, the vault prompt, the flag marker and warning |
| `map_style.gd` | A map's greybox: colours and surface by block kind, the ground, the world grid |
| `lighting_config.gd` | The sun, the sky, ambient light, SSAO and exposure |
| `flag_view_config.gd` | Attack / Defend's pole in the world: pole, base, rope, cleat, the flag cloth's size, travel and wave, the reach ring's colours |
| `team_config.gd` | Team names (translation keys) and colours |
| `bot_config.gd`, `bot_tuning.tres` | How bots play (`BotConfig.load_default()`): senses, aim, firing, lanes and holds, routes, cover, searching, hunting, the holster |
| `bot_skill.gd` | How well a bot plays: reaction, turn rate, aim error and settling, lead, bursts, holds (Normal only for now) |
