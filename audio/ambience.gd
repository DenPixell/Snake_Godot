class_name Ambience
extends Node
## Давящий фон комнаты: только низкий гул, без отдельных звуков.

## Гул повторяется по кругу. Частоты подобраны так, чтобы за это время
## каждая волна делала целое число колебаний и стык петли был не слышен.
const DRONE_SECONDS := 20.0
const DRONE_RATE := 11025

var _drone := AudioStreamPlayer.new()


func _ready() -> void:
	_drone.stream = _build_drone()
	_drone.bus = Settings.MUSIC_BUS
	_drone.volume_db = -6.0
	add_child(_drone)
	_drone.play()


## Две близкие низкие ноты дают медленные «биения», под ними — глухой шум и гудение сети.
func _build_drone() -> AudioStreamWAV:
	var count := int(DRONE_SECONDS * DRONE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var rumble := 0.0
	for i in count:
		var t := float(i) / DRONE_RATE
		# Медленная «волна» громкости: 2 полных периода за петлю.
		var swell := 0.75 + 0.25 * sin(TAU * t * 2.0 / DRONE_SECONDS)
		var low := sin(TAU * 41.0 * t) * 0.35 + sin(TAU * 41.35 * t) * 0.3 + sin(TAU * 55.0 * t) * 0.12
		var mains := (sin(TAU * 60.0 * t) * 0.03 + sin(TAU * 180.0 * t) * 0.015)
		rumble = lerpf(rng.randf_range(-1.0, 1.0), rumble, 0.985)
		samples[i] = (low * swell + mains + rumble * 0.6) * 0.7
	# Шум не повторяется сам по себе: плавно сводим конец петли с её началом.
	var fade := int(1.0 * DRONE_RATE)
	for i in fade:
		var k := float(i) / fade
		samples[count - fade + i] = lerpf(samples[count - fade + i], samples[i], k)
	var stream := Synth.to_stream(samples, true)
	stream.mix_rate = DRONE_RATE
	return stream
