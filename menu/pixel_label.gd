class_name PixelLabel
extends Control
## Надпись пиксельным шрифтом, без нажатия. Переводится на язык из настроек.

@export var text := "":
	set(value):
		text = value
		update_minimum_size()
		queue_redraw()
@export var pixel := 5
@export var color := Color(0.4, 0.46, 0.33)
@export var translate := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Settings.changed.connect(func() -> void: update_minimum_size(); queue_redraw())


func _get_minimum_size() -> Vector2:
	return Vector2(PixelArt.text_width(_shown()), PixelArt.GLYPH_HEIGHT) * pixel


func _draw() -> void:
	PixelArt.draw_text(self, _shown(), Vector2i.ZERO, color, pixel)


func _shown() -> String:
	return Settings.t(text) if translate else text
