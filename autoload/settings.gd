extends Node
## Настройки игры. Пока только управление по умолчанию,
## громкость, язык и переназначение клавиш добавятся отдельным этапом.

## Действие → событие ввода по умолчанию.
const DEFAULT_KEYS := {
	"gb_up": KEY_W,
	"gb_down": KEY_S,
	"gb_left": KEY_A,
	"gb_right": KEY_D,
	"pause_menu": KEY_ESCAPE,
}
const DEFAULT_MOUSE := {
	"gb_a": MOUSE_BUTTON_LEFT,
	"gb_b": MOUSE_BUTTON_RIGHT,
	"gb_start": MOUSE_BUTTON_MIDDLE,
}


func _ready() -> void:
	_apply_default_input()


func _apply_default_input() -> void:
	for action: String in DEFAULT_KEYS:
		var event := InputEventKey.new()
		event.physical_keycode = DEFAULT_KEYS[action]
		_bind(action, event)
	for action: String in DEFAULT_MOUSE:
		var event := InputEventMouseButton.new()
		event.button_index = DEFAULT_MOUSE[action]
		_bind(action, event)


func _bind(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
