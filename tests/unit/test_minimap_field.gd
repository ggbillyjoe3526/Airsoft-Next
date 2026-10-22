extends GutTest
## The minimap's field drawing (MM3; the browser game's minimap layers, M23 and M34c), read pixel by pixel: Depot's
## walls, low cover, the dock raised with its rim and the ramps, Neon Heights' storeys (the floors over a storey left
## out, the street under it washed darker), storey_of, the size cap, nothing on the range, and the images freed with
## the field. Each map is drawn once for the file; the build time and bytes are printed.

## How far apart two colours may be per channel after the image's 8 bits.
const TOLERANCE := 1.5 / 255.0

var cfg: MinimapConfig = null
var maps: Dictionary[String, MapData] = {}
var fields: Dictionary[String, MinimapField] = {}


func before_all() -> void:
	cfg = PlayTuning.load_default().minimap
	var tuning := SimTuning.load_default()
	for id: String in ["depot", "neonHeights", "range"]:
		maps[id] = MapData.load_map(id, MapStyle.new(), tuning.rounds.team_size if id != "range" else 1)
		var t0 := Time.get_ticks_usec()
		fields[id] = MinimapField.build(maps[id], cfg)
		var f := fields[id]
		var side := Vector2i.ZERO if f.layers.is_empty() else f.layers[0].get_size()
		gut.p("%s: %d layer(s) of %s px at %.2f px/m, %.1f ms, %d KB" % [id, f.layers.size(), side, f.scale,
				(Time.get_ticks_usec() - t0) / 1000.0, f.byte_size() / 1024])


func after_all() -> void:
	fields.clear()
	maps.clear()
	cfg = null


func test_depot_is_one_layer_at_the_layer_scale() -> void:
	var f := fields["depot"]
	assert_eq(f.layers.size(), 1, "no storeys, one image")
	assert_eq(f.scale, cfg.layer_scale)
	assert_eq(f.layers[0].get_size(), Vector2i(510, 330), "51 m by 33 m of floor at 10 px/m")
	assert_eq(f.pixel_of(-25.5, -16.5), Vector2.ZERO, "north west corner at the top left")
	assert_eq(f.storey_of(1.2), 0)


func test_depot_walls_cover_floors_and_ramps() -> void:
	assert_colour("depot", 0, -17.5, 0.0, cfg.tall_colour, "the long wall by the toilets is tall")
	assert_colour("depot", 0, -11.6, 0.0, cfg.low_colour, "the 1.2 m barrier is low cover")
	assert_colour("depot", 0, -21.4, 11.8, cfg.tall_colour, "two crates stacked are tall")
	assert_colour("depot", 0, -0.5, -15.4, cfg.low_colour, "sandbags on the dock: low over the dock's floor")
	assert_colour("depot", 0, -2.5, 0.0, cfg.ground_colour, "open yard is ground")
	assert_colour("depot", 0, 9.5, -14.5, cfg.raised_colour, "the loading dock is raised floor")
	assert_colour("depot", 0, -3.2, -14.6, cfg.ramp_colour, "the west ramp up to the dock")
	assert_colour("depot", 0, 12.2, -14.6, cfg.ramp_colour, "the east ramp up to the dock")


## The browser's known issue: the dock a shade off the yard, so a patch over it read as one below. The rim marks the
## dock's drop on the yard side; where a ramp meets it there is none.
func test_the_dock_has_a_rim_where_it_drops() -> void:
	assert_ne(pixel("depot", 0, 9.5, -14.5), pixel("depot", 0, 4.0, -12.5), "dock and yard differ")
	assert_colour("depot", 0, 4.0, -13.05, cfg.drop_colour, "the rim along the dock's yard side")
	assert_colour("depot", 0, 4.0, -12.8, cfg.ground_colour, "the yard past the rim")
	assert_colour("depot", 0, -2.1, -14.6, cfg.ramp_colour, "no rim where the west ramp meets the dock")
	assert_colour("depot", 0, 11.1, -14.6, cfg.ramp_colour, "nor the east one")
	var lift := luminance(cfg.raised_colour) - luminance(cfg.drop_colour)
	assert_gt(lift, luminance(cfg.raised_colour) - luminance(cfg.ground_colour), "the rim stands out more than the shade")


