class_name TowerBlock
extends RefCounted
## A small test field built in storeys that offers both Day and Night (`maps/tower_block.json`), for what no shipped map
## has since Neon Heights went (2026-10-29): floors at 0, 3 and 6 m with areas banded by floor, a 3 m floor with a crate
## on it under a roof, a 3 m floor open to the sky, a 6 m bridge over the street, and pools of light on two floors.
## Test-only (tests/ never ships), and never in the catalogue: it is loaded from its file, not by id.

const PATH := "res://tests/support/maps/tower_block.json"


## The field at `team_size` a side, read with `style`.
static func load_map(style: MapStyle, team_size: int) -> MapData:
	return MapData.parse(FileAccess.get_file_as_string(PATH), style, team_size)
