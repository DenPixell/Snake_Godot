class_name Hands
extends Node3D
## Руки от первого лица. Поза рук выставлена вручную в сцене console/hold_pose.tscn:
## там можно крутить кости Skeleton3D прямо в редакторе. Скрипт только затемняет кожу
## и двигает большие пальцы при нажатиях — поверх позы из сцены.

## Кожа темнее и грязнее, чем в исходной текстуре, под хоррор-свет.
@export var skin_tint := Color(0.42, 0.4, 0.38)

## Сдвиги больших пальцев при нажатиях. Пересчитываются инструментом tools/thumb_poses.gd
## после того, как поза рук в hold_pose.tscn изменилась.
@export var thumb_poses: ThumbPoses = preload("res://console/thumb_poses.tres")

const THUMB_L := ["Finger_5.1.L_021", "Finger_5.2.L_022", "Finger_5.3.L_023"]
const THUMB_R := ["Finger_5.1.R_044", "Finger_5.2.R_045", "Finger_5.3.R_046"]
const PRESS_SPEED := 25.0

const REST := {"base": Vector3.ZERO, "tip": Vector3.ZERO}

var skeleton: Skeleton3D
## Повороты фаланг большого пальца из сцены — от них считаем нажатия.
var _base: Dictionary[int, Quaternion] = {}
var _thumb_left := {}
var _thumb_right := {}


func _ready() -> void:
	skeleton = find_children("*", "Skeleton3D")[0]
	for bone_name: String in THUMB_L + THUMB_R:
		var bone := skeleton.find_bone(bone_name)
		_base[bone] = skeleton.get_bone_pose_rotation(bone)
	_darken_skin()


func _darken_skin() -> void:
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D"):
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
	_thumb_left = _blend_pose(_thumb_left, _thumb_target(thumb_poses.left), blend)
	_thumb_right = _blend_pose(_thumb_right, _thumb_target(thumb_poses.right), blend)
	_pose_thumb(THUMB_L, _thumb_left, 1.0)
	_pose_thumb(THUMB_R, _thumb_right, -1.0)


## Сдвиг пальца для первой зажатой кнопки или ноль — поза из сцены.
func _thumb_target(poses: Dictionary) -> Dictionary:
	for action: String in poses:
		if Input.is_action_pressed(action):
			return poses[action]
	return REST


func _blend_pose(current: Dictionary, target: Dictionary, weight: float) -> Dictionary:
	if current.is_empty():
		return target.duplicate()
	return {
		"base": (current["base"] as Vector3).lerp(target["base"], weight),
		"tip": (current["tip"] as Vector3).lerp(target["tip"], weight),
	}


## Первая фаланга получает base, две следующие — tip. side зеркалит правую руку.
## Публичная версия нужна инструменту tools/thumb_poses.gd.
func pose_thumb(left_hand: bool, pose: Dictionary) -> void:
	if left_hand:
		_pose_thumb(THUMB_L, pose, 1.0)
	else:
		_pose_thumb(THUMB_R, pose, -1.0)


func _pose_thumb(bones: Array, pose: Dictionary, side: float) -> void:
	var mirror := Vector3(1.0, side, side) * (PI / 180.0)
	for i in bones.size():
		var degrees: Vector3 = pose["base"] if i == 0 else pose["tip"]
		var bone := skeleton.find_bone(bones[i])
		skeleton.set_bone_pose_rotation(bone, _base[bone] * Quaternion.from_euler(degrees * mirror))
