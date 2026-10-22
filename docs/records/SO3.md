# SO3 · Order keys, the wheel's input and the radio click

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (QA's second-wheel-key advisory fixed and pinned by the build thread) | pass | 8/8 accept | |

## Decisions

- **Keys are the browser's:** F Follow me, X Hold here, V Regroup, Z (held) the order wheel; Team plan has no key. The
  Settings › Controls list is built from `KeyBindings`, so the four "SQUAD: …" rows show with no screen code.
- **The wheel's data is `ControlsConfig`:** orders, keys, names (`ORDER_*`, title case), gain 0.5 × sensitivity,
  reach 90 px, dead zone 24 px, slices clockwise from the top, Hover / Click (saved as `wheel_pick`, Hover by default).
  One table maps the order keys too. The pointer works in mouse px; SO4 maps them to its drawing.
- **While Z is held** the mouse moves the wheel's pointer, not the view; feet still move, the mouse wheel switches
  nothing, aim held before stays up, fire and aim need a fresh press after. It closes giving nothing on pause, focus
  loss, being out, on the range and on a key-up it never saw. A second key bound to the wheel doesn't recentre it.
- **Out of play** the wheel can't open but the order keys still send, so the simulation refuses them (NOT_NOW) for
  SO4's notice.
- **The radio click** (`radio_ack`) plays on your own voice on the Interface bus only for your order taken (no notice,
  an order in force); a refusal, a cancel or nobody to take it plays nothing.
- **Merged before SO4** (critic): the frozen view lasts only while Z is held, and a gate until SO4 would be throwaway
  code the smoke test couldn't exercise. The KNOWN_ISSUES row names it.
- `game/save/settings_apply.gd` (outside touches) gets one line carrying `wheel_pick` into the controls.

## Also fixed here

- **The exported game crashed on starting a match** (on main too, unseen because the export test only runs when the
  release files change; the last run was PR #48). `sim_tuning.tres` and `play_tuning.tres` left out configs added
  since (wind, ricochet, vault, flag, targets; debug view, flag view, range view); an export converts the .tres in the
  editor, where the scripts' `= Config.new()` defaults don't run, so they shipped as null. Both files now write every
  config out, `tests/unit/test_saved_configs.gd` fails if a saved config file leaves one out, and the export test now
  also runs when a `game/config` .tres changes. Exported Linux build checked locally: smoke ok, no script errors.

## Known issues left

- Until SO4 draws it, holding Z stops the view with nothing on screen; don't tag a build between SO3 and SO4 unless
  that row is acceptable.
- `order_wheel_pointer.gd` repeats reach 90 and dead zone 24 as default arguments beside `ControlsConfig`'s (setup
  always passes the config's); can wait.
- Owner to test: hold Z and flick each way (view still, feet move, letting go on an order clicks twice); whether Z
  opens by accident beside X and Shift; F then F (one click, then silence); alt-tab or Esc with Z held; the four rows
  rebinding in Settings, a mouse button on the wheel included.
