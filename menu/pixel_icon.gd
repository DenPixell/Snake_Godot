class_name PixelIcon
extends Control
## Пиксельная картинка из PixelArt в маленьком «окошке» ЖК-экрана:
## зелено-жёлтый фон и тёмные пиксели, как на Game Boy.

const BACKLIGHT := Color(0.6, 0.7, 0.22)
const INK := Color(0.08, 0.13, 0.05)

@export var pixel := 6
## Сторона окошка в пикселях картинки.
@export var box := 12

var pattern: Array = []:
	set(value):
		pattern = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ONE * box * pixel


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2.ONE * box * pixel), BACKLIGHT)
	if pattern.is_empty():
		return
	var size := Vector2i(pattern[0].length(), pattern.size())
	var offset := (Vector2i.ONE * box - size) / 2
	PixelArt.draw_pattern(self, pattern, offset * pixel, INK, pixel)
