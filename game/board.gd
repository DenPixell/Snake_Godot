class_name Board
extends RefCounted
## Поле: размеры, кирпичи и проверки клеток.

const WIDTH := 20
const HEIGHT := 25
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

## Кирпич не ставится ближе этого расстояния к голове (по клеткам, включая диагональ).
const BRICK_MIN_DISTANCE := 3
## И не ставится на столько клеток вперёд по ходу змейки.
const BRICK_AHEAD_CELLS := 5

var _bricks: Dictionary[Vector2i, bool] = {}


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT


func is_brick(cell: Vector2i) -> bool:
	return _bricks.has(cell)


func add_brick(cell: Vector2i) -> void:
	_bricks[cell] = true


func bricks() -> Array[Vector2i]:
	return _bricks.keys()


## Клетки без кирпичей и без занятых (змейкой).
func free_cells(occupied: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in HEIGHT:
		for x in WIDTH:
			var cell := Vector2i(x, y)
			if not _bricks.has(cell) and not occupied.has(cell):
				result.append(cell)
	return result


## Свободные клетки, до которых можно дойти от start, не проходя через занятые и кирпичи.
func reachable_from(start: Vector2i, occupied: Dictionary) -> Dictionary[Vector2i, bool]:
	var seen: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for dir in DIRECTIONS:
			var next := cell + dir
			if in_bounds(next) and not seen.has(next) and not _bricks.has(next) \
					and not occupied.has(next):
				seen[next] = true
				queue.append(next)
	seen.erase(start)
	return seen


## Можно ли поставить кирпич в клетку, чтобы змейка не погибла сразу и поле осталось проходимым.
func is_safe_brick(cell: Vector2i, occupied: Dictionary, head: Vector2i, dir: Vector2i) -> bool:
	if not in_bounds(cell) or _bricks.has(cell) or occupied.has(cell):
		return false
	var diff := (cell - head).abs()
	if maxi(diff.x, diff.y) < BRICK_MIN_DISTANCE:
		return false
	for i in range(1, BRICK_AHEAD_CELLS + 1):
		if head + dir * i == cell:
			return false
	_bricks[cell] = true
	var ok := _has_no_dead_ends() and _is_connected()
	_bricks.erase(cell)
	return ok


## У каждой клетки без кирпича минимум два соседа без кирпича и стены.
## Иначе получается тупик: змейка заедет туда за объектом и не сможет развернуться.
func _has_no_dead_ends() -> bool:
	for y in HEIGHT:
		for x in WIDTH:
			var cell := Vector2i(x, y)
			if _bricks.has(cell):
				continue
			var open := 0
			for dir in DIRECTIONS:
				var next := cell + dir
				if in_bounds(next) and not _bricks.has(next):
					open += 1
			if open < 2:
				return false
	return true


## Все клетки без кирпичей связаны между собой, ни одна не отрезана.
func _is_connected() -> bool:
	var start := Vector2i(-1, -1)
	for y in HEIGHT:
		for x in WIDTH:
			if not _bricks.has(Vector2i(x, y)):
				start = Vector2i(x, y)
				break
		if start.x >= 0:
			break
	if start.x < 0:
		return true
	var reached := reachable_from(start, {}).size() + 1
	return reached == WIDTH * HEIGHT - _bricks.size()
