Task: SF1 · Smoke and flash bombs (players' bombs, bots affected; bots throwing is SF2)
Attempt: 1 of 4
Head: 5470dc8 (checks passed on it)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. Keys: key_bindings.gd:55-56 (G, Y), player_input.gd:186-189,329 → grenades.gd:122-139. Smoke hides: grenades.gd:226-259
   (smoke_depth), grenade_view.gd:250-293 (puffs, wash). Flash blinds by facing: grenades.gd:265-279,363-391; wash and
   dip grenade_view.gd:278-293, sound_mix.gd:56-58. Bots: bot_senses.gd:64-65,85-93,189-193, bot_brain.gd:26-32.
   Records: SF1.md, DECISIONS (SF1 x3), KNOWN_ISSUES (4 rows incl. SF2), PLAYTEST, wiki Grenades/Controls/Loadout.
2. Grenades/Grenade are RefCounted in game/sim; six GameEvent kinds; bots act only via cmd.crouch; tuning in
   GrenadeConfig inside sim_tuning.tres; view keeps its own seeded RNG. No contract changed.
3. Read step, press, step_throw, _fly, _bang, smoke_depth, BotSenses.smoke_clear, GrenadeView.update/_draw_*,
   replica_panel._refresh_bombs (text only on change), sim_audio, sound_mix: no Array/Dictionary/String/lambda/new()
   per tick or frame; pool of 12 made once. QA's and test_grenades.gd:609 OBJECT_COUNT tests hold it.
4. test_grenades.gd:561-576 asserts visible_part == 0 with a full cloud between: removing smoke_clear from
   _sight_clear (bot_senses.gd:201) makes it see the foe and fail. QA's mutation runs confirm the rest.
5. Rules in Grenades; view and HUD read state and events. Typed throughout. Gameplay numbers in GrenadeConfig/BotConfig.
6. Toy canisters (green, violet), pop and hiss, white wash and a bang, no ringing, teammates dazzled as on a site;
   sounds synthesised in-house and recorded in ASSETS; tools/ excluded from exports.
7. Two scripts under 400 lines, pooled view freed with its node, .tres ids kept (20_gr1gc added only).
8. Dev 2 feature the owner asked for; CO2 grenade, rigs, arc preview and cooking left to IDEAS/0.2; SF2 row filed.
   The changelog.d note is the changelog agent's, after this report.
Advisories (non-blocking, none fails a check):
- grenades.gd:161 turns the torch back on by writing torch_on: no TORCH event (no click, torch_time not reset), while
  going off for the throw clicks (torch.gd:46). Route it through Torch so on and off match.
- grenade_view.gd:212-226 smoke_inside re-derives the cloud ellipsoid Grenades owns; one helper in Grenades would keep
  one source of truth for the cloud's shape.
- grenade_view.gd:283 (`* 2.0`) and :326 (`0.75`) are unnamed view tuning; name them like the other consts.
- QA's open advisories stand: two bangs in one tick draw one flare (grenade_view.gd:146); a weak dazzle peaks dim.
Owner should test in the game:
- Smoke from outside and inside on Low and at 4K: solid cloud, no pop at screen edges, frame time inside it.
- Flash in your face and at your feet: is up to 3.5 s of white fair and fun; Reduced motion softer.
- Throw feel: windup and redraw speed mid-fight, a lob over a container, a sprinting throw.
- Bots: cross behind a cloud (they should stop firing), flash them round a corner (they duck, stop, recover).
- At night: torch off for the throw and back on (silently); the held canister near a wall (clipping).
- G and Y, rebinding them, and the panel's "SMOKE 1 · FLASH 1" spending and refilling.
