class_name GameBoy
extends Node3D
## 3D-модель Game Boy: экран показывает наш ЖК, кнопки нажимаются вместе с вводом.
## Координаты ниже — в системе меша модели: лицевая сторона смотрит в −Y, верх корпуса — +Z.

const MODEL := preload("res://assets/gameboy/scene.gltf")
const SCREEN_SHADER := preload("res://screen/lcd_screen.gdshader")

## Где на атласе текстур лежит экран (из файла модели).
const SCREEN_UV_MIN := Vector2(0.605, 0.493)
const SCREEN_UV_MAX := Vector2(0.742, 0.614)

const DPAD_CENTER := Vector3(-1.025, -0.45, -1.025)
const DPAD_HALF := 0.45
const A_CENTER := Vector3(1.17, -0.42, -0.85)
const B_CENTER := Vector3(0.67, -0.42, -1.1)
const AB_SPLIT_X := 0.92
const SELECT_CENTER := Vector3(-0.42, -0.4, -1.86)
const START_CENTER := Vector3(0.05, -0.4, -1.86)
const START_SPLIT_X := -0.19

## Насколько кнопка уходит в корпус и как сильно наклоняется крестовина.
const PRESS_DEPTH := 0.05
const DPAD_TILT := deg_to_rad(9.0)
const PRESS_SPEED := 30.0

const BUTTON_RED := Color(0.62, 0.05, 0.06)
## Модель в своих единицах шириной 343, настоящий Game Boy — 9 см.
const MODEL_SCALE := 0.09 / 343.2

var _buttons := {}
var _rest := {}
var _dpad: Node3D


## screen_texture — картинка из SubViewport с экраном Game Boy.
func setup(screen_texture: Texture2D) -> void:
	var model: Node3D = MODEL.instantiate()
	model.scale = Vector3.ONE * MODEL_SCALE
	add_child(model)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D"):
		_prepare_mesh(mesh, screen_texture)


func _prepare_mesh(mesh: MeshInstance3D, screen_texture: Texture2D) -> void:
	var name := String(mesh.name)
	# Надписи и логотипы убираем: это чужой товарный знак.
	if name.contains("TEXT_WHITE") or name.contains("Text_Blue"):
		mesh.visible = false
	elif name.contains("Screen"):
		var material := ShaderMaterial.new()
		material.shader = SCREEN_SHADER
		material.set_shader_parameter("screen_data", screen_texture)
		material.set_shader_parameter("uv_min", SCREEN_UV_MIN)
		material.set_shader_parameter("uv_max", SCREEN_UV_MAX)
		material.set_shader_parameter("flip_x", true)
		mesh.material_override = material
	elif name.contains("A_B_Buttons"):
		mesh.material_override = _tinted(mesh, BUTTON_RED)
		_add_button("gb_a", MeshSplit.extract(mesh, A_CENTER, func(p: Vector3) -> bool: return p.x > AB_SPLIT_X, "ButtonA"))
		_add_button("gb_b", MeshSplit.extract(mesh, B_CENTER, func(p: Vector3) -> bool: return p.x <= AB_SPLIT_X, "ButtonB"))
	elif name.contains("START_SELECT"):
		_add_button("gb_start", MeshSplit.extract(mesh, START_CENTER, func(p: Vector3) -> bool: return p.x > START_SPLIT_X, "ButtonStart"))
		MeshSplit.extract(mesh, SELECT_CENTER, func(p: Vector3) -> bool: return p.x <= START_SPLIT_X, "ButtonSelect")
	elif name.contains("D-PAD"):
		# Чёрный материал крестовины есть и на других деталях, берём только область крестовины спереди.
		_dpad = MeshSplit.extract(mesh, DPAD_CENTER, _is_dpad, "DPad")
		_rest[_dpad] = _dpad.transform


## Куда должен встать палец для каждой кнопки, в координатах самого Game Boy.
## Нужно инструменту tools/thumb_poses.gd.
func button_positions() -> Dictionary:
	var to_local := global_transform.affine_inverse()
	var dpad := to_local * _dpad.global_position
	var arm := Vector3(0.0075, 0.0, 0.0)
	return {
		"gb_up": dpad + Vector3(0, arm.x, 0),
		"gb_down": dpad - Vector3(0, arm.x, 0),
		"gb_left": dpad - arm,
		"gb_right": dpad + arm,
		"gb_a": to_local * _buttons["gb_a"].global_position,
		"gb_b": to_local * _buttons["gb_b"].global_position,
	}


func _is_dpad(p: Vector3) -> bool:
	return absf(p.x - DPAD_CENTER.x) < DPAD_HALF and absf(p.z - DPAD_CENTER.z) < DPAD_HALF and p.y < -0.3


func _add_button(action: String, pivot: Node3D) -> void:
	_buttons[action] = pivot
	_rest[pivot] = pivot.transform


## Перекраска: своя текстура цвета у кнопок тёмно-бордовая, поэтому заменяем её сплошным цветом,
## а карту нормалей (рельеф) оставляем.
func _tinted(mesh: MeshInstance3D, color: Color) -> Material:
	var material := mesh.get_active_material(0)
	if material is BaseMaterial3D:
		material = material.duplicate()
		material.albedo_texture = null
		material.albedo_color = color
	return material


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-PRESS_SPEED * delta)
	for action: String in _buttons:
		var pivot: Node3D = _buttons[action]
		var target: Transform3D = _rest[pivot]
		if Input.is_action_pressed(action):
			target = target.translated_local(Vector3(0, PRESS_DEPTH, 0))
		pivot.transform = pivot.transform.interpolate_with(target, blend)
	if _dpad != null:
		_dpad.transform = _dpad.transform.interpolate_with(_dpad_target(), blend)


## Крестовина качается: нажатая сторона уходит в корпус.
func _dpad_target() -> Transform3D:
	var tilt := Vector2(
		Input.get_axis("gb_left", "gb_right"),
		Input.get_axis("gb_down", "gb_up"),
	)
	var rest: Transform3D = _rest[_dpad]
	return rest.rotated_local(Vector3.FORWARD, tilt.x * DPAD_TILT).rotated_local(Vector3.RIGHT, tilt.y * DPAD_TILT)
