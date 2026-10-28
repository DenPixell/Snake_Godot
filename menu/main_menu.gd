class_name MainMenu
extends Control
## Пункты главного меню слева под надписью: Play, Settings, Exit.
## На Android пункта Exit нет — приложения там закрывают системной кнопкой.

signal play_pressed
signal settings_pressed

@onready var _exit: PixelButton = %Exit


func _ready() -> void:
	%Play.pressed.connect(play_pressed.emit)
	%Settings.pressed.connect(settings_pressed.emit)
	_exit.pressed.connect(get_tree().quit)
	_exit.visible = not OS.has_feature("android")
