class_name Leaderboard
extends RefCounted
## Таблица рекордов одной сложности: десять лучших результатов, имя из трёх букв.

const SIZE := 10
const NAME_LENGTH := 3

## Записи вида {"name": "AAA", "score": 42}, лучшие сверху.
var entries: Array[Dictionary] = []


## Попадает ли результат в таблицу.
func qualifies(score: int) -> bool:
	if score <= 0:
		return false
	return entries.size() < SIZE or score > entries.back()["score"]


## Добавляет результат и возвращает место (с нуля) или -1, если не попал.
## При равном счёте новая запись встаёт ниже старой.
func add(player_name: String, score: int) -> int:
	if not qualifies(score):
		return -1
	var rank := entries.size()
	for i in entries.size():
		if score > entries[i]["score"]:
			rank = i
			break
	entries.insert(rank, {"name": player_name.to_upper().left(NAME_LENGTH), "score": score})
	entries.resize(mini(entries.size(), SIZE))
	return rank


func to_array() -> Array:
	return entries.duplicate(true)


## Загрузка из сохранённого массива. Битые записи пропускаем.
static func from_array(data: Variant) -> Leaderboard:
	var board := Leaderboard.new()
	if data is Array:
		for entry: Variant in data:
			if entry is Dictionary and entry.get("name") is String and entry.get("score") is int:
				board.entries.append({"name": entry["name"], "score": entry["score"]})
	board.entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	board.entries.resize(mini(board.entries.size(), SIZE))
	return board
