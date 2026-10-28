extends Node
## Рекорды Normal и Hard, хранятся в файле на этом компьютере.

const PATH := "user://records.cfg"

var _boards: Dictionary[Difficulty.Level, Leaderboard] = {}


func _ready() -> void:
	var file := ConfigFile.new()
	# Файла может не быть при первом запуске — тогда таблицы просто пустые.
	file.load(PATH)
	for level: Difficulty.Level in [Difficulty.Level.NORMAL, Difficulty.Level.HARD]:
		_boards[level] = Leaderboard.from_array(file.get_value("records", _key(level), []))


func board(level: Difficulty.Level) -> Leaderboard:
	return _boards.get(level, Leaderboard.new())


func qualifies(level: Difficulty.Level, score: int) -> bool:
	return Difficulty.has_leaderboard(level) and board(level).qualifies(score)


func add(level: Difficulty.Level, player_name: String, score: int) -> int:
	var rank := board(level).add(player_name, score)
	if rank >= 0:
		_save()
	return rank


func _save() -> void:
	var file := ConfigFile.new()
	for level: Difficulty.Level in _boards:
		file.set_value("records", _key(level), _boards[level].to_array())
	var error := file.save(PATH)
	if error != OK:
		push_error("Не удалось сохранить рекорды: %s" % error_string(error))


func _key(level: Difficulty.Level) -> String:
	return Difficulty.Level.keys()[level].to_lower()
