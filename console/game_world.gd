extends Node3D
## Сцена игры от первого лица: руки держат Game Boy, свеча, темнота.
## Камера, руки и место Game Boy берутся из сцены позы console/hold_pose.tscn,
## её можно править прямо в редакторе.

@onready var _viewport: SubViewport = $ScreenViewport
@onready var _gameboy: GameBoy = $GameBoy
@onready var _anchor: Node3D = $HoldPose/GameBoyAnchor


func _ready() -> void:
	# В сцене позы стоит простая модель Game Boy для наглядности, в игре её заменяет настоящий.
	_anchor.get_node("Preview").queue_free()
	_gameboy.global_transform = _anchor.global_transform
	_gameboy.setup(_viewport.get_texture())
