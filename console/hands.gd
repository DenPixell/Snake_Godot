class_name Hands
extends Node3D
## Руки от первого лица. Кисти держат Game Boy за точки хвата на корпусе:
## IK (TwoBoneIK3D) подтягивает плечо и локоть, HandAlign поворачивает кисть,
## пальцы берутся из готовой позы модели, большие пальцы нажимают кнопки.

const MODEL := preload("res://assets/hands/scene.gltf")
const BASE_POSE := "Heart Pose"

## Хват левой руки в координатах Game Boy (метры): где запястье. Правая рука — зеркально.
@export var grip_position := Vector3(-0.0491, -0.0903, -0.0223)
## Куда смотрят пальцы левой руки и куда обращена ладонь (направления в координатах Game Boy).
## Подобрано по точкам касания: ладонь на боку и задней крышке, пальцы за корпусом,
## прямой большой палец сам смотрит на крестовину.
@export var grip_fingers := Vector3(-0.0295, 0.9202, -0.3904)
@export var grip_palm := Vector3(0.9752, 0.1122, 0.1908)
## Куда смотрит локоть левой руки, тоже в координатах Game Boy.
@export var elbow_hint := Vector3(-0.3, -0.3, 0.05)
## Кожа темнее и грязнее, чем в исходной текстуре, под хоррор-свет.
@export var skin_tint := Color(0.42, 0.4, 0.38)

## Сгиб остальных пальцев к ладони, градусы на каждую фалангу.
@export var finger_curl := 54.6

## Позы большого пальца (градусы). base — первая фаланга, tip — две следующие.
## Углы посчитаны так, чтобы кончик пальца попадал в нужную кнопку, палец шёл к ней
## по диагонали от нижнего угла и не проваливался в корпус. Правая рука — зеркально.
@export var thumb_left := {
	"rest": {"base": Vector3(-2.8, 37.0, -46.7), "tip": Vector3(-45.1, 5.6, 21.9)},
	"gb_up": {"base": Vector3(-2.3, 38.3, -39.2), "tip": Vector3(-40.2, 9.7, 24.6)},
	"gb_down": {"base": Vector3(-2.9, 36.5, -49.5), "tip": Vector3(-52.2, 1.3, 19.9)},
	"gb_left": {"base": Vector3(0.6, 36.1, -52.5), "tip": Vector3(-50.8, 5.5, 23.4)},
	"gb_right": {"base": Vector3(-5.5, 38.6, -37.1), "tip": Vector3(-41.7, 5.7, 21.4)},
}
@export var thumb_right := {
	"rest": {"base": Vector3(-8.2, 32.2, -43.4), "tip": Vector3(-42.4, 3.4, 29.2)},
	"gb_a": {"base": Vector3(-5.3, 32.0, -45.4), "tip": Vector3(-44.4, 5.2, 31.9)},
	"gb_b": {"base": Vector3(-10.3, 33.4, -36.0), "tip": Vector3(-41.4, 2.2, 27.9)},
}

## Оси кости кисти в модели: пальцы смотрят вдоль +Y, ладонь — в сторону −X.
const HAND_FINGERS_AXIS := Vector3.UP
const HAND_PALM_AXIS := Vector3.LEFT
## Сгиб фаланги к ладони — поворот вокруг локальной оси Z кости пальца.
const FINGER_FLEX_AXIS := Vector3.BACK

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


## Пальцы 1–4 (кроме большого): три фаланги на каждом, обе руки.
func _curl_fingers() -> void:
	for bone in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(bone)
		if not bone_name.begins_with("Finger_") or bone_name.begins_with("Finger_5"):
			continue
		if bone_name.contains("_end") or bone_name.contains(".4."):
			continue
		var side := 1.0 if bone_name.contains(".L") else -1.0
		var rotation := Quaternion(FINGER_FLEX_AXIS, deg_to_rad(finger_curl) * side)
		skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * rotation)


## Поворот кисти, при котором пальцы смотрят по fingers, а ладонь — по palm.
static func grip_basis(fingers: Vector3, palm: Vector3) -> Basis:
	var y := fingers.normalized()
	var x := -(palm - y * palm.dot(y)).normalized()
	return Basis(x, y, x.cross(y))


## Привязывает руки к Game Boy: создаёт на нём цели хвата и подключает IK.
func hold(gameboy: Node3D) -> void:
	var targets: Array[Node3D] = []
	var poles: Array[Node3D] = []
	for side: float in [1.0, -1.0]:
		var mirror := Vector3(side, 1.0, 1.0)
		var target := Marker3D.new()
		target.position = grip_position * mirror
		# Правая рука — зеркальная копия левой относительно вертикальной оси корпуса.
		var flip := Basis.from_scale(mirror)
		target.basis = flip * grip_basis(grip_fingers, grip_palm) * flip
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
