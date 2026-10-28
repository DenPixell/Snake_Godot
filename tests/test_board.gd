extends TestCase


func test_free_cells_skip_bricks_and_snake() -> void:
	var board := Board.new()
	board.add_brick(Vector2i(0, 0))
	var free := board.free_cells({Vector2i(1, 0): true})
	check_eq(free.size(), Board.WIDTH * Board.HEIGHT - 2, "свободных клеток")
	check(not free.has(Vector2i(0, 0)), "кирпич не свободен")


func test_brick_not_near_head() -> void:
	var board := Board.new()
	var head := Vector2i(10, 10)
	check(not board.is_safe_brick(Vector2i(12, 12), {}, head, Vector2i.UP), "рядом с головой")
	check(board.is_safe_brick(Vector2i(13, 10), {}, head, Vector2i.UP), "в стороне можно")


func test_brick_not_ahead_of_snake() -> void:
	var board := Board.new()
	var head := Vector2i(10, 10)
	check(not board.is_safe_brick(Vector2i(10, 5), {}, head, Vector2i.UP), "в 5 клетках впереди")
	check(board.is_safe_brick(Vector2i(10, 4), {}, head, Vector2i.UP), "в 6 клетках уже можно")


func test_brick_not_on_snake() -> void:
	var board := Board.new()
	var occupied := {Vector2i(15, 15): true}
	check(not board.is_safe_brick(Vector2i(15, 15), occupied, Vector2i(5, 5), Vector2i.UP), "в змейке")


func test_brick_does_not_make_dead_end() -> void:
	var board := Board.new()
	# Кирпич рядом с углом оставил бы угловую клетку с одним выходом.
	check(not board.is_safe_brick(Vector2i(1, 0), {}, Vector2i(10, 10), Vector2i.UP), "тупик в углу")


func test_brick_does_not_cut_field() -> void:
	var board := Board.new()
	# Почти целая стена поперёк поля, последний кирпич закрыл бы проход.
	for x in range(0, Board.WIDTH - 1):
		board.add_brick(Vector2i(x, 12))
	check(not board.is_safe_brick(Vector2i(Board.WIDTH - 1, 12), {}, Vector2i(5, 20), Vector2i.UP),
			"поле разрезано")


func test_reachable_stops_at_snake() -> void:
	var board := Board.new()
	# Голова в углу, тело перекрывает оба выхода.
	var occupied := {Vector2i(1, 0): true, Vector2i(0, 1): true}
	check(board.reachable_from(Vector2i(0, 0), occupied).is_empty(), "некуда ехать")
