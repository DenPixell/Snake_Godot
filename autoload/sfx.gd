extends Node
## Звуки меню на мониторе: наведение и нажатие. Звуки Game Boy идут из его динамика (GameBoy.play_sound).

var _player := AudioStreamPlayer.new()


func _ready() -> void:
	_player.bus = Settings.EFFECTS_BUS
	_player.max_polyphony = 4
	add_child(_player)


func play(sound: String) -> void:
	_player.stream = Sounds.get_stream(sound)
	_player.play()
