extends TestCase


func _rng(seed_value := 7) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _always_true() -> bool:
	return true


func _always_false() -> bool:
	return false


func test_easy_has_only_dots() -> void:
	var spawner := ItemSpawner.new(Difficulty.Level.EASY, _rng())
	for i in 200:
		check_eq(spawner.choose_type(false, _always_true), Item.Type.DOT, "на Easy только точки")


func test_normal_gives_three_dots_after_complication() -> void:
	var spawner := ItemSpawner.new(Difficulty.Level.NORMAL, _rng())
	spawner.on_picked(Item.Type.LIGHTNING)
	for i in 3:
		check_eq(spawner.choose_type(false, _always_true), Item.Type.DOT, "защитная точка %d" % i)


func test_hard_has_no_protection() -> void:
	var spawner := ItemSpawner.new(Difficulty.Level.HARD, _rng())
	spawner.on_picked(Item.Type.LIGHTNING)
	var complications := 0
	for i in 200:
		if spawner.choose_type(true, _always_true) != Item.Type.DOT:
			complications += 1
	check(complications > 60 and complications < 140, "примерно половина усложнений: %d" % complications)


func test_normal_waits_for_effect_to_end() -> void:
	var spawner := ItemSpawner.new(Difficulty.Level.NORMAL, _rng())
	for i in 100:
		check_eq(spawner.choose_type(true, _always_true), Item.Type.DOT, "пока действует эффект")


func test_brick_removed_when_no_place() -> void:
	var spawner := ItemSpawner.new(Difficulty.Level.HARD, _rng())
	for i in 300:
		check(spawner.choose_type(false, _always_false) != Item.Type.BRICK, "кирпич без места")
	check(not spawner.pool().has(Item.Type.BRICK), "кирпич убран из пула")


func test_big_apple_takes_2x2() -> void:
	var spawner := ItemSpawner.new(Difficulty.Level.NORMAL, _rng())
	var item := spawner.place(Item.Type.BIG_APPLE, Board.new(), {}, Vector2i(10, 10))
	check_eq(item.cells.size(), 4, "четыре клетки")
	check(not item.compact, "обычный размер")


func test_big_apple_compact_when_no_room() -> void:
	var board := Board.new()
	var occupied := {}
	# Занимаем всё, кроме полосы шириной в одну клетку.
	for y in Board.HEIGHT:
		for x in Board.WIDTH:
			if x != 0:
				occupied[Vector2i(x, y)] = true
	var item := ItemSpawner.new(Difficulty.Level.NORMAL, _rng()).place(
			Item.Type.BIG_APPLE, board, occupied, Vector2i(1, 0))
	check_eq(item.cells.size(), 1, "одна клетка")
	check(item.compact, "помечено как x2")


func test_item_never_on_snake() -> void:
	var spawner := ItemSpawner.new(Difficulty.Level.NORMAL, _rng())
	var occupied := {}
	for x in Board.WIDTH:
		occupied[Vector2i(x, 5)] = true
	for i in 200:
		var item := spawner.place(Item.Type.DOT, Board.new(), occupied, Vector2i(0, 5))
		check(not occupied.has(item.cells[0]), "объект в змейке")


func test_nothing_placed_on_full_field() -> void:
	var occupied := {}
	for y in Board.HEIGHT:
		for x in Board.WIDTH:
			occupied[Vector2i(x, y)] = true
	var item := ItemSpawner.new(Difficulty.Level.NORMAL, _rng()).place(
			Item.Type.DOT, Board.new(), occupied, Vector2i.ZERO)
	check(item == null, "места нет")
