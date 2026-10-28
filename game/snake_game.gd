class_name SnakeGame
extends RefCounted
## Одна партия змейки. Хранит состояние и двигает его по времени.
## Ничего не рисует: экран читает поля и подписывается на сигналы.

signal item_eaten(type: Item.Type)
signal brick_placed(cell: Vector2i)
signal died
signal won
## Неуязвимость по коду Конами закончилась.
signal invincibility_ended

enum State { PLAYING, DEAD, WON }

const START_SPEED := 5.0
const SPEED_PER_ITEM := 0.05
const MAX_SPEED := 15.0
const LIGHTNING_BONUS := 3.0
const BIG_APPLE_GROWTH_MIN := 2
const BIG_APPLE_GROWTH_MAX := 5
## Больше двух нажатий вперёд не запоминаем, чтобы змейка не «жила своей жизнью».
const MAX_QUEUED_TURNS := 2
const NO_CELL := Vector2i(-1, -1)

var level: Difficulty.Level
var state := State.PLAYING
var score := 0
## Клетки змейки, голова первая.
var body: Array[Vector2i] = []
var direction := Vector2i.UP
var board := Board.new()
var item: Item
var effects := Effects.new()
## Чит по коду Конами: сколько секунд ещё змейка проходит сквозь стены (выходит
## с другой стороны), себя и кирпичи. Время идёт только во время партии.
var invincible_left := 0.0

var _rng: RandomNumberGenerator
var _spawner: ItemSpawner
var _turns: Array[Vector2i] = []
var _grow_left := 0
var _step_time := 0.0


func _init(difficulty: Difficulty.Level, rng := RandomNumberGenerator.new()) -> void:
	level = difficulty
	_rng = rng
	_spawner = ItemSpawner.new(level, _rng)
	var start := Vector2i(Board.WIDTH / 2, Board.HEIGHT * 3 / 5)
	body = [start, start + Vector2i.DOWN, start + Vector2i.DOWN * 2]
	# Первый объект всегда обычная точка.
	item = _spawner.place(Item.Type.DOT, board, _body_set(), head())


func head() -> Vector2i:
	return body[0]


## Скорость в клетках в секунду с учётом молнии.
func speed() -> float:
	var base := minf(START_SPEED + SPEED_PER_ITEM * score, MAX_SPEED)
	if effects.is_active(Effects.Kind.SPEED):
		base += LIGHTNING_BONUS
	return base


## Нажатие на крестовину. При гнилом яблоке направление меняется на противоположное.
func turn(dir: Vector2i) -> void:
	if state != State.PLAYING or _turns.size() >= MAX_QUEUED_TURNS:
		return
	if effects.is_active(Effects.Kind.INVERT):
		dir = -dir
	var last: Vector2i = _turns.back() if not _turns.is_empty() else direction
	# Развернуться в собственную шею нельзя, повтор того же направления ничего не даёт.
	if dir == last or dir == -last:
		return
	_turns.append(dir)


## Двигает время вперёд. На паузе просто не вызывается.
func tick(delta: float) -> void:
	if state != State.PLAYING:
		return
	effects.tick(delta)
	_tick_invincibility(delta)
	_step_time += delta
	while state == State.PLAYING and _step_time >= 1.0 / speed():
		_step_time -= 1.0 / speed()
		step()


## Один шаг змейки на клетку.
func step() -> void:
	if state != State.PLAYING:
		return
	if not _turns.is_empty():
		direction = _turns.pop_front()
	var next := head() + direction
	var invincible := is_invincible()
	if invincible:
		next = Vector2i(posmod(next.x, Board.WIDTH), posmod(next.y, Board.HEIGHT))
	var growing := _grow_left > 0
	# В клетку хвоста можно въехать, если хвост в этот же шаг уходит.
	var hits_body: bool = body.has(next) and not (next == body.back() and not growing)
	var crashed := not board.in_bounds(next) or board.is_brick(next) or hits_body
	if crashed and not invincible:
		state = State.DEAD
		died.emit()
		return
	body.push_front(next)
	if growing:
		_grow_left -= 1
	else:
		body.pop_back()
	if item != null and item.occupies(next):
		_eat()


func is_invincible() -> bool:
	return invincible_left > 0.0


## Неуязвимость не заканчивается, пока змейка внутри себя или кирпича —
## иначе она погибла бы сразу, как только время вышло.
func _tick_invincibility(delta: float) -> void:
	if invincible_left <= 0.0:
		return
	invincible_left = maxf(invincible_left - delta, 0.0)
	if invincible_left == 0.0 and _overlaps():
		invincible_left = 0.01
	if invincible_left == 0.0:
		invincibility_ended.emit()


func _overlaps() -> bool:
	var seen := {}
	for cell in body:
		if seen.has(cell) or board.is_brick(cell):
			return true
		seen[cell] = true
	return false


## Доля пройденного пути до следующей клетки, от 0 до 1. Нужна для плавной отрисовки.
func step_progress() -> float:
	return clampf(_step_time * speed(), 0.0, 1.0)


func _eat() -> void:
	var eaten := item
	item = null
	score += 1
	match eaten.type:
		Item.Type.DOT:
			_grow_left += 1
		Item.Type.BIG_APPLE:
			_grow_left += _rng.randi_range(BIG_APPLE_GROWTH_MIN, BIG_APPLE_GROWTH_MAX)
		Item.Type.BRICK:
			_place_brick()
	var effect := Effects.from_item(eaten.type)
	if effect >= 0:
		effects.add(effect)
	_spawner.on_picked(eaten.type)
	item_eaten.emit(eaten.type)
	_spawn_next()


## Победа, когда змейка с учётом будущего роста займёт все клетки без кирпичей.
func _spawn_next() -> void:
	var capacity := Board.WIDTH * Board.HEIGHT - board.bricks().size()
	if body.size() + _grow_left >= capacity:
		_win()
		return
	var type := _spawner.choose_type(effects.any_active(), _has_safe_brick_cell)
	item = _spawner.place(type, board, _body_set(), head())
	if item == null:
		_win()


func _win() -> void:
	item = null
	state = State.WON
	won.emit()


## Сначала ставится кирпич, потом появляется следующий объект.
func _place_brick() -> void:
	var cell := _find_safe_brick_cell()
	if cell == NO_CELL:
		_spawner.remove_from_pool(Item.Type.BRICK)
		return
	board.add_brick(cell)
	brick_placed.emit(cell)


func _has_safe_brick_cell() -> bool:
	return _find_safe_brick_cell() != NO_CELL


## Случайная клетка, куда можно поставить кирпич, или NO_CELL.
## Проверяем клетки в случайном порядке до первой подходящей: проверка всех сразу заметно тормозит.
func _find_safe_brick_cell() -> Vector2i:
	var occupied := _body_set()
	var cells := board.free_cells(occupied)
	_shuffle(cells)
	for cell in cells:
		if board.is_safe_brick(cell, occupied, head(), direction):
			return cell
	return NO_CELL


## Перемешивание через наш генератор, чтобы в тестах с сидом всё повторялось.
func _shuffle(cells: Array[Vector2i]) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := cells[i]
		cells[i] = cells[j]
		cells[j] = tmp


func _body_set() -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	for cell in body:
		cells[cell] = true
	return cells
