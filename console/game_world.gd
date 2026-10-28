extends Node3D
## Сцена игры от первого лица: руки держат Game Boy, свеча, темнота.
## Game Boy стоит перед камерой экраном к лицу, как телефон. Руки сами тянутся
## к точкам хвата на корпусе (IK), поэтому корпус можно двигать, не трогая позу.

const EYE := Vector3(0, 1.5, 0)
## Взгляд вниз на Game Boy.
const VIEW_PITCH := deg_to_rad(-28.0)
## Расстояние от глаз до экрана.
const SCREEN_DISTANCE := 0.2
## Центр экрана выше центра корпуса — так экран оказывается по центру кадра.
const SCREEN_ABOVE_CENTER := 0.033
## Плечи ниже глаз и чуть впереди.
const SHOULDERS_FROM_EYE := Vector3(0, -0.22, -0.03)

@onready var _viewport: SubViewport = $ScreenViewport
@onready var _hands: Hands = $Hands
@onready var _gameboy: GameBoy = $GameBoy
@onready var _camera: PlayerCamera = $Camera3D


func _ready() -> void:
	var view := Basis(Vector3.RIGHT, VIEW_PITCH)
	_camera.set_base(Transform3D(view, EYE))
	# Тот же поворот, что у камеры: экран смотрит прямо в глаза.
	var screen_center := EYE + view * Vector3(0, 0, -SCREEN_DISTANCE)
	_gameboy.global_transform = Transform3D(view, screen_center - view * Vector3(0, SCREEN_ABOVE_CENTER, 0))
	_gameboy.setup(_viewport.get_texture())
	_hands.global_position += EYE + SHOULDERS_FROM_EYE - _hands.shoulders()
	_hands.hold(_gameboy)
