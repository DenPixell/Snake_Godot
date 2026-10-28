class_name PixelButton
extends Control
## Кнопка меню, нарисованная пиксельным шрифтом. При наведении слева появляется
## треугольник-курсор, текст становится ярким.

signal pressed

@export var text := "PLAY"
@export var pixel := 5

const NORMAL := Color(0.55, 0.62, 0.45)
const HOVER := Color(0.95, 0.98, 0.45)

var _hovered := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(PixelArt.text_width(text) + 12, PixelArt.GLYPH_HEIGHT) * pixel
	mouse_entered.connect(func() -> void: _hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: _hovered = false; queue_redraw())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _draw() -> void:
	var color := HOVER if _hovered else NORMAL
	if _hovered:
		PixelArt.draw_text(self, ">", Vector2i.ZERO, color, pixel)
	PixelArt.draw_text(self, text, Vector2i(12 * pixel, 0), color, pixel)
