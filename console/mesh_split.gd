class_name MeshSplit
extends RefCounted
## Вырезает часть меша в отдельный MeshInstance3D.
## Нужно, потому что в модели кнопки A и B (и Start с Select) — один меш, а нажимать их надо по отдельности.


## Переносит в новый узел треугольники, центр которых проходит проверку keep(центр).
## Новый узел висит на опоре (Node3D) в точке pivot, чтобы кнопку можно было двигать и наклонять.
## Возвращает опору. Исходный меш теряет эти треугольники.
static func extract(source: MeshInstance3D, pivot: Vector3, keep: Callable, pivot_name: String) -> Node3D:
	var original: Mesh = source.mesh
	var taken := ArrayMesh.new()
	var left := ArrayMesh.new()
	for surface in original.get_surface_count():
		var arrays := original.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			indices = PackedInt32Array(range(vertices.size()))
		var taken_indices := PackedInt32Array()
		var left_indices := PackedInt32Array()
		for i in range(0, indices.size(), 3):
			var center := (vertices[indices[i]] + vertices[indices[i + 1]] + vertices[indices[i + 2]]) / 3.0
			var target := taken_indices if keep.call(center) else left_indices
			target.append_array([indices[i], indices[i + 1], indices[i + 2]])
		var material := original.surface_get_material(surface)
		_add_surface(taken, arrays, taken_indices, material)
		_add_surface(left, arrays, left_indices, material)
	source.mesh = left

	var holder := Node3D.new()
	holder.name = pivot_name
	holder.transform = source.transform.translated_local(pivot)
	source.get_parent().add_child(holder)
	var part := MeshInstance3D.new()
	part.mesh = taken
	part.position = -pivot
	part.material_override = source.material_override
	holder.add_child(part)
	return holder


static func _add_surface(mesh: ArrayMesh, arrays: Array, indices: PackedInt32Array,
		material: Material) -> void:
	if indices.is_empty():
		return
	var copy := arrays.duplicate()
	copy[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, copy)
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)
