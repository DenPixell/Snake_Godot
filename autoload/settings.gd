extends Node
## Настройки игры: громкость, язык, экран, клавиши. Хранятся в user://settings.cfg
## и применяются сразу при изменении.

signal changed

const PATH := "user://settings.cfg"

## Действие → привязка по умолчанию.
const DEFAULT_BINDINGS := {
	"gb_up": "key:%d" % KEY_W,
	"gb_down": "key:%d" % KEY_S,
	"gb_left": "key:%d" % KEY_A,
	"gb_right": "key:%d" % KEY_D,
	"gb_a": "mouse:%d" % MOUSE_BUTTON_LEFT,
	"gb_b": "mouse:%d" % MOUSE_BUTTON_RIGHT,
	"gb_start": "mouse:%d" % MOUSE_BUTTON_MIDDLE,
	"pause_menu": "key:%d" % KEY_ESCAPE,
}
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440),
]
const MUSIC_BUS := "Music"
const EFFECTS_BUS := "Effects"

var music_volume := 0.8
var effects_volume := 0.8
var language := "en"
var resolution := Vector2i(1920, 1080)
var fullscreen := false
var vsync := true
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate()


func _ready() -> void:
	_create_buses()
	_load()
	apply()


## Перевод надписи меню на текущий язык.
func t(text: String) -> String:
	return Texts.translate(text, language)


func apply() -> void:
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(EFFECTS_BUS, effects_volume)
	DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if not fullscreen and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(resolution)
	for action: String in bindings:
		var event := InputBinding.from_text(bindings[action])
		if event == null:
			event = InputBinding.from_text(DEFAULT_BINDINGS[action])
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)


## Меняет настройку, применяет и сохраняет.
func set_value(key: String, value: Variant) -> void:
	set(key, value)
	if key == "resolution" and not fullscreen:
		# Разрешение имеет смысл только в окне: выходим из развёрнутого режима и центрируем.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
		var screen := DisplayServer.screen_get_usable_rect()
		DisplayServer.window_set_position(screen.position + (screen.size - resolution) / 2)
	apply()
	_save()
	changed.emit()


func bind(action: String, event: InputEvent) -> void:
	bindings[action] = InputBinding.to_text(event)
	set_value("bindings", bindings)


func reset_bindings() -> void:
	set_value("bindings", DEFAULT_BINDINGS.duplicate())


func binding_name(action: String) -> String:
	return t(InputBinding.display_name(InputBinding.from_text(bindings[action])))


## F11 — полноэкранный режим и обратно.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		set_value("fullscreen", not fullscreen)


func _create_buses() -> void:
	for bus_name: String in [MUSIC_BUS, EFFECTS_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _set_bus_volume(bus_name: String, volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, volume <= 0.0)


func _load() -> void:
	var file := ConfigFile.new()
	# Файла может не быть при первом запуске — тогда всё по умолчанию.
	if file.load(PATH) != OK:
		return
	music_volume = clampf(file.get_value("audio", "music", music_volume), 0.0, 1.0)
	effects_volume = clampf(file.get_value("audio", "effects", effects_volume), 0.0, 1.0)
	var saved_language: String = file.get_value("game", "language", language)
	language = saved_language if saved_language in Texts.LANGUAGES else "en"
	resolution = file.get_value("display", "resolution", resolution)
	fullscreen = file.get_value("display", "fullscreen", fullscreen)
	vsync = file.get_value("display", "vsync", vsync)
	for action: String in DEFAULT_BINDINGS:
		var text: String = file.get_value("input", action, DEFAULT_BINDINGS[action])
		bindings[action] = text if InputBinding.from_text(text) != null else DEFAULT_BINDINGS[action]


func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "effects", effects_volume)
	file.set_value("game", "language", language)
	file.set_value("display", "resolution", resolution)
	file.set_value("display", "fullscreen", fullscreen)
	file.set_value("display", "vsync", vsync)
	for action: String in bindings:
		file.set_value("input", action, bindings[action])
	var error := file.save(PATH)
	if error != OK:
		push_error("Не удалось сохранить настройки: %s" % error_string(error))
