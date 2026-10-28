extends OmniLight3D
## Свет свечи: неровное мерцание и лёгкое дрожание пламени.

@export var flicker := 0.25
@export var sway := 0.004

var _base_energy: float
var _base_position: Vector3
var _noise := FastNoiseLite.new()
var _time := 0.0


func _ready() -> void:
	_base_energy = light_energy
	_base_position = position
	_noise.frequency = 1.5


func _process(delta: float) -> void:
	_time += delta
	var n := _noise.get_noise_1d(_time * 10.0)
	light_energy = _base_energy * (1.0 + n * flicker)
	position = _base_position + Vector3(
		_noise.get_noise_2d(_time * 4.0, 10.0),
		_noise.get_noise_2d(_time * 4.0, 20.0),
		0.0,
	) * sway
