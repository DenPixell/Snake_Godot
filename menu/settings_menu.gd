class_name SettingsMenu
extends Control
## Экран настроек: слева звук, язык и экран, справа управление.
## Значения меняются стрелками «<» и «>». Чтобы переназначить кнопку,
## щёлкните по ней и нажмите новую клавишу или кнопку мыши.

signal closed

const PIXEL := 4
const NAME_WIDTH := 15
const VOLUME_STEP := 0.1
## Действия, которые можно переназначить, и их подписи.
const ACTIONS := [
	["gb_up", "UP"], ["gb_down", "DOWN"], ["gb_left", "LEFT"], ["gb_right", "RIGHT"],
	["gb_a", "BUTTON A"], ["gb_b", "BUTTON B"], ["gb_start", "START"], ["pause_menu", "MENU"],
]

## Какое действие ждёт новую клавишу, пустая строка — никакое.
var _waiting := ""
var _values := {}
var _key_buttons := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.82)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 40)
	center.add_child(root)
	root.add_child(_label("SETTINGS", 8, PixelButton.HOVER))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 120)
	root.add_child(columns)
	var left := _column(columns)
	_option_row(left, "MUSIC", "music_volume")
	_option_row(left, "EFFECTS", "effects_volume")
	_option_row(left, "LANGUAGE", "language")
	_option_row(left, "RESOLUTION", "resolution")
	_option_row(left, "FULLSCREEN", "fullscreen")
	_option_row(left, "VSYNC", "vsync")
	var right := _column(columns)
	right.add_child(_label("CONTROLS", PIXEL, PixelButton.HOVER))
	for pair: Array in ACTIONS:
		_key_row(right, pair[0], pair[1])

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 80)
	root.add_child(bottom)
	var reset := _button("RESET KEYS")
	reset.pressed.connect(Settings.reset_bindings)
	bottom.add_child(reset)
	var back := _button("BACK")
	back.pressed.connect(close)
	bottom.add_child(back)

	Settings.changed.connect(_refresh)
	_refresh()


func close() -> void:
	_waiting = ""
	visible = false
	closed.emit()


## Ждём новую клавишу: следующее нажатие клавиши или кнопки мыши становится привязкой.
func _input(event: InputEvent) -> void:
	if not visible or _waiting.is_empty() or not InputBinding.is_bindable(event):
		return
	get_viewport().set_input_as_handled()
	var action := _waiting
	_waiting = ""
	Settings.bind(action, event)


func _refresh() -> void:
	_values["music_volume"].text = "%d%%" % roundi(Settings.music_volume * 100)
	_values["effects_volume"].text = "%d%%" % roundi(Settings.effects_volume * 100)
	_values["language"].text = Settings.language.to_upper()
	_values["resolution"].text = "%dX%d" % [Settings.resolution.x, Settings.resolution.y]
	_values["fullscreen"].text = Settings.t("ON" if Settings.fullscreen else "OFF")
	_values["vsync"].text = Settings.t("ON" if Settings.vsync else "OFF")
	for action: String in _key_buttons:
		_key_buttons[action].text = Settings.t("PRESS KEY") if action == _waiting \
				else Settings.binding_name(action)


func _change(key: String, step: int) -> void:
	match key:
		"music_volume", "effects_volume":
			var volume: float = Settings.get(key)
			Settings.set_value(key, clampf(snappedf(volume + step * VOLUME_STEP, VOLUME_STEP), 0.0, 1.0))
		"language":
			var index := wrapi(Texts.LANGUAGES.find(Settings.language) + step, 0, Texts.LANGUAGES.size())
			Settings.set_value(key, Texts.LANGUAGES[index])
		"resolution":
			var list := Settings.RESOLUTIONS
			var index := wrapi(maxi(list.find(Settings.resolution), 0) + step, 0, list.size())
			Settings.set_value(key, list[index])
		"fullscreen", "vsync":
			Settings.set_value(key, not Settings.get(key))


func _option_row(parent: Control, title: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var name_label := _label(title, PIXEL, PixelLabel.new().color)
	name_label.custom_minimum_size.x = NAME_WIDTH * 6 * PIXEL
	row.add_child(name_label)
	var less := _arrow("<")
	less.pressed.connect(_change.bind(key, -1))
	row.add_child(less)
	var value := _label("", PIXEL, PixelButton.HOVER)
	value.translate = false
	value.custom_minimum_size.x = 10 * 6 * PIXEL
	_values[key] = value
	row.add_child(value)
	var more := _arrow(">")
	more.pressed.connect(_change.bind(key, 1))
	row.add_child(more)
	parent.add_child(row)


func _key_row(parent: Control, action: String, title: String) -> void:
	var row := HBoxContainer.new()
	var name_label := _label(title, PIXEL, PixelLabel.new().color)
	name_label.custom_minimum_size.x = 11 * 6 * PIXEL
	row.add_child(name_label)
	var key := _button("")
	key.translate = false
	key.show_cursor = false
	key.pressed.connect(func() -> void: _waiting = action; _refresh())
	_key_buttons[action] = key
	row.add_child(key)
	parent.add_child(row)


func _column(parent: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	parent.add_child(column)
	return column


func _label(text: String, pixel: int, color: Color) -> PixelLabel:
	var label := PixelLabel.new()
	label.text = text
	label.pixel = pixel
	label.color = color
	return label


func _button(text: String) -> PixelButton:
	var button := PixelButton.new()
	button.text = text
	button.pixel = PIXEL
	return button


func _arrow(text: String) -> PixelButton:
	var button := _button(text)
	button.show_cursor = false
	button.translate = false
	return button
