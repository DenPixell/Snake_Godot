class_name Synth
extends RefCounted
## Простейший синтезатор: собирает звук из волн и шума и упаковывает в AudioStreamWAV.
## Все звуки игры делаются им, поэтому в проекте нет звуковых файлов.

const RATE := 22050


## Квадратная волна с плавным изменением частоты — так звучит динамик Game Boy.
## duty — доля «верхней» половины волны: 0.5 — ровный звук, 0.125 — тонкий, гнусавый.
static func square(from_hz: float, to_hz: float, duration: float, volume := 0.3,
		duty := 0.5) -> PackedFloat32Array:
	var count := int(duration * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase = fmod(phase + lerpf(from_hz, to_hz, t) / RATE, 1.0)
		out[i] = (volume if phase < duty else -volume) * _envelope(i, count)
	return out


## Синусоида со скольжением частоты и лёгким дрожанием (vibrato).
static func sine(from_hz: float, to_hz: float, duration: float, volume := 0.3,
		vibrato := 0.0) -> PackedFloat32Array:
	var count := int(duration * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		var hz := lerpf(from_hz, to_hz, t) * (1.0 + vibrato * sin(TAU * 5.0 * i / RATE))
		phase = fmod(phase + hz / RATE, 1.0)
		out[i] = sin(TAU * phase) * volume * _envelope(i, count)
	return out


## Шум. smooth от 0 до 1: чем больше, тем глуше (простой фильтр нижних частот).
static func noise(duration: float, volume := 0.3, smooth := 0.0, seed_value := 1) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := int(duration * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var value := 0.0
	for i in count:
		value = lerpf(rng.randf_range(-1.0, 1.0), value, smooth)
		out[i] = value * volume * _envelope(i, count)
	return out


## Звуки друг за другом.
static func chain(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for part: PackedFloat32Array in parts:
		out.append_array(part)
	return out


## Тишина заданной длины.
static func silence(duration: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(duration * RATE))
	return out


## Сложение двух звуков (второй может быть короче).
static func mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := a.duplicate()
	if b.size() > out.size():
		out.resize(b.size())
	for i in b.size():
		out[i] += b[i]
	return out


## Упаковка в поток для AudioStreamPlayer. loop — бесконечный повтор.
static func to_stream(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	return stream


## Короткое нарастание и затухание по краям, чтобы звук не щёлкал.
static func _envelope(i: int, count: int) -> float:
	var edge := mini(int(0.004 * RATE), count / 4)
	if edge <= 0:
		return 1.0
	return clampf(minf(float(i) / edge, float(count - 1 - i) / edge), 0.0, 1.0)