func test_neon_heights_has_a_layer_per_storey() -> void:
	var f := fields["neonHeights"]
	assert_eq(f.layers.size(), 3)
	assert_eq(f.floors, maps["neonHeights"].storeys)
	for img in f.layers:
		assert_eq(img.get_size(), f.layers[0].get_size(), "the layers line up")
	assert_eq(f.storey_of(0.0), 0)
	assert_eq(f.storey_of(-1.0), 0, "below the lowest storey is on it")
	assert_eq(f.storey_of(2.4), 0, "half way up a stair")
	assert_eq(f.storey_of(2.6), 1, "the top of a stair counts as the storey it reaches")
	assert_eq(f.storey_of(3.0), 1)
	assert_eq(f.storey_of(5.6), 2)
	assert_eq(f.storey_of(9.3), 2, "on a roof, the top storey")


func test_a_storey_leaves_out_the_floors_over_it() -> void:
	# (-10, -6): the street, the west building's 3 m floor, and its roof (a 6.0-6.3 m slab) over that.
	assert_colour("neonHeights", 0, -10.0, -6.0, cfg.ground_colour, "the street: the 3 m floor over it left out")
	assert_colour("neonHeights", 1, -10.0, -6.0, cfg.ground_colour, "the 3 m floor, its roof left out")
	assert_colour("neonHeights", 2, -10.0, -6.0, cfg.ground_colour, "the roof is at the 6 m storey's feet")


func test_an_upper_storey_washes_the_street_darker() -> void:
	# (0, 7.3): the street under the 6 m bridge.
	var washed := cfg.ground_colour.blend(cfg.below_storey_colour)
	assert_colour("neonHeights", 0, 0.0, 7.3, cfg.ground_colour, "the street on the street's storey")
	assert_colour("neonHeights", 1, 0.0, 7.3, washed, "the street under the 3 m storey, the bridge left out")
	assert_lt(luminance(pixel("neonHeights", 1, 0.0, 7.3)), luminance(pixel("neonHeights", 0, 0.0, 7.3)), "darker")
	assert_colour("neonHeights", 2, 0.0, 7.3, cfg.ground_colour, "the bridge on its own storey")
	assert_colour("neonHeights", 2, -10.0, 4.2, washed, "a 3 m floor open to the sky, under the 6 m storey")


func test_a_storeys_own_cover_shows() -> void:
	# A crate (3.0-4.2 m) on the west building's 3 m floor.
	assert_colour("neonHeights", 1, -8.0, -4.0, cfg.low_colour, "a crate on the 3 m floor is low cover there")
	assert_colour("neonHeights", 0, -8.0, -4.0, cfg.ground_colour, "and out of the street's drawing")


func test_no_side_passes_the_cap() -> void:
	var text := JSON.stringify({"blocks": [{"kind": "floor", "center": {"x": 0, "y": -0.25, "z": 0},
			"size": {"x": 300, "y": 0.5, "z": 100}}]})
	var f := MinimapField.build(MapData.parse(text, MapStyle.new(), 1), cfg)
	assert_eq(f.layers.size(), 1)
	assert_lt(f.scale, cfg.layer_scale, "the scale lowered for a big field")
	assert_eq(f.layers[0].get_width(), cfg.max_layer_side, "the long side at the cap")
	assert_lte(f.layers[0].get_height(), cfg.max_layer_side)
	for id: String in fields:
		for img in fields[id].layers:
			assert_lte(maxi(img.get_width(), img.get_height()), cfg.max_layer_side, id)


func test_nothing_is_built_on_the_range() -> void:
	assert_false(MinimapField.drawn(maps["range"]))
	assert_true(fields["range"].layers.is_empty())
	assert_eq(fields["range"].byte_size(), 0)
	assert_eq(fields["range"].storey_of(1.0), 0)


func test_the_images_go_with_the_field() -> void:
	var f := MinimapField.build(maps["depot"], cfg)
	var held: WeakRef = weakref(f.layers[0])
	f = null
	assert_null(held.get_ref(), "the image is freed with its field")


func test_the_config_is_left_alone() -> void:
	assert_eq(PlayTuning.load_default().minimap.layer_scale, cfg.layer_scale, "the shared default unchanged")


func pixel(id: String, layer: int, x: float, z: float) -> Color:
	var f := fields[id]
	var at := Vector2i(f.pixel_of(x, z).floor())
	return f.layers[layer].get_pixelv(at)


func assert_colour(id: String, layer: int, x: float, z: float, want: Color, what: String) -> void:
	var got := pixel(id, layer, x, z)
	var off := maxf(maxf(absf(got.r - want.r), absf(got.g - want.g)), maxf(absf(got.b - want.b), absf(got.a - want.a)))
	assert_lte(off, TOLERANCE, "%s (%s at %.2f, %.2f storey %d: %s, want %s)" % [what, id, x, z, layer, got, want])


static func luminance(c: Color) -> float:
	return c.get_luminance()
