class_name SecretMenu
extends Control
## Поздравление тому, кто ввёл код Конами: смайлик, сам код и что он включает.

signal closed

var _state: PixelLabel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.85)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 26)
	center.add_child(column)

	var smiley := _Smiley.new()
	smiley.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(smiley)
	column.add_child(_line("CONGRATULATIONS!", 8, PixelButton.HOVER))
	column.add_child(_line("YOU DECIDED TO TRY THE GOOD OLD CODE", 4, PixelButton.NORMAL))
	column.add_child(_line("AND IT STILL WORKS", 4, PixelButton.NORMAL))
	column.add_child(_line("UP UP DOWN DOWN LEFT RIGHT LEFT RIGHT B A", 3, PixelButton.HOVER))
	_state = _line("", 4, PixelButton.HOVER)
	column.add_child(_state)
	var duration := _line("IT LASTS %d MINUTES OF PLAY", 3, PixelButton.NORMAL)
	duration.values = [int(Handheld.CHEAT_SECONDS / 60.0)]
	column.add_child(duration)
	column.add_child(_line("ENTER THE CODE ON THE GAME BOY AGAIN TO SWITCH", 3, PixelButton.NORMAL))
	column.add_child(_line("SCORES WITH THE CODE DO NOT GO TO THE LEADERBOARD", 3, PixelButton.NORMAL))
	var back := PixelButton.new()
	back.text = "BACK"
	back.pixel = 4
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	column.add_child(back)
	Settings.changed.connect(_refresh)
	_refresh()


func close() -> void:
	visible = false
	closed.emit()


func _refresh() -> void:
	_state.text = "INVINCIBILITY AND RAINBOW SCREEN: ON" if Settings.cheat_enabled \
			else "INVINCIBILITY AND RAINBOW SCREEN: OFF"


func _line(text: String, pixel: int, color: Color) -> PixelLabel:
	var label := PixelLabel.new()
	label.text = text
	label.pixel = pixel
	label.color = color
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return label


## Смайлик, переливающийся радугой.
class _Smiley extends Control:
	const PIXEL := 12

	func _ready() -> void:
		custom_minimum_size = Vector2(PixelArt.SMILEY[0].length(), PixelArt.SMILEY.size()) * PIXEL

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var hue := fmod(Time.get_ticks_msec() / 3000.0, 1.0)
		PixelArt.draw_pattern(self, PixelArt.SMILEY, Vector2i.ZERO, Color.from_hsv(hue, 0.55, 1.0), PIXEL)
