extends Node3D
## Сцена игры от первого лица: руки держат Game Boy, свеча, темнота.
## Game Boy ставится под большие пальцы автоматически, поэтому позу рук можно менять без ручной подгонки.

## Глаза выше и чуть позади плеч.
const EYE_OFFSET := Vector3(0, 0.22, 0.05)
## Небольшой зазор, чтобы большие пальцы лежали на кнопках, а не проваливались в них.
const THUMB_GAP := 0.004
## Наклон рук с Game Boy к лицу.
const RIG_TILT := deg_to_rad(18.0)

@onready var _viewport: SubViewport = $ScreenViewport
@onready var _rig: Node3D = $Rig
@onready var _hands: Hands = $Rig/Hands
@onready var _gameboy: GameBoy = $Rig/GameBoy
@onready var _camera: PlayerCamera = $Camera3D


func _ready() -> void:
	_gameboy.setup(_viewport.get_texture())
	_place_gameboy()
	var eye := _hands.shoulders() + EYE_OFFSET
	# Наклоняем руки с Game Boy вокруг точки хвата, экраном к глазам.
	var pivot := _gameboy.global_position
	_rig.global_transform = Transform3D(Basis(Vector3.RIGHT, RIG_TILT), pivot) \
			* Transform3D(Basis.IDENTITY, -pivot) * _rig.global_transform
	_camera.place(eye, _gameboy.global_position)


## Сдвигаем Game Boy так, чтобы середина между крестовиной и A/B оказалась под большими пальцами.
func _place_gameboy() -> void:
	var tips := _hands.thumb_tips()
	var buttons := _gameboy.thumbs_target()
	var tips_mid: Vector3 = (tips["left"] + tips["right"]) * 0.5
	var buttons_mid: Vector3 = (buttons["left"] + buttons["right"]) * 0.5
	_gameboy.global_position += tips_mid - buttons_mid + Vector3(0, 0, -THUMB_GAP)
