extends Node3D
## Весь мир игры: комната, главное меню и игра от первого лица.
## Состояния: главное меню → переход (камера едет к Game Boy, руки поднимают его) → игра.
## Камера, руки и место Game Boy в руках берутся из сцены позы console/hold_pose.tscn.

enum State { MENU, TRANSITION, PLAYING, PAUSED }

## Откуда смотрит камера в главном меню и куда.
@export var menu_camera_position := Vector3(-0.85, 1.4, 0.15)
@export var menu_camera_target := Vector3(-0.55, 1.0, -0.45)
## Где руки ждут в меню: ниже кадра, потом поднимаются вместе с Game Boy.
const HANDS_HIDDEN_OFFSET := Vector3(0, -0.45, 0.15)
const CAMERA_MOVE_TIME := 2.2
const LIFT_DELAY := 0.7
const LIFT_TIME := 1.4

var state := State.MENU

var _hold_transform: Transform3D
var _hands_rest: Transform3D

@onready var _viewport: SubViewport = $ScreenViewport
@onready var _handheld: Handheld = $ScreenViewport/Handheld
@onready var _gameboy: GameBoy = $GameBoy
@onready var _anchor: Node3D = $HoldPose/GameBoyAnchor
@onready var _camera: PlayerCamera = $HoldPose/Camera3D
@onready var _hands: Node3D = $HoldPose/Hands
@onready var _menu_view: Node3D = $MenuView
@onready var _table_spot: Node3D = $Room/GameBoyOnTable
@onready var _menu: MainMenu = $UI/MainMenu
@onready var _pause := PauseMenu.new()
@onready var _settings := SettingsMenu.new()
@onready var _tutorial := TutorialMenu.new()


func _ready() -> void:
	# В сцене позы стоит простая модель Game Boy для наглядности, в игре её заменяет настоящий.
	_anchor.get_node("Preview").queue_free()
	_hold_transform = _anchor.global_transform
	_hands_rest = _hands.transform
	_gameboy.setup(_viewport.get_texture())
	_menu_view.global_transform = Transform3D.IDENTITY.looking_at(
			menu_camera_target - menu_camera_position).translated(menu_camera_position)
	_menu.play_pressed.connect(_start_game)
	_menu.settings_pressed.connect(_open_settings)
	_menu.tutorial_pressed.connect(_open_tutorial)
	$UI.add_child(_pause)
	$UI.add_child(_settings)
	$UI.add_child(_tutorial)
	_pause.visible = false
	_settings.visible = false
	_tutorial.visible = false
	_tutorial.closed.connect(_show_main_menu)
	# Заставка про наушники — поверх всего, только при запуске игры.
	var splash := Splash.new()
	$UI.add_child(splash)
	_pause.continue_pressed.connect(_resume)
	_pause.settings_pressed.connect(_open_settings)
	_pause.main_menu_pressed.connect(_back_to_main_menu)
	_settings.closed.connect(_on_settings_closed)
	_handheld.beep.connect(_gameboy.play_sound)
	add_child(Ambience.new())
	# В модели три подсвечника, на столе нужен только простой на одну свечу.
	for unused: String in ["brass_candleholder_02", "brass_candleholder_03"]:
		$Room/Candles.find_child(unused).visible = false
	_enter_menu()


func _enter_menu() -> void:
	state = State.MENU
	_camera.deactivate()
	_camera.global_transform = _menu_view.global_transform
	_gameboy.global_transform = _table_spot.global_transform
	_gameboy.set_screen_on(false)
	_hands.visible = false
	_hands.transform = _hands_rest.translated(HANDS_HIDDEN_OFFSET)
	# Пока Game Boy лежит на столе, он не реагирует на кнопки.
	_handheld.process_mode = Node.PROCESS_MODE_DISABLED
	_gameboy.input_enabled = false
	_menu.visible = true
	_menu_view.visible = true


func _start_game() -> void:
	if state != State.MENU:
		return
	state = State.TRANSITION
	_menu.visible = false
	_menu_view.visible = false
	_hands.visible = true
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_camera, "global_transform", _camera.base_transform(), CAMERA_MOVE_TIME)
	tween.tween_property(_gameboy, "global_transform", _hold_transform, LIFT_TIME).set_delay(LIFT_DELAY)
	tween.tween_property(_hands, "transform", _hands_rest, LIFT_TIME).set_delay(LIFT_DELAY)
	tween.chain().tween_callback(_begin_playing)


func _begin_playing() -> void:
	_gameboy.set_screen_on(true)
	_resume()


## Esc: в игре открывает паузу, на паузе — продолжает, в настройках — закрывает их.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_menu"):
		return
	if _settings.visible:
		_settings.close()
	elif _tutorial.visible:
		_tutorial.close()
	elif state == State.PLAYING:
		_pause_game()
	elif state == State.PAUSED:
		_resume()
	get_viewport().set_input_as_handled()


func _pause_game() -> void:
	state = State.PAUSED
	_handheld.pause_game()
	_handheld.process_mode = Node.PROCESS_MODE_DISABLED
	_gameboy.input_enabled = false
	_camera.deactivate()
	_pause.visible = true


func _resume() -> void:
	state = State.PLAYING
	_pause.visible = false
	_handheld.process_mode = Node.PROCESS_MODE_INHERIT
	_gameboy.input_enabled = true
	_camera.activate()


func _back_to_main_menu() -> void:
	_pause.visible = false
	_handheld.reset()
	_enter_menu()


func _open_settings() -> void:
	_menu.visible = false
	_menu_view.visible = false
	_pause.visible = false
	_settings.visible = true


func _open_tutorial() -> void:
	_menu.visible = false
	_menu_view.visible = false
	_tutorial.visible = true


func _show_main_menu() -> void:
	_menu.visible = true
	_menu_view.visible = true


## Настройки возвращают туда, откуда их открыли: в главное меню или в паузу.
func _on_settings_closed() -> void:
	if state == State.MENU:
		_show_main_menu()
	else:
		_pause.visible = true
