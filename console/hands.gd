class_name Hands
extends Node3D
## Руки от первого лица. Берём готовую позу из модели и доворачиваем кости,
## чтобы ладони держали Game Boy, а большие пальцы лежали на кнопках.

const MODEL := preload("res://assets/hands/scene.gltf")
const BASE_POSE := "Heart Pose"

## Доворот костей поверх базовой позы, в градусах (X, Y, Z локальных осей кости).
## Подобрано по снимкам: кисти повёрнуты ладонями к корпусу, пальцы уходят за него.
@export var bone_offsets := {
	"Forearm.L_03": Vector3(0, 20, 0),
	"Hand.L_04": Vector3(40, -60, 0),
	"Forearm.R_026": Vector3(0, -20, 0),
	"Hand.R_027": Vector3(40, 60, 0),
}
## Кожа темнее и грязнее, чем в исходной текстуре, под хоррор-свет.
@export var skin_tint := Color(0.42, 0.4, 0.38)

## Большой палец: поза покоя и поза нажатия, градусы для каждой из трёх фаланг.
@export var thumb_rest := Vector3.ZERO
@export var thumb_press := Vector3(0, 0, 18)

const THUMB_L := ["Finger_5.1.L_021", "Finger_5.2.L_022", "Finger_5.3.L_023"]
const THUMB_R := ["Finger_5.1.R_044", "Finger_5.2.R_045", "Finger_5.3.R_046"]
const PRESS_SPEED := 25.0
## Какие кнопки нажимает каждый большой палец.
const LEFT_ACTIONS := ["gb_up", "gb_down", "gb_left", "gb_right"]
const RIGHT_ACTIONS := ["gb_a", "gb_b"]

var skeleton: Skeleton3D
var _base: Dictionary[int, Quaternion] = {}
var _press_left := 0.0
var _press_right := 0.0


func _ready() -> void:
	var model: Node3D = MODEL.instantiate()
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D")[0]
	var player: AnimationPlayer = model.find_children("*", "AnimationPlayer")[0]
	player.play(BASE_POSE)
	player.seek(0.0, true)
	player.stop(true)
	_apply_offsets()
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D"):
		var material := mesh.get_active_material(0)
		if material is BaseMaterial3D:
			material = material.duplicate()
			material.albedo_color = skin_tint
			# Своя карта шероховатости делает кожу глянцевой, нам нужна матовая.
			material.roughness_texture = null
			material.roughness = 0.85
			material.metallic = 0.0
			material.metallic_specular = 0.25
			mesh.material_override = material


## Запоминаем позу после доворотов: от неё считаем нажатия.
func _apply_offsets() -> void:
	for bone_name: String in bone_offsets:
		var bone := skeleton.find_bone(bone_name)
		var euler: Vector3 = bone_offsets[bone_name] * (PI / 180.0)
		var rotation := skeleton.get_bone_pose_rotation(bone) * Quaternion.from_euler(euler)
		skeleton.set_bone_pose_rotation(bone, rotation)
	for bone_name: String in THUMB_L + THUMB_R:
		var bone := skeleton.find_bone(bone_name)
		_base[bone] = skeleton.get_bone_pose_rotation(bone)


## Точка между плечами — от неё считаем положение глаз.
func shoulders() -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Shoulder.L_00")).origin


## Кончики больших пальцев в мировых координатах.
func thumb_tips() -> Dictionary:
	return {
		"left": skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Finger_5.3.L_end_051")).origin,
		"right": skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Finger_5.3.R_end_056")).origin,
	}


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-PRESS_SPEED * delta)
	_press_left = lerpf(_press_left, 1.0 if _any_pressed(LEFT_ACTIONS) else 0.0, blend)
	_press_right = lerpf(_press_right, 1.0 if _any_pressed(RIGHT_ACTIONS) else 0.0, blend)
	_pose_thumb(THUMB_L, _press_left, 1.0)
	_pose_thumb(THUMB_R, _press_right, -1.0)


func _any_pressed(actions: Array) -> bool:
	for action: String in actions:
		if Input.is_action_pressed(action):
			return true
	return false


## side зеркалит повороты для правой руки.
func _pose_thumb(bones: Array, press: float, side: float) -> void:
	var euler := thumb_rest.lerp(thumb_press, press) * (PI / 180.0)
	euler.y *= side
	euler.z *= side
	for bone_name: String in bones:
		var bone := skeleton.find_bone(bone_name)
		skeleton.set_bone_pose_rotation(bone, _base[bone] * Quaternion.from_euler(euler))
