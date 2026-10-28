class_name HandAlign
extends SkeletonModifier3D
## Поворачивает кисти так же, как повёрнуты цели. IK ставит запястье в точку,
## а этот модификатор задаёт, куда смотрит ладонь.

## Пары «кость кисти» → узел-цель.
var pairs: Array[Dictionary] = []


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	var to_skeleton := skeleton.global_basis.orthonormalized().inverse()
	for pair in pairs:
		var bone: int = pair["bone"]
		var target: Node3D = pair["target"]
		var pose := skeleton.get_bone_global_pose(bone)
		var basis := to_skeleton * target.global_basis.orthonormalized()
		skeleton.set_bone_global_pose(bone, Transform3D(basis, pose.origin))
