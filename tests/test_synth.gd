extends TestCase


func test_length_matches_duration() -> void:
	check_eq(Synth.square(440, 440, 0.5).size(), int(0.5 * Synth.RATE), "полсекунды")


func test_stays_in_range() -> void:
	for sample in Synth.mix(Synth.square(220, 880, 0.2, 0.6), Synth.noise(0.2, 0.6)):
		check(absf(sample) <= 1.2, "без перегруза")


func test_edges_are_quiet() -> void:
	var tone := Synth.square(440, 440, 0.1, 0.5)
	check(absf(tone[0]) < 0.01 and absf(tone[tone.size() - 1]) < 0.01, "края без щелчка")


func test_stream_is_16_bit() -> void:
	var stream := Synth.to_stream(Synth.sine(440, 440, 0.1), true)
	check_eq(stream.data.size(), int(0.1 * Synth.RATE) * 2, "два байта на отсчёт")
	check_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "повтор включён")


func test_noise_is_repeatable() -> void:
	check_eq(Synth.noise(0.05, 0.3, 0.5, 7), Synth.noise(0.05, 0.3, 0.5, 7), "один сид — один шум")


func test_every_sound_is_built() -> void:
	# Неизвестное имя даёт тишину в 0.01 с — настоящие звуки длиннее.
	for sound in Sounds.NAMES:
		check(Sounds.get_stream(sound).data.size() > int(0.011 * Synth.RATE) * 2, "звук " + sound)
