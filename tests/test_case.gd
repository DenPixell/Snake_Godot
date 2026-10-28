class_name TestCase
extends RefCounted
## Основа для тестов: каждый метод test_* запускается отдельно.

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: ожидали %s, получили %s" % [message, expected, actual])


## Игра с фиксированным сидом, чтобы тест каждый раз шёл одинаково.
func make_game(level := Difficulty.Level.NORMAL, seed_value := 1) -> SnakeGame:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return SnakeGame.new(level, rng)


## Кладёт объект прямо перед головой змейки.
func put_item_ahead(game: SnakeGame, type: Item.Type) -> void:
	var cell := game.head() + game.direction
	game.item = Item.new(type, [cell])
