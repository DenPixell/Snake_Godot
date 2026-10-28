class_name InputBinding
extends RefCounted
## Перевод привязки клавиши в строку для файла настроек и обратно,
## и короткое имя для экрана настроек.

const MOUSE_NAMES := {
	MOUSE_BUTTON_LEFT: "LMB",
	MOUSE_BUTTON_RIGHT: "RMB",
	MOUSE_BUTTON_MIDDLE: "MMB",
}


## "key:87" для клавиши W, "mouse:1" для левой кнопки мыши. Пустая строка — не поддерживаем.
static func to_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		return "key:%d" % code
	if event is InputEventMouseButton:
		return "mouse:%d" % event.button_index
	return ""


## Обратно из строки. null, если строка битая.
static func from_text(text: String) -> InputEvent:
	var parts := text.split(":")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return null
	var code := parts[1].to_int()
	match parts[0]:
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = code
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = code
			return mouse
	return null


## Короткое имя для экрана настроек: «W», «ESCAPE», «LMB».
static func display_name(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		return OS.get_keycode_string(code).to_upper()
	if event is InputEventMouseButton:
		return MOUSE_NAMES.get(event.button_index, "MOUSE %d" % event.button_index)
	return "?"


## Можно ли назначить это нажатие на действие.
static func is_bindable(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed and event.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
	return false
