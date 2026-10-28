extends SceneTree
## Пересчитывает, как большие пальцы двигаются к кнопкам, под текущую позу рук из
## console/hold_pose.tscn. Результат пишет в console/thumb_poses.tres.
##
## Запуск (из папки проекта):
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s tools/thumb_poses.gd
##
## Как считается: для каждой кнопки подбираем шесть углов (две группы фаланг по три оси),
## чтобы кончик пальца встал на кнопку и чуть вдавил её, а средний сустав не ушёл
## в корпус. Метод — Гаусс — Ньютон с численными производными и проверкой шага.

const OUTPUT := "res://console/thumb_poses.tres"
## Насколько кончик пальца опускается при нажатии, метры.
const PRESS_DEPTH := 0.003
## Сдвиг по крестовине от её центра до нужного плеча, метры.
const DPAD_ARM := 0.0075
## Ниже этой высоты над центром корпуса средний сустав пальца уже в корпусе, метры.
const KNUCKLE_MIN_Z := 0.019
const DERIVATIVE_STEP := 1.0
const ITERATIONS := 20

var _hands: Hands
var _gameboy: GameBoy
var _skeleton: Skeleton3D


func _initialize() -> void:
	# Узлы попадают в дерево только после первого кадра, поэтому всё — отложенно.
	_setup.call_deferred()


func _setup() -> void:
	var pose: Node3D = load("res://console/hold_pose.tscn").instantiate()
	root.add_child(pose)
	_hands = pose.get_node("Hands")
	var anchor: Node3D = pose.get_node("GameBoyAnchor")
	_gameboy = GameBoy.new()
	root.add_child(_gameboy)
	_gameboy.global_transform = anchor.global_transform
	_gameboy.setup(ImageTexture.new())
	_skeleton = _hands.skeleton
	_solve_all()


func _solve_all() -> void:
	var buttons := _gameboy.button_positions()
	var result := ThumbPoses.new()
	for left_hand: bool in [true, false]:
		var actions: Array = ["gb_up", "gb_down", "gb_left", "gb_right"] if left_hand else ["gb_a", "gb_b"]
		var rest_tip := _tip(left_hand, ThumbPoses_zero())
		var poses := {}
		for action: String in actions:
			var target: Vector3 = buttons[action]
			target.z = rest_tip.z - PRESS_DEPTH
			var solved := _solve(left_hand, target)
			poses[action] = {"base": solved[0], "tip": solved[1]}
			var error := _tip(left_hand, poses[action]).distance_to(target) * 1000.0
			print("%s: ошибка %.1f мм, base %s, tip %s" % [action, error, solved[0], solved[1]])
		if left_hand:
			result.left = poses
		else:
			result.right = poses
	var error := ResourceSaver.save(result, OUTPUT)
	print("Сохранено в %s: %s" % [OUTPUT, error_string(error)])
	quit(0 if error == OK else 1)


static func ThumbPoses_zero() -> Dictionary:
	return {"base": Vector3.ZERO, "tip": Vector3.ZERO}


## Кончик и средний сустав большого пальца в координатах Game Boy при заданных углах.
func _tip(left_hand: bool, pose: Dictionary) -> Vector3:
	return _points(left_hand, pose)[0]


func _points(left_hand: bool, pose: Dictionary) -> Array[Vector3]:
	_hands.pose_thumb(left_hand, pose)
	var to_gameboy := _gameboy.global_transform.affine_inverse() * _skeleton.global_transform
	var tip_bone := "Finger_5.3.L_end_051" if left_hand else "Finger_5.3.R_end_056"
	var knuckle_bone := "Finger_5.3.L_023" if left_hand else "Finger_5.3.R_046"
	return [
		to_gameboy * _skeleton.get_bone_global_pose(_skeleton.find_bone(tip_bone)).origin,
		to_gameboy * _skeleton.get_bone_global_pose(_skeleton.find_bone(knuckle_bone)).origin,
	]


## Невязка: куда не дотянулся кончик (3 числа) и насколько сустав ушёл в корпус (1 число).
func _residual(left_hand: bool, params: PackedFloat64Array, target: Vector3) -> PackedFloat64Array:
	var points := _points(left_hand, _to_pose(params))
	var miss := target - points[0]
	return PackedFloat64Array([miss.x, miss.y, miss.z, maxf(0.0, KNUCKLE_MIN_Z - points[1].z) * 2.0])


func _to_pose(p: PackedFloat64Array) -> Dictionary:
	return {"base": Vector3(p[0], p[1], p[2]), "tip": Vector3(p[3], p[4], p[5])}


func _norm(v: PackedFloat64Array) -> float:
	var sum := 0.0
	for x in v:
		sum += x * x
	return sqrt(sum)


func _solve(left_hand: bool, target: Vector3) -> Array[Vector3]:
	var params := PackedFloat64Array([0, 0, 0, 0, 0, 0])
	var residual := _residual(left_hand, params, target)
	for iteration in ITERATIONS:
		# Численные производные: как меняется невязка при повороте на 1 градус по каждой оси.
		var jacobian: Array[PackedFloat64Array] = []
		for k in 6:
			var shifted := params.duplicate()
			shifted[k] += DERIVATIVE_STEP
			var r := _residual(left_hand, shifted, target)
			var column := PackedFloat64Array()
			for i in r.size():
				column.append((residual[i] - r[i]) / DERIVATIVE_STEP)
			jacobian.append(column)
		var step := _least_squares(jacobian, residual)
		# Берём полный шаг или его часть — что уменьшает невязку сильнее.
		var best := params
		var best_residual := residual
		for scale in [1.0, 0.5, 0.25]:
			var candidate := params.duplicate()
			for k in 6:
				candidate[k] += clampf(step[k] * scale, -15.0, 15.0)
			var r := _residual(left_hand, candidate, target)
			if _norm(r) < _norm(best_residual):
				best = candidate
				best_residual = r
		if best == params:
			break
		params = best
		residual = best_residual
	_hands.pose_thumb(left_hand, ThumbPoses_zero())
	return [Vector3(params[0], params[1], params[2]), Vector3(params[3], params[4], params[5])]


## Решение (JᵀJ + λI)·x = Jᵀr методом Гаусса. Маленькое λ сглаживает шаг.
func _least_squares(columns: Array[PackedFloat64Array], residual: PackedFloat64Array) -> PackedFloat64Array:
	var n := columns.size()
	var matrix: Array[PackedFloat64Array] = []
	for i in n:
		var row := PackedFloat64Array()
		for j in n:
			var sum := 0.0
			for k in residual.size():
				sum += columns[i][k] * columns[j][k]
			row.append(sum + (1e-9 if i == j else 0.0))
		var rhs := 0.0
		for k in residual.size():
			rhs += columns[i][k] * residual[k]
		row.append(rhs)
		matrix.append(row)
	for c in n:
		var pivot := c
		for r in range(c + 1, n):
			if absf(matrix[r][c]) > absf(matrix[pivot][c]):
				pivot = r
		var tmp := matrix[c]
		matrix[c] = matrix[pivot]
		matrix[pivot] = tmp
		for r in n:
			if r != c and matrix[c][c] != 0.0:
				var f := matrix[r][c] / matrix[c][c]
				for k in n + 1:
					matrix[r][k] -= f * matrix[c][k]
	var result := PackedFloat64Array()
	for i in n:
		result.append(matrix[i][n] / matrix[i][i] if matrix[i][i] != 0.0 else 0.0)
	return result
