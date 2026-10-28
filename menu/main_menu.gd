class_name MainMenu
extends Control
## Пункты главного меню слева под надписью: Play, Tutorial, Settings, Exit.
## На Android пункта Exit нет — приложения там закрывают системной кнопкой.

signal play_pressed
signal tutorial_pressed
signal settings_pressed
signal secret_pressed

@onready var _exit: PixelButton = %Exit


func _ready() -> void:
	%Play.pressed.connect(play_pressed.emit)
	%Tutorial.pressed.connect(tutorial_pressed.emit)
	%Settings.pressed.connect(settings_pressed.emit)
	_exit.pressed.connect(get_tree().quit)
	_exit.visible = not OS.has_feature("android")
	# Кнопка с поздравлением появляется, когда код Конами хоть раз введён.
	var secret := PixelButton.new()
	secret.text = "YOU FOUND IT"
	secret.pressed.connect(secret_pressed.emit)
	_exit.get_parent().add_child(secret)
	_exit.get_parent().move_child(secret, _exit.get_index())
	var update := func() -> void: secret.visible = Settings.secret_found
	Settings.changed.connect(update)
	update.call()
