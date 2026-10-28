class_name MenuTitle
extends Node3D
## Надпись SNAKE перед камерой меню. Наклоняется к курсору: сторона ближе к курсору
## уходит вглубь, противоположная приподнимается.

const SHADER := preload("res://menu/title.gdshader")
## Ширина надписи в метрах, высота считается по картинке.
const WIDTH := 0.62
const MAX_TILT := Vector2(18.0, 12.0)
const FOLLOW_SPEED := 6.0

var _tilt := Vector2.ZERO
var _mesh: MeshInstance3D


func _ready() -> void:
	var texture := TitleArt.build()
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("art", texture)
	material.set_shader_parameter("art_size", Vector2(texture.get_size()))
	var quad := QuadMesh.new()
	quad.size = Vector2(WIDTH, WIDTH * texture.get_height() / texture.get_width())
	_mesh = MeshInstance3D.new()
	_mesh.mesh = quad
	_mesh.material_override = material
	add_child(_mesh)


func _process(delta: float) -> void:
	var viewport := get_viewport()
	var size := viewport.get_visible_rect().size
	# Положение курсора от −1 до 1 по каждой оси.
	var cursor := (viewport.get_mouse_position() / size) * 2.0 - Vector2.ONE
	var target := Vector2(cursor.y, cursor.x) * MAX_TILT
	_tilt = _tilt.lerp(target, 1.0 - exp(-FOLLOW_SPEED * delta))
	_mesh.rotation_degrees = Vector3(_tilt.x, _tilt.y, 0.0)
