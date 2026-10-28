class_name Ambience
extends Node3D
## Давящий фон комнаты: низкий гул и редкие звуки в темноте — далёкий свист, скрип,
## стук, гудение проводки. События звучат из случайной точки вокруг игрока.

## Гул повторяется по кругу. Частоты подобраны так, чтобы за это время
## каждая волна делала целое число колебаний и стык петли был не слышен.
const DRONE_SECONDS := 20.0
const DRONE_RATE := 11025
const EVENT_INTERVAL := Vector2(12.0, 35.0)
const EVENT_DISTANCE := Vector2(2.0, 5.0)
const EVENTS := ["whistle", "creak", "knock", "hum"]

var _drone := AudioStreamPlayer.new()
var _event := AudioStreamPlayer3D.new()
var _timer := Timer.new()
var _rng := RandomNumberGenerator.new()
var _events := {}


func _ready() -> void:
	_rng.randomize()
	_drone.stream = _build_drone()
	_drone.bus = Settings.MUSIC_BUS
	_drone.volume_db = -6.0
	add_child(_drone)
	_drone.play()
	_event.bus = Settings.MUSIC_BUS
	_event.unit_size = 3.0
	add_child(_event)
	for name: String in EVENTS:
		_events[name] = Synth.to_stream(_build_event(name))
	_timer.one_shot = true
	_timer.timeout.connect(_play_event)
	add_child(_timer)
	_schedule()


func _schedule() -> void:
	_timer.start(_rng.randf_range(EVENT_INTERVAL.x, EVENT_INTERVAL.y))


func _play_event() -> void:
	var angle := _rng.randf() * TAU
	var distance := _rng.randf_range(EVENT_DISTANCE.x, EVENT_DISTANCE.y)
	_event.position = Vector3(cos(angle) * distance, _rng.randf_range(0.5, 2.5), sin(angle) * distance)
	_event.stream = _events[EVENTS[_rng.randi_range(0, EVENTS.size() - 1)]]
	_event.play()
	_schedule()


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


func _build_event(name: String) -> PackedFloat32Array:
	match name:
		# Далёкий тонкий свист с дрожанием — как в старых хоррорах.
		"whistle":
			return Synth.sine(1750, 1380, 1.6, 0.12, 0.01)
		# Скрип: низкая «пила» из шума, будто старое дерево.
		"creak":
			return Synth.mix(Synth.square(95, 70, 0.9, 0.08, 0.1), Synth.noise(0.9, 0.12, 0.92, 21))
		# Два глухих удара где-то за стеной.
		"knock":
			return Synth.chain([Synth.thump(70, 0.25, 0.6), Synth.silence(0.25), Synth.thump(65, 0.35, 0.6)])
		# Нарастающее гудение проводки.
		"hum":
			return Synth.mix(Synth.sine(60, 60, 2.5, 0.2), Synth.sine(120, 121, 2.5, 0.08))
	return Synth.silence(0.1)
