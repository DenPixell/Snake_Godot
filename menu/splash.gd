class_name Splash
extends Control
## Заставка перед главным меню: пиксельные наушники и совет играть в наушниках.
## Плавно появляется и исчезает, щелчок или любая клавиша пропускают её.

signal finished

const FADE := 0.8
const HOLD := 2.6

var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var black := ColorRect.new()
	black.color = Color.BLACK
	add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 36)
	center.add_child(column)
	var icon := _Headphones.new()
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	for line: String in ["FOR BETTER IMMERSION", "PLAY WITH HEADPHONES"]:
		var label := PixelLabel.new()
		label.text = line
		label.pixel = 5
		label.color = PixelButton.HOVER
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(label)
	# Появляется только содержимое, чёрный фон с самого начала закрывает меню.
	center.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(center, "modulate:a", 1.0, FADE)
	tween.tween_interval(HOLD)
	tween.tween_property(self, "modulate:a", 0.0, FADE)
	tween.tween_callback(_finish)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()


## Наушники, нарисованные светлыми пикселями.
class _Headphones extends Control:
	const PIXEL := 12

	func _ready() -> void:
		custom_minimum_size = Vector2(PixelArt.HEADPHONES[0].length(), PixelArt.HEADPHONES.size()) * PIXEL

	func _draw() -> void:
		PixelArt.draw_pattern(self, PixelArt.HEADPHONES, Vector2i.ZERO, PixelButton.HOVER, PIXEL)
