class_name Sounds
extends RefCounted
## Все короткие звуки игры. Собираются синтезатором при первом обращении и запоминаются.

## Все имена звуков — пригодится, чтобы проверить, что ни один не потерян.
const NAMES: Array[String] = [
	"move", "select", "back", "eat", "big", "bad", "brick", "tick", "go", "pause",
	"die", "over", "win", "click", "ui_hover", "ui_click",
]

static var _cache := {}


static func get_stream(sound: String) -> AudioStreamWAV:
	if not _cache.has(sound):
		_cache[sound] = Synth.to_stream(_build(sound))
	return _cache[sound]


static func _build(sound: String) -> PackedFloat32Array:
	match sound:
		# Динамик Game Boy: квадратная волна.
		"move":
			return Synth.square(880, 880, 0.03, 0.2, 0.25)
		"select":
			return Synth.chain([Synth.square(660, 660, 0.04, 0.22), Synth.square(990, 990, 0.07, 0.22)])
		"back":
			return Synth.chain([Synth.square(990, 990, 0.04, 0.22), Synth.square(660, 660, 0.07, 0.22)])
		"eat":
			return Synth.chain([Synth.square(1046, 1046, 0.03, 0.22), Synth.square(1318, 1318, 0.05, 0.22)])
		"big":
			return Synth.chain([Synth.square(523, 523, 0.04, 0.22), Synth.square(659, 659, 0.04, 0.22),
					Synth.square(784, 784, 0.04, 0.22), Synth.square(1046, 1046, 0.08, 0.22)])
		"bad":
			return Synth.square(330, 180, 0.22, 0.24, 0.125)
		"brick":
			return Synth.mix(Synth.noise(0.1, 0.35, 0.7, 3), Synth.square(110, 80, 0.1, 0.2))
		"tick":
			return Synth.square(1046, 1046, 0.06, 0.2)
		"go":
			return Synth.square(2093, 2093, 0.14, 0.2)
		"pause":
			return Synth.chain([Synth.square(523, 523, 0.05, 0.2), Synth.square(392, 392, 0.09, 0.2)])
		"die":
			return Synth.mix(Synth.square(440, 90, 0.6, 0.25, 0.25), Synth.noise(0.6, 0.12, 0.3, 5))
		"over":
			return Synth.chain([Synth.square(392, 392, 0.16, 0.22), Synth.square(330, 330, 0.16, 0.22),
					Synth.square(262, 262, 0.35, 0.22)])
		"win":
			return Synth.chain([Synth.square(523, 523, 0.1, 0.22), Synth.square(659, 659, 0.1, 0.22),
					Synth.square(784, 784, 0.1, 0.22), Synth.square(1046, 1046, 0.35, 0.22)])
		# Пластмассовый щелчок кнопки корпуса.
		"click":
			return Synth.mix(Synth.noise(0.018, 0.5, 0.2, 9), Synth.sine(2400, 1800, 0.012, 0.15))
		# Меню на экране монитора.
		"ui_hover":
			return Synth.sine(1400, 1400, 0.02, 0.08)
		"ui_click":
			return Synth.mix(Synth.noise(0.03, 0.3, 0.5, 11), Synth.sine(900, 600, 0.04, 0.15))
	push_error("Нет такого звука: " + sound)
	return Synth.silence(0.01)
