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

var _base: Transform3D
var _look := Vector2.ZERO
var _time := 0.0


## Положение, вокруг которого камера «дышит» и поворачивается мышью.
func set_base(base: Transform3D) -> void:
	_base = base
	global_transform = base


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# Esc отпускает мышь, повторный Esc снова захватывает. Позже здесь откроется меню паузы.
	if event.is_action_pressed("pause_menu"):
		var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look -= event.relative * MOUSE_SENSITIVITY
		_look = _look.clamp(-LOOK_LIMIT, LOOK_LIMIT)


func _process(delta: float) -> void:
	_time += delta
	_look = _look.move_toward(Vector2.ZERO, RETURN_SPEED * delta * _look.length())
	var breath := Vector3(
		sin(_time * BREATH_SPEED * 0.5) * 0.4,
		sin(_time * BREATH_SPEED),
		0.0,
	) * BREATH_AMOUNT
	var rotation_offset := Basis.from_euler(Vector3(deg_to_rad(_look.y), deg_to_rad(_look.x), 0.0))
	global_transform = Transform3D(_base.basis * rotation_offset, _base.origin + _base.basis * breath)
