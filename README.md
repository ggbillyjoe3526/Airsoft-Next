# Airsoft

An original first-person airsoft shooter for Windows and Linux, built with Godot and Blender. Round-based team
matches against bots on purpose-built airsoft fields: plastic replicas, visible BBs, one hit and you're out, hand up,
"HIT!", walk off, reset, go again. Single player against bots only.

It is the same game as the browser version (`ggbillyjoe3526/Airsoft`, frozen at `0.1-beta.1`), rebuilt as an
installable desktop game. Versions restart at 0.1 Dev 1.

## Status

**Building 0.1 Dev 1.** Depot is playable against stand-in targets (no bots yet): press *Play Depot* on the title
screen. The plan is `docs/ROADMAP.md`; what is happening now is `docs/HANDOFF.md`.

## Run it

- **Players:** download the Windows installer or zip, or the Linux build, from the
  [Releases page](https://github.com/ggbillyjoe3526/Airsoft-Next/releases) once 0.1 Dev 1 is tagged.
- **From source:** install Godot **4.7.2** (standard, not .NET), choose *Import*, pick this folder's `project.godot`
  and press F5.
- **Controls:** move WASD, walk Shift, sprint Alt, crouch C or Ctrl, jump Space, fire and aim the left and
  right mouse buttons, reload R, fire mode B, replicas 1, 2 or the mouse wheel, pause Esc.

## Layout

| Folder | What it holds |
|---|---|
| `game/` | The game's scripts and scenes, by system (`docs/ARCHITECTURE.md`) |
| `data/` | The owner's data tables (replicas, stats, levels, bots, kits, callouts) and the map layouts |
| `assets/` | Models (glTF), fonts and sounds; every one is logged in `docs/ASSETS.md` |
| `tests/` | GUT unit tests, run headless |
| `tools/` | Check, test, release and asset scripts; `tools/blender/` builds the figures |
| `docs/` | Vision, art direction, rulings, roadmap, process and the playtest guide |
| `legacy/` | Read-only reference, removed at 0.1: the browser game's gameplay code, tests and docs, and a few katanashotgun scripts still to port |

## Checks

`tools/check.sh` runs every check CI runs (lint, unit tests, a headless smoke test, the licence notices); it needs
`godot` on PATH (or `GODOT=/path/to/godot`) and, for lint, `pip install "gdtoolkit==4.5.0"`. How work moves:
`docs/PROCESS.md` and `CLAUDE.md`.

## Licence

The code is MIT (`LICENSE`), copyright ggbillyjoe3526. Third-party assets keep their own licences (`docs/ASSETS.md`);
every build ships `THIRD_PARTY_NOTICES.txt`.
