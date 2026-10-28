extends TestCase


func test_starts_with_dot_and_length_three() -> void:
	var game := make_game()
	check_eq(game.body.size(), 3, "длина")
	check_eq(game.item.type, Item.Type.DOT, "первый объект — точка")


func test_moves_at_start_speed() -> void:
	var game := make_game()
	var start := game.head()
	var step_time := 1.0 / SnakeGame.START_SPEED
	game.tick(step_time * 0.99)
	check_eq(game.head(), start, "ещё не сдвинулась")
	game.tick(step_time * 0.02)
	check_eq(game.head(), start + Vector2i.UP, "сдвинулась на клетку")


func test_dies_at_wall() -> void:
	var game := make_game()
	game.item = null
	for i in Board.HEIGHT:
		game.step()
	check_eq(game.state, SnakeGame.State.DEAD, "удар о стену")


func test_cannot_reverse_into_neck() -> void:
	var game := make_game()
	game.turn(Vector2i.DOWN)
	game.step()
	check_eq(game.state, SnakeGame.State.PLAYING, "разворот игнорируется")


func test_dot_grows_by_one_and_scores() -> void:
	var game := make_game()
	put_item_ahead(game, Item.Type.DOT)
	game.step()
	game.step()
	check_eq(game.body.size(), 4, "длина +1")
	check_eq(game.score, 1, "счёт +1")


func test_big_apple_grows_two_to_five_and_scores_one() -> void:
	var game := make_game()
	put_item_ahead(game, Item.Type.BIG_APPLE)
	game.step()
	game.item = null
	game.turn(Vector2i.LEFT)
	for i in 6:
		game.step()
	var grown := game.body.size() - 3
	check(grown >= 2 and grown <= 5, "выросла на %d" % grown)
	check_eq(game.score, 1, "счёт +1")


func test_rotten_apple_inverts_controls() -> void:
	var game := make_game()
	put_item_ahead(game, Item.Type.ROTTEN_APPLE)
	game.step()
	game.turn(Vector2i.LEFT)
	game.step()
	check_eq(game.direction, Vector2i.RIGHT, "влево стало вправо")


func test_inversion_ends_after_five_seconds() -> void:
	var game := make_game()
	game.effects.add(Effects.Kind.INVERT)
	game.effects.tick(5.1)
	game.turn(Vector2i.LEFT)
	game.step()
	check_eq(game.direction, Vector2i.LEFT, "управление вернулось")


func test_lightning_adds_three_speed() -> void:
	var game := make_game()
	put_item_ahead(game, Item.Type.LIGHTNING)
	game.step()
	check(is_equal_approx(game.speed(), SnakeGame.START_SPEED + 0.05 + 3.0), "скорость с молнией")


func test_speed_capped_at_fifteen() -> void:
	var game := make_game()
	game.score = 10000
	check(is_equal_approx(game.speed(), 15.0), "потолок")


func test_brick_placed_away_from_head() -> void:
	var game := make_game(Difficulty.Level.NORMAL, 3)
	put_item_ahead(game, Item.Type.BRICK)
	game.step()
	var bricks := game.board.bricks()
	check_eq(bricks.size(), 1, "один кирпич")
	var diff := (bricks[0] - game.head()).abs()
	check(maxi(diff.x, diff.y) >= Board.BRICK_MIN_DISTANCE, "не рядом с головой")
	check(not game.item.occupies(bricks[0]), "объект не на кирпиче")


func test_dies_on_brick() -> void:
	var game := make_game()
	game.item = null
	game.board.add_brick(game.head() + Vector2i.UP)
	game.step()
	check_eq(game.state, SnakeGame.State.DEAD, "удар о кирпич")


func test_wins_when_field_is_full() -> void:
	var game := make_game()
	# Заполняем змейкой всё поле, кроме одной клетки перед головой.
	var target := game.head() + Vector2i.UP
	var body: Array[Vector2i] = [game.head()]
	for y in Board.HEIGHT:
		for x in Board.WIDTH:
			var cell := Vector2i(x, y)
			if cell != target and cell != game.head():
				body.append(cell)
	game.body = body
	game.item = Item.new(Item.Type.DOT, [target])
	game.step()
	check_eq(game.state, SnakeGame.State.WON, "победа")


func test_long_random_games_never_break_rules() -> void:
	# Много случайных партий на Hard: объект никогда не стоит на змейке или кирпиче.
	for seed_value in 20:
		var game := make_game(Difficulty.Level.HARD, seed_value)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for i in 400:
			if game.state != SnakeGame.State.PLAYING:
				break
			_steer_to_item(game)
			game.step()
			if game.item != null:
				for cell in game.item.cells:
					check(not game.body.has(cell), "объект в змейке, сид %d" % seed_value)
					check(not game.board.is_brick(cell), "объект на кирпиче, сид %d" % seed_value)


## Простой автопилот: едет к объекту, избегая немедленной смерти.
func _steer_to_item(game: SnakeGame) -> void:
	if game.item == null:
		return
	var head := game.head()
	var best := game.direction
	var best_dist := 1 << 30
	for dir in Board.DIRECTIONS:
		if dir == -game.direction:
			continue
		var next := head + dir
		if not game.board.in_bounds(next) or game.board.is_brick(next) or game.body.has(next):
			continue
		var dist := absi(next.x - game.item.cells[0].x) + absi(next.y - game.item.cells[0].y)
		if dist < best_dist:
			best_dist = dist
			best = dir
	var dir := best
	if game.effects.is_active(Effects.Kind.INVERT):
		dir = -dir
	game.turn(dir)


func test_invincible_wraps_through_wall() -> void:
	var game := make_game()
	game.invincible_left = 120.0
	game.item = null
	for i in Board.HEIGHT:
		game.step()
	check_eq(game.state, SnakeGame.State.PLAYING, "не умерла о стену")
	check(game.board.in_bounds(game.head()), "голова на поле")


func test_invincible_passes_brick_and_self() -> void:
	var game := make_game()
	game.invincible_left = 120.0
	game.item = null
	game.board.add_brick(game.head() + Vector2i.UP)
	game.step()
	check_eq(game.state, SnakeGame.State.PLAYING, "сквозь кирпич")
	game.body.append_array([game.head() + Vector2i(1, -1), game.head() + Vector2i(1, 0)])
	game.body.insert(1, game.head() + Vector2i.UP)
	game.step()
	check_eq(game.state, SnakeGame.State.PLAYING, "сквозь себя")


func test_invincibility_ends_after_time() -> void:
	var game := make_game()
	game.invincible_left = 1.0
	game.item = null
	var ended := [false]
	game.invincibility_ended.connect(func() -> void: ended[0] = true)
	game.tick(0.5)
	check(game.is_invincible(), "ещё действует")
	game.tick(0.6)
	check(not game.is_invincible(), "закончилась")
	check(ended[0], "сигнал об окончании")


func test_invincibility_waits_until_snake_is_free() -> void:
	var game := make_game()
	game.invincible_left = 0.05
	game.item = null
	game.board.add_brick(game.body[1])
	game._tick_invincibility(0.1)
	check(game.is_invincible(), "пока на кирпиче — не заканчивается")
