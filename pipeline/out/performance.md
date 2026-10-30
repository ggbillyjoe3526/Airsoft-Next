Task: RL2 · head 24ed35c · Verdict: Pass
Run: no headless --perf match run (read-only review of origin/main...24ed35c; the diff adds no per-tick or per-frame work that a run could resolve from noise on a shared 4-core box) · budget: no baseline yet, judged against targets and origin/main by reading the diff
Metrics: not measured. Static cost: +5 Controls built once in Hud.setup (PanelContainer, HBox, key chip panel + Label, RELOAD Label), parented under the existing prompt VBox, freed with the HUD. No new autoload, timer, tween, material or mesh.
Regressions (> 10 % worse): none (judgment)

Per-frame path (hud.gd:840 -> hud_reload_prompt.gd:36 show_when), judgment:
- Hud.update evaluates `manual_reload and in_play and is_live() and a.reload_due()`; short-circuits on the Manual flag and live phase. reload_due (armament.gd:167-173) is a few field reads plus next_spare (armament.gd:25-30), a loop over the small pouch array with no allocation. No Array/Dictionary/String/Callable is made per frame.
- show_when assigns `visible = due` each frame; CanvasItem.set_visible returns early on an unchanged value, so no relayout or redraw between changes. A relayout of the prompt VBox happens only when it appears or hides.
- Input map lookup + string building (KeyNames.of_action -> InputMap.action_get_events, name_of) run only on the hidden -> shown transition (hud_reload_prompt.gd:37-38), once per empty magazine, and on _resume (play_session.gd:1322). Not per frame. Label.text with an equal string is also a no-op.
- No theme lookups per frame: fonts, sizes and the stylebox are set once in _init (override theme calls at build time only).
- play_session.gd:1047 copies one bool from the player's cached PlayerCommand each _process; no allocation.

Sim tick: armament.gd:327 adds one bool test inside the already-taken dry-click branch (cmd.manual_reload). PlayerCommand gains one bool, copied in reset/copy_from (player_command.gd:66,91) and vault.gd:190; PlayerInput.fill writes it once per tick (player_input.gd:290,314). Negligible, no allocation.

Teardown / signals: the prompt connects no signals and owns no timers or tweens. It is a child of the HUD prompt VBox and goes with the HUD (no orphans). settings_screen.gd:246 adds one toggled lambda inside _build_controls, which runs once at line 125 (not per open), so no duplicate connection.

Presets / prewarm: no new shader, material, particle or quality-preset bypass (flat StyleBox via HudStyle.panel_box).

Blocking findings: none
Advisory: none
Unexplained: none
Not verified: no frame-time or node-count run was taken (the cloud box has no GPU, and the node delta is the 5 static Controls above).

Verdict: Pass
