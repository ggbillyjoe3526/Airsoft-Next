class_name YardMap
extends RefCounted
## The first Depot, an outdoor warehouse yard 51 x 33 m (`maps/yard.json`), kept for the tests written against its
## layout when Depot became the indoor hall (DR1, 2026-10-31): its blocks, ends, lanes, areas, flag and overtime spot as
## they were, without its bake. Test-only (tests/ never ships), and never in the catalogue: loaded from its file.

const PATH := "res://tests/support/maps/yard.json"


## The yard at `team_size` a side (at most 3), read with `style`.
static func load_map(style: MapStyle, team_size: int) -> MapData:
	var m := MapData.parse(FileAccess.get_file_as_string(PATH), style, team_size)
	m.id = "yard"
	return m
