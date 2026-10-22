extends GutTest
## The referee's whistle (SP3): the rendered blasts on disk (length, peak, pitch, made from SoundConfig's numbers by
## tools/render_whistle.gd) and SoundConfig's level and blast pattern (the browser game's whistle.ts and AUDIO).

const Renderer := preload("res://tools/render_whistle.gd")
const RATE := 44100
const HEADER := 44

var cfg: SoundConfig


func before_all() -> void:
	cfg = PlayTuning.load_default().sound


func test_each_blast_is_a_16_bit_mono_wav_of_its_length_at_full_scale_and_2900_hz() -> void:
	for stem: String in [Renderer.SHORT, Renderer.LONG]:
		var seconds := Renderer.length_of(cfg, stem)
		assert_almost_eq(seconds, 0.14 if stem == Renderer.SHORT else 0.8, 1e-6, stem)
		for v in 3:
			var path := "%s%s_%d.wav" % [SoundConfig.CUE_DIR, stem, v + 1]
			var bytes := FileAccess.get_file_as_bytes(path)
			assert_gt(bytes.size(), HEADER, path)
			if bytes.size() <= HEADER:
				continue
			assert_eq(bytes.slice(0, 4).get_string_from_ascii(), "RIFF", path)
			assert_eq(bytes.decode_u16(20), 1, "%s is PCM" % path)
			assert_eq(bytes.decode_u16(22), 1, "%s is mono" % path)
			assert_eq(bytes.decode_u32(24), RATE, "%s is 44.1 kHz" % path)
			assert_eq(bytes.decode_u16(34), 16, "%s is 16-bit" % path)
			var frames := bytes.decode_u32(40) >> 1
			assert_almost_eq(float(frames) / RATE, seconds, 1.0 / RATE, "%s lasts its blast" % path)
			var peak := 0
			var first := -1.0
			var last := -1.0
			var rises := 0
			var before := bytes.decode_s16(HEADER)
			for i in range(1, frames):
				var s := bytes.decode_s16(HEADER + i * 2)
				peak = maxi(peak, absi(s))
				if before <= 0 and s > 0:
					var at := i - 1 + float(-before) / float(s - before)
					if first < 0.0:
						first = at
					last = at
					rises += 1
				before = s
			assert_between(peak / 32767.0, 0.98, 1.0, "%s peaks at full scale" % path)
			var hz := (rises - 1) / ((last - first) / RATE)
			assert_almost_eq(hz / 2900.0, 1.0, 0.02, "%s sounds at %.1f Hz" % [path, hz])


func test_the_files_are_rendered_from_sound_configs_numbers_each_variant_its_own() -> void:
	var renders: Array[PackedByteArray] = []
	for stem: String in [Renderer.SHORT, Renderer.LONG]:
		for v in cfg.whistle_variants:
			var path := "%s%s_%d.wav" % [SoundConfig.CUE_DIR, stem, v + 1]
			var made := Renderer.wav(Renderer.samples(cfg, Renderer.length_of(cfg, stem), v))
			assert_true(FileAccess.get_file_as_bytes(path) == made, "%s is SoundConfig's whistle (re-render it)" % path)
			for other in renders:
				assert_false(other == made, "%s differs from the other variants" % path)
			renders.append(made)
	assert_false(ResourceLoader.exists("%swhistle_short_%d.wav" % [SoundConfig.CUE_DIR, cfg.whistle_variants + 1]))


func test_the_whistle_numbers_are_the_browsers() -> void:
	assert_almost_eq(cfg.whistle_gain, 0.25, 1e-6, "level")
	assert_almost_eq(cfg.whistle_hz, 2900.0, 1e-6)
	assert_almost_eq(cfg.whistle_warble_hz, 28.0, 1e-6)
	assert_almost_eq(cfg.whistle_warble_depth, 0.04, 1e-6)
	assert_almost_eq(cfg.whistle_attack, 0.02, 1e-6)
	assert_almost_eq(cfg.whistle_release, 0.05, 1e-6)
	assert_eq(cfg.whistle_variants, 3)


func test_a_round_starts_on_two_short_blasts_the_second_1_6_lengths_on() -> void:
	assert_eq(cfg.round_start_blasts, 2)
	assert_almost_eq(cfg.round_start_blast(0), 0.0, 1e-6)
	assert_almost_eq(cfg.round_start_blast(1), 0.14 * 1.6, 1e-6)


func test_the_match_ends_on_three_more_long_blasts_after_the_rounds_each_1_3_lengths_on() -> void:
	assert_eq(cfg.match_over_blasts, 3)
	for i in 3:
		assert_almost_eq(cfg.match_over_blast(i), 0.8 * 1.3 * (i + 1), 1e-6, "blast %d" % i)
	assert_gt(cfg.match_over_blast(0), cfg.whistle_long, "the round's long blast ends before the next starts")
