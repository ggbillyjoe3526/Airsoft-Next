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
| `movement_config.gd`, `accuracy_config.gd`, `body_config.gd` | Paces, jump, crouch, aiming pace; spread by stance and motion; the body's size |
| `hit_config.gd` | Hit calling, the walk-off and the hit volume (head, chest, hips, legs) |
| `round_config.gd` | Elimination rounds: clock, score, half time, reset |
| `footstep_config.gd` | Strides and landings |
| `replica_rules_config.gd` | Recoil recovery, the trigger, BB weight and the hop-up dial's range |
| `replica_config.gd`, `replicas/*.tres` | One replica's stats, the built-in values; `data/stats.md` wins over them |
| `replica_stats.gd`, `data_table.gd` | Read `data/stats.md`'s tables (a cell that won't read keeps the built-in value and warns) |
| `play_tuning.gd`, `play_tuning.tres` | Bundles the play screen's configs below, and the rematch delay |
| `controls_config.gd` | Mouse turn, sensitivity, invert, slower while zoomed, crouch toggle or hold |
| `view_config.gd` | Field of view, the sight's zoom, near and far |
| `viewmodel_config.gd` | The replica in hand: hip and sight positions, sway, kick, sprint carry, draw, reload cant, wall pull-back |
| `effects_config.gd` | BB size and colour, the muzzle blend, puffs by surface |
| `sound_config.gd` | Cue and loop folders, gains, distances, voice pools, the ambience |
| `hud_config.gd` | HUD colours, the low-magazine share, the crosshair, the hit marker, banner times |
| `map_style.gd` | A map's greybox: colours and surface by block kind, the ground, the world grid |
| `lighting_config.gd` | The sun, the sky, ambient light, SSAO and exposure |
| `team_config.gd` | Team names (translation keys) and colours |
| `bot_config.gd`, `bot_tuning.tres` | How bots play (`BotConfig.load_default()`): senses, aim, firing, lanes and holds, routes, cover, searching, hunting |
| `bot_skill.gd` | How well a bot plays: reaction, turn rate, aim error and settling, lead, bursts, holds (Normal only for now) |
