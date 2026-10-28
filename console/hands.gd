class_name Hands
extends Node3D
## Руки от первого лица. Кисти держат Game Boy за точки хвата на корпусе:
## IK (TwoBoneIK3D) подтягивает плечо и локоть, HandAlign поворачивает кисть,
## пальцы берутся из готовой позы модели, большие пальцы нажимают кнопки.

const MODEL := preload("res://assets/hands/scene.gltf")
const BASE_POSE := "Heart Pose"

## Хват левой руки в координатах Game Boy (метры и градусы). Правая — зеркально.
@export var grip_position := Vector3(-0.062, -0.095, -0.028)
@export var grip_rotation := Vector3(40.7, -161.5, 46.6)
## Доворот кисти в осях самого Game Boy (X — к экрану/от экрана, Z — в плоскости экрана), градусы.
@export var grip_twist := Vector3(0, 0, 60)
## Куда смотрит локоть левой руки, тоже в координатах Game Boy.
@export var elbow_hint := Vector3(-0.3, -0.3, 0.05)
## Кожа темнее и грязнее, чем в исходной текстуре, под хоррор-свет.
@export var skin_tint := Color(0.42, 0.4, 0.38)

## Сгиб остальных пальцев, чтобы они обхватывали корпус сзади (градусы на каждую фалангу).
@export var finger_curl := Vector3(35, 0, 0)

## Позы большого пальца (градусы). base — основание пальца: им палец ходит влево-вправо
## и переключается между A и B. tip — две верхние фаланги: ими палец сгибается вверх-вниз.
## Углы посчитаны так, чтобы кончик пальца попадал в нужную кнопку. Правая рука — зеркально.
@export var thumb_left := {
	"rest": {"base": Vector3(-6.1, 1.7, 18.3), "tip": Vector3(-14.0, 5.8, 0.9)},
	"gb_up": {"base": Vector3(-6.1, 1.7, 18.3), "tip": Vector3(-3.3, 44.2, -7.8)},
	"gb_down": {"base": Vector3(-6.1, 1.7, 18.3), "tip": Vector3(11.1, 64.4, -29.2)},
	"gb_left": {"base": Vector3(3.7, 4.0, 11.3), "tip": Vector3(-22.1, 4.0, -3.9)},
	"gb_right": {"base": Vector3(-25.6, 50.5, -12.4), "tip": Vector3(-14.0, 5.8, 0.9)},
}
@export var thumb_right := {
	"rest": {"base": Vector3(-9.5, 1.6, 20.4), "tip": Vector3(-10.5, 6.1, 3.8)},
	"gb_a": {"base": Vector3(-0.7, 3.6, 13.7), "tip": Vector3(-15.9, 5.0, 0.9)},
	"gb_b": {"base": Vector3(-16.7, 12.4, 20.1), "tip": Vector3(-10.5, 6.1, 3.8)},
}

const ARM_L := ["Shoulder_2.L_02", "Forearm.L_03", "Hand.L_04"]
const ARM_R := ["Shoulder_2.R_025", "Forearm.R_026", "Hand.R_027"]
const THUMB_L := ["Finger_5.1.L_021", "Finger_5.2.L_022", "Finger_5.3.L_023"]
const THUMB_R := ["Finger_5.1.R_044", "Finger_5.2.R_045", "Finger_5.3.R_046"]
const PRESS_SPEED := 25.0

var skeleton: Skeleton3D
var _base: Dictionary[int, Quaternion] = {}
var _thumb_left := {}
var _thumb_right := {}


func _ready() -> void:
	var model: Node3D = MODEL.instantiate()
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D")[0]
	var player: AnimationPlayer = model.find_children("*", "AnimationPlayer")[0]
	player.play(BASE_POSE)
	player.seek(0.0, true)
	player.stop(true)
	_curl_fingers()
	for bone_name: String in THUMB_L + THUMB_R:
		var bone := skeleton.find_bone(bone_name)
		_base[bone] = skeleton.get_bone_pose_rotation(bone)
	_darken_skin(model)


