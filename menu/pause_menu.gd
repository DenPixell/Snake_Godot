class_name PauseMenu
extends Control
## Меню по Esc во время игры: Продолжить, Настройки, Главное меню.

signal continue_pressed
signal settings_pressed
signal main_menu_pressed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	center.add_child(box)
	var title := PixelLabel.new()
	title.text = "PAUSE"
	title.pixel = 8
	title.color = PixelButton.HOVER
	box.add_child(title)
	for item: Array in [["CONTINUE", continue_pressed], ["SETTINGS", settings_pressed],
			["MAIN MENU", main_menu_pressed]]:
		var button := PixelButton.new()
		button.text = item[0]
		button.pressed.connect((item[1] as Signal).emit)
		box.add_child(button)
