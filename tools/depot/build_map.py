"""Writes data/maps/depot.json from tools/depot/layout.py (the layout as data). Run from anywhere:

    python3 tools/depot/build_map.py

Then rebake its light (`godot --headless --path . -s res://tools/bake_light.gd -- depot`) and re-render its card
(`tools/map_pictures.gd`, docs/ASSETS.md). The JSON is the map file the game reads (game/map/map_data.gd).
"""
from __future__ import annotations

import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import layout as L  # noqa: E402

OUT = os.path.join(HERE, "..", "..", "data", "maps", "depot.json")

# The concept's piece kinds as the game's block kinds (game/config/map_style.gd).
KINDS = {"wall": "plywood", "hut": "plywood", "wardrobe": "plywood", "window": "plywood", "dead": "rack",
         "crates": "crate", "lowcrate": "crate", "desk": "crate", "drums": "drum", "barrels": "barrel",
         "pillar": "pillar", "net": "net", "sofa": "sofa", "container": "container", "lid": "rack"}
# A window or a container's port: solid under the sill and over the lintel.
SILL, LINTEL = 1.0, 2.0
EYE_FACING_EAST = -math.pi / 2  # yaw -90 degrees looks along +x
EYE_FACING_WEST = math.pi / 2


def r(v: float) -> float:
    return round(v, 3)


def block(kind: str, x1: float, y1: float, z1: float, x2: float, y2: float, z2: float) -> dict:
    return {"kind": kind, "center": {"x": r((x1 + x2) / 2), "y": r((y1 + y2) / 2), "z": r((z1 + z2) / 2)},
            "size": {"x": r(x2 - x1), "y": r(y2 - y1), "z": r(z2 - z1)}}


def blocks() -> list[dict]:
    out = [block("floor", -L.W, -0.5, -L.H, L.W, 0.0, L.H)]
    # The hall's shell, up to the roof.
    t = 0.5
    out.append(block("wall", -L.W - t, 0, -L.H - t, L.W + t, L.ROOF, -L.H))
    out.append(block("wall", -L.W - t, 0, L.H, L.W + t, L.ROOF, L.H + t))
    out.append(block("wall", -L.W - t, 0, -L.H, -L.W, L.ROOF, L.H))
    out.append(block("wall", L.W, 0, -L.H, L.W + t, L.ROOF, L.H))
    for p in L.pieces:
        k, x1, z1, x2, z2, h = p["kind"], p["x1"], p["z1"], p["x2"], p["z2"], p["h"]
        kind = KINDS[k]
        if k == "window":
            kind = "container" if p["tag"] == "port" else kind
            out.append(block(kind, x1, 0, z1, x2, SILL, z2))
            out.append(block(kind, x1, LINTEL, z1, x2, p["h"], z2))
        elif k == "lid":
            out.append(block(kind, x1, L.LID_H, z1, x2, L.LID_H + h, z2))
        elif p["tag"] == "boxroof":
            out.append(block(kind, x1, 2.6, z1, x2, 2.6 + h, z2))
        else:
            out.append(block(kind, x1, 0, z1, x2, h, z2))
    return out


def spot(x: float, z: float, yaw: float) -> dict:
    return {"position": {"x": r(x), "y": 0, "z": r(z)}, "yaw": yaw}


def dead_zone(cx: float, cz: float, yaw: float) -> list[dict]:
    """Six walk-off spots: two columns of three, 0.8 m apart, round (cx, cz)."""
    return [spot(cx + dx, cz + dz, yaw) for dz in (-0.8, 0.0, 0.8) for dx in (-0.4, 0.4)]


def areas() -> list[dict]:
    """Every zone as a named area, the rooms and lanes first so where a link overlaps one the room names it."""
    rooms = [z for z in L.zones if z["lane"] != "x"]
    links = [z for z in L.zones if z["lane"] == "x"]
    return [{"name": z["name"], "box": [z["x1"], z["x2"], z["z1"], z["z2"]]} for z in rooms + links]


def roof() -> dict:
    """The roof (look only): its height and its lamp panels, every 7 m over each lit room, none over the tunnels."""
    lamps = []
    for z in L.zones:
        if z["light"] == "dark" or z["lane"] == "x":
            continue
        step = 7.0 if z["light"] == "lit" else 10.0
        x = z["x1"] + 3.0
        while x < z["x2"] - 1.0:
            zz = z["z1"] + 3.0
            while zz < z["z2"] - 1.0:
                lamps.append({"x": r(x), "z": r(zz)})
                zz += step
            x += step
    return {"height": L.ROOF, "lamps": lamps}


def site() -> dict:
    lines = [{"x": 1.0, "z": z, "w": 25.2, "d": 0.12} for z in (-10.8, 6.6)]
    stencils = [
        {"area": "A site", "x": 30.16, "y": 1.9, "z": -28.0, "facing": "+x", "height": 0.7},
        {"area": "B site", "x": 32.16, "y": 1.9, "z": 26.0, "facing": "+x", "height": 0.7},
        {"area": "Shoot House", "x": -36.16, "y": 1.9, "z": -29.0, "facing": "-x", "height": 0.45},
        {"area": "Offices", "x": 16.5, "y": 1.9, "z": -25.84, "facing": "+z", "height": 0.45},
    ]
    return {"stencils": stencils, "lines": lines}


def build() -> dict:
    return {
        "name": "Depot",
        "blocks": blocks(),
        "killY": -10,
        "spawns": [[spot(x, z, EYE_FACING_EAST) for x, z in L.SPAWNS_W],
                   [spot(x, z, EYE_FACING_WEST) for x, z in L.SPAWNS_E]],
        "deadZones": [dead_zone(*L.DEAD_W, EYE_FACING_EAST), dead_zone(*L.DEAD_E, EYE_FACING_WEST)],
        "lanes": [[{"x": x, "y": 0, "z": z} for x, z in L.LANES[k]] for k in ("n", "m", "s")],
        "flag": {"x": L.FLAG_A[0], "y": 0, "z": L.FLAG_A[1]},
        "overtimeFlag": {"x": L.OT_FLAG[0], "y": 0, "z": L.OT_FLAG[1]},
        "botSight": 55,
        "roof": roof(),
        "lighting": {"presets": ["day"], "overrides": {"day": {
            "key": {"elevation": 76, "heading": 25, "intensity": 1.1}, "hemi": {"intensity": 0.55}}}},
        "bakedLight": {"file": "depot"},
        "dressing": {"site": site()},
        "areas": areas(),
    }


if __name__ == "__main__":
    data = build()
    with open(OUT, "w") as f:
        json.dump(data, f, indent=1)
        f.write("\n")
    print(f"{os.path.relpath(OUT)}: {len(data['blocks'])} blocks, {len(data['areas'])} areas, "
          f"{len(data['roof']['lamps'])} lamps")
