# game/config

Every tuning value the game reads, as typed `Resource` scripts (docs/ARCHITECTURE.md › Contracts 6). Each script's
defaults are the values ported from the browser game, where they were tuned by play; its `##` comments say what each
does and why it is what it is. `sim_tuning.tres` is the instance the game loads (`SimTuning.load_default()`), so a value
changed in the inspector is saved there. The play screen's own tuning (how the game looks, sounds and handles, never its
rules) is `play_tuning.tres` (`PlayTuning.load_default()`), the same way.

A config added to `SimTuning`, `PlayTuning` or `BotConfig` must also be written into its .tres (open and save it in the
editor): an export converts the .tres where the scripts' `= Config.new()` defaults don't run, so a config the file
leaves out ships as null and the exported game crashes. `tests/unit/test_saved_configs.gd` fails until it is.

| Script | Area |
|---|---|
| `sim_tuning.gd` | Bundles the simulation's configs below |
| `ballistics_config.gd` | BB flight: air, BB size, hop-up spin, lift, spin decay, lifetime, pool size; leaves (the depth that stops a BB, the speed kept and the scatter a metre) |
| `movement_config.gd`, `accuracy_config.gd`, `body_config.gd` | Paces (the holstered run too), jump, crouch, aiming pace, lean speed and wall clearance; spread by stance and motion; the body's size |
| `vault_config.gd` | Vaulting: the heights and depth vaulted, reach, the path's speed and tuck, the fire lockout after |
| `hit_config.gd` | Hit calling, friendly fire and whether ricochets count, the walk-off, the hit volume (head, chest, hips, legs) and the lean's pivot and tilt |
| `wind_config.gd` | The match's breeze: its speed range, gusts and veer |
| `ricochet_config.gd` | BBs bouncing off hard surfaces: restitution by material, slide, scatter, the most bounces |
| `round_config.gd` | Rounds: clock, score, half time, reset |
| `range_config.gd` | The practice range's targets: plate and post sizes, a figure's time down and rise, pop-ups', movers' and swingers' timing, the range's marked distances and size (the targets' layout is `data/maps/range.json`); practice on a field (`field_`, WL9): where targets stand and of what kind, the START plate's search, the challenge's sight reach |
| `flag_config.gd` | Attack / Defend's flag: reach, raise and lower times, overtime, rope steps |
| `footstep_config.gd` | Strides and landings |
| `noise_config.gd` | Noisy props and loud ground (NP1): which block kinds knock and ring, how far each carries, the knock's speed, touch and facing, the quiet time, the ring's speed and margin, how far steps carry on each ground |
| `nav_config.gd` | The nav grid: cell size, clearance margin, snapping, the search's greed, line sampling |
| `replica_rules_config.gd` | Recoil recovery, the trigger, BB weight, the hop-up dial's range and notch, the draw from the holster |
| `replica_config.gd`, `replicas/*.tres` | One replica's stats, the built-in values; `data/stats.md` wins over them |
| `replica_stats.gd`, `data_table.gd` | Read `data/stats.md`'s tables, the power sources too (a cell that won't read keeps the built-in value and warns) |
| `bots_file.gd` | Read `data/bots.md`: the bots' roster of names and what each personality changes (a cell that won't read plays neutral and warns) |
| `part_stats.gd` | Read `data/stats.md`'s part tables: optics, grips, lasers, magazines, barrels and muzzle parts (a part with no row changes nothing) |
| `replica_schemes.gd` | Replica colours: the eight bold schemes and four plain colours, each class's default, the bots' team colours, Realistic colours |
| `play_tuning.gd`, `play_tuning.tres` | Bundles the play screen's configs below, and the rematch delay |
| `controls_config.gd` | Mouse turn, sensitivity (hip, and a multiplier aimed), invert, slower while zoomed, crouch and aim toggle or hold; the order wheel's orders, keys, names, pointer and Hover or Click; the settings screen writes its values over these |
| `view_config.gd` | Field of view, the sight's zoom, near and far, the view's roll in a lean, a cut lean's easing, a vault's dip and tip |
| `viewmodel_config.gd` | The replica in hand: hip and sight positions, sway, kick, sprint carry, draw, the holster, reload cant, wall pull-back, each optic's glass and eye distance |
| `effects_config.gd` | BB size and colour, the muzzle blend, puffs by surface, a noisy prop's knock puff, a bush's green puff and leaves, the wind dust |
| `sound_config.gd` | Cue and loop folders, gains, pitch and level spreads, distances and reaches, others' steps' and impacts' start limits, voice pools and voices per cue, the field's mix (out of play and the dips), the occlusion numbers (rays, corners, levels, surface gap, reach, far ramp, refresh, ray budget), kit rustle (levels, reach and start limit), landings (how hard a landing must come down to sound hard, its level and pitch then, your own landing's level), the ambience, the referee's whistle (its sound as tools/render_whistle.gd renders it, its level and blast pattern), a silenced shot's muffling, the flag rope's ratchet, the range's steel and how far targets are heard, the challenge's beeps, the squad order radio click, a noisy prop's knock (level, spreads, reach) |
| `ambience_config.gd`, `ambience_set.gd`, `ambience_bed.gd`, `ambience_call.gd` | Each field's ambience (part of `sound_config.gd`): for the yard, the woods and the city a day and a night set of beds (loop, gain, width, the second copy's offset) and calls (cue, level, pitch spread, gaps, distances, height, seed); the yard for a map naming none or an unknown one |
| `debug_view_config.gd` | The F4/F5 debug draw: a BB trail's length and colours, the hit volumes' colours and roundness |
| `report_config.gd`, `report_config.tres` | The bug report (`game/report/`): the issue address and its 8,000-character limit, the cut steps, the note and title lengths, the lists' lengths, the burst ticks, the frame window and hitch threshold, the log lines, the shortest name taken out, the teams' names (loaded on its own, `ReportConfig.load_default()`) |
| `hud_config.gd` | the low-magazine share, the magazine boxes' sizes, the crosshair, the hit marker, banner times, the hop-up readout, the vault prompt, the flag marker and warning |
| `map_style.gd` | A map's greybox: colours and surface by block kind, the ground, the world grid |
| `graphics_table.gd`, `graphics_quality.gd` | Read `data/graphics.md`: the graphics presets (Low to Ultra), each row's label, choices or range, cost and the renderers that draw it; one set of values a field per row, a preset's or Custom's (a preset with your own rows over it) |
| `graphics_pick.gd` | The first start's preset from the graphics card and the renderer (never Ultra), and the `--graphics=` launch option |
| `display_config.gd` | The window: the frames a second drawn in the background (30), and the keys that switch between a window and fullscreen (F11, Alt+Enter); the automatic graphics step-down's numbers (FrameWatch: 2 s windows, 20 ms or 1.25 frames of the limit, a 5 % slow share, 2 windows, the HUD line's 5 s) |
| `lighting_config.gd`, `night_lighting.tres` | The sun, the sky, ambient light, SSAO and exposure, and whether the preset is night (no glow on team paint); by night the haze, stars and moon, the light pools, and a map's `lighting.overrides` (`LightingConfig.for_map`). The day preset is in `play_tuning.tres`, the night one in `night_lighting.tres` |
| `bake_config.gd` | The baked light (`BakeConfig` on PlayTuning): the bake's tile size, rays, reach, lift, open-ground height and sun reach (in each bake's hash: a change asks for a rebake), and the look's sky share and bounce strength (free to tune) |
| `skyline_config.gd` | The skyline round a field (`SkylineConfig` on PlayTuning): the fade toward the horizon, the sight check's raised floors, each kind's colours (site colours and greys) and proportions, the treelines, and the chimneys' smoke |
| `woods_config.gd` | A wood's dressing (`WoodsConfig` on PlayTuning, WL4): the crowns, the forest beyond the fence, grass tufts, puddles and mud, leaf drifts, fallen wood, moss, the night air and the bushes' placeholder look, with each Mesh detail step's share |
| `figure_config.gd` | The rigged figures (`FigureConfig` on PlayTuning): the files and kinds, the human's four heads, the levels' lines on each Mesh detail and their margin, the shadow twin's level, the team paint's prefix, the model's turn, the Idle clip, the bones read, the robot mix and its salt |
| `flag_view_config.gd` | Attack / Defend's pole in the world: pole, base, rope, cleat, the flag cloth's size, travel and wave, the reach ring's colours |
| `range_view_config.gd` | The practice range drawn: plate, post, figure and gear paint and sizes, a hit plate's swing, a figure's fall, the challenge's lit glow and START plate, the floor lines and wall boards |
| `minimap_config.gd` | The minimap: the panel's size, ring and caption room, what sits under it, the pinned markers' steps, the markers' sizes and the patches' look, how far it shows, the field drawing's scale, rules and colours, how far each sound places an enemy and how their patches blur, last and fade |
| `team_config.gd` | Team names (translation keys), colours and the figures' paint glow |
| `accessibility_table.gd`, `team_colours.gd` | Read `data/accessibility.md`: the team colour sets (Standard, High contrast) for figures and the HUD with their day glow, Reduced motion's share of each movement, the props allowed near a team's hue; one set resolved for a match, day or night |
| `accessibility_config.gd` | Settings › Accessibility's fixed numbers: the sound cue ring (life, fade, far opacity, markers, radius) and the sound cue size and HUD size sliders' ranges |
| `bot_config.gd`, `bot_tuning.tres` | How bots play (`BotConfig.load_default()`): senses, aim, firing, lanes and holds, routes, cover, searching, hunting, the holster |
| `squad_config.gd` | Squad orders (part of `bot_tuning.tres`): Hold here's reach, wall gap, spacing, arrival and move distance |
| `bot_skill.gd` | How well a bot plays: reaction, turn rate, aim error and settling, lead, bursts, holds, whether it fires into bushes (Easy) |