## Пальцы 1–4 (кроме большого), три фаланги на каждом, обе руки.
func _curl_fingers() -> void:
	for bone in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(bone)
		if not bone_name.begins_with("Finger_") or bone_name.begins_with("Finger_5") or bone_name.contains("_end"):
			continue
		if bone_name.contains(".4."):
			continue
		var side := 1.0 if bone_name.contains(".L") else -1.0
		var euler := finger_curl * Vector3(1.0, side, side) * (PI / 180.0)
		skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * Quaternion.from_euler(euler))


## Привязывает руки к Game Boy: создаёт на нём цели хвата и подключает IK.
func hold(gameboy: Node3D) -> void:
	var targets: Array[Node3D] = []
	var poles: Array[Node3D] = []
	for side: float in [1.0, -1.0]:
		var mirror := Vector3(side, 1.0, 1.0)
		var target := Marker3D.new()
		target.position = grip_position * mirror
		var euler := grip_rotation * Vector3(1.0, side, side) * (PI / 180.0)
		var twist := grip_twist * Vector3(1.0, side, side) * (PI / 180.0)
		target.basis = Basis.from_euler(twist) * Basis.from_euler(euler)
		gameboy.add_child(target)
		targets.append(target)
		var pole := Marker3D.new()
		pole.position = elbow_hint * mirror
		gameboy.add_child(pole)
		poles.append(pole)

	var ik := TwoBoneIK3D.new()
	skeleton.add_child(ik)
	ik.setting_count = 2
	for i in 2:
		var arm: Array = ARM_L if i == 0 else ARM_R
		ik.set_root_bone_name(i, arm[0])
		ik.set_middle_bone_name(i, arm[1])
		ik.set_end_bone_name(i, arm[2])
		ik.set_target_node(i, ik.get_path_to(targets[i]))
		ik.set_pole_node(i, ik.get_path_to(poles[i]))

	var align := HandAlign.new()
	for i in 2:
		var arm: Array = ARM_L if i == 0 else ARM_R
		align.pairs.append({"bone": skeleton.find_bone(arm[2]), "target": targets[i]})
	skeleton.add_child(align)


## Точка между плечами — от неё ставим руки относительно камеры.
func shoulders() -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Shoulder.L_00")).origin


func _darken_skin(model: Node3D) -> void:
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


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-PRESS_SPEED * delta)
	_thumb_left = _blend_pose(_thumb_left, _thumb_target(thumb_left), blend)
	_thumb_right = _blend_pose(_thumb_right, _thumb_target(thumb_right), blend)
	_pose_thumb(THUMB_L, _thumb_left, 1.0)
	_pose_thumb(THUMB_R, _thumb_right, -1.0)


## Поза пальца для первой зажатой кнопки или поза покоя.
func _thumb_target(poses: Dictionary) -> Dictionary:
	for action: String in poses:
		if action != "rest" and Input.is_action_pressed(action):
			return poses[action]
	return poses["rest"]


func _blend_pose(current: Dictionary, target: Dictionary, weight: float) -> Dictionary:
	if current.is_empty():
		return target.duplicate()
	return {
		"base": (current["base"] as Vector3).lerp(target["base"], weight),
		"tip": (current["tip"] as Vector3).lerp(target["tip"], weight),
	}


## Первая фаланга получает base, две следующие — tip. side зеркалит правую руку.
func _pose_thumb(bones: Array, pose: Dictionary, side: float) -> void:
	var mirror := Vector3(1.0, side, side) * (PI / 180.0)
	for i in bones.size():
		var degrees: Vector3 = pose["base"] if i == 0 else pose["tip"]
		var bone := skeleton.find_bone(bones[i])
		skeleton.set_bone_pose_rotation(bone, _base[bone] * Quaternion.from_euler(degrees * mirror))
