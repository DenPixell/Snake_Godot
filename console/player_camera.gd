class_name PlayerCamera
extends Camera3D
## Камера игрока: лёгкое «дыхание» и небольшой поворот мышью.

## На сколько градусов можно повернуть голову мышью.
const LOOK_LIMIT := Vector2(7.0, 5.0)
const MOUSE_SENSITIVITY := 0.04
## Как быстро взгляд возвращается к Game Boy, когда мышь не двигается.
const RETURN_SPEED := 0.6
const BREATH_AMOUNT := 0.0025
const BREATH_SPEED := 0.9

## Пока камера не активна (главное меню, переход), ею управляет сцена, а не игрок.
var active := false

var _base: Transform3D
var _look := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	# Положение из сцены позы — вокруг него камера «дышит» и поворачивается мышью.
	_base = global_transform


## Где стоит камера во время игры.
func base_transform() -> Transform3D:
	return _base


func activate() -> void:
	active = true
	_look = Vector2.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func deactivate() -> void:
	active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look -= event.relative * MOUSE_SENSITIVITY
		_look = _look.clamp(-LOOK_LIMIT, LOOK_LIMIT)


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	_look = _look.move_toward(Vector2.ZERO, RETURN_SPEED * delta * _look.length())
	var breath := Vector3(
		sin(_time * BREATH_SPEED * 0.5) * 0.4,
		sin(_time * BREATH_SPEED),
		0.0,
	) * BREATH_AMOUNT
	var rotation_offset := Basis.from_euler(Vector3(deg_to_rad(_look.y), deg_to_rad(_look.x), 0.0))
	global_transform = Transform3D(_base.basis * rotation_offset, _base.origin + _base.basis * breath)
