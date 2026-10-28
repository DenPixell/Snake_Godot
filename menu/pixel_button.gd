class_name PixelButton
extends Control
## Кнопка меню, нарисованная пиксельным шрифтом. Текст переводится на язык из настроек.
## При наведении текст становится ярким, а слева появляется треугольник-курсор.

signal pressed

@export var text := "PLAY":
	set(value):
		text = value
		update_minimum_size()
		queue_redraw()
@export var pixel := 5
## Треугольник слева при наведении. У маленьких стрелок «<» и «>» он не нужен.
@export var show_cursor := true
## Переводить ли текст. Значения вроде «1920X1080» или «W» переводить не нужно.
@export var translate := true

const NORMAL := Color(0.55, 0.62, 0.45)
const HOVER := Color(0.95, 0.98, 0.45)

var _hovered := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: _hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: _hovered = false; queue_redraw())
	Settings.changed.connect(func() -> void: update_minimum_size(); queue_redraw())


func _get_minimum_size() -> Vector2:
	return Vector2(PixelArt.text_width(_shown()) + _indent(), PixelArt.GLYPH_HEIGHT) * pixel


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _draw() -> void:
	var color := HOVER if _hovered else NORMAL
	if _hovered and show_cursor:
		PixelArt.draw_text(self, ">", Vector2i.ZERO, color, pixel)
	PixelArt.draw_text(self, _shown(), Vector2i(_indent() * pixel, 0), color, pixel)


func _shown() -> String:
	return Settings.t(text) if translate else text


func _indent() -> int:
	return 12 if show_cursor else 0
