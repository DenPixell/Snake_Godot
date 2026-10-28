class_name ItemSpawner
extends RefCounted
## Решает, какой объект появится следующим и в какой клетке.

var _level: Difficulty.Level
var _rng: RandomNumberGenerator
## Сколько точек ещё выпадет гарантированно, без усложнений.
var _protection_left := 0
## Усложнения, которые ещё могут выпасть. Кирпич убирается, если его некуда поставить.
var _pool: Array[Item.Type] = Item.COMPLICATIONS.duplicate()


func _init(level: Difficulty.Level, rng: RandomNumberGenerator) -> void:
	_level = level
	_rng = rng


## brick_possible — функция без аргументов, отвечает, есть ли сейчас безопасное место для кирпича.
func choose_type(effects_active: bool, brick_possible: Callable) -> Item.Type:
	if not Difficulty.has_complications(_level):
		return Item.Type.DOT
	if _protection_left > 0:
		_protection_left -= 1
		return Item.Type.DOT
	if effects_active and Difficulty.waits_for_effects(_level):
		return Item.Type.DOT
	if _rng.randf() >= Difficulty.COMPLICATION_CHANCE:
		return Item.Type.DOT
	while not _pool.is_empty():
		var type: Item.Type = _pool[_rng.randi_range(0, _pool.size() - 1)]
		if type != Item.Type.BRICK or brick_possible.call():
			return type
		remove_from_pool(Item.Type.BRICK)
	return Item.Type.DOT


## Вызывается, когда змейка подобрала объект.
func on_picked(type: Item.Type) -> void:
	if Item.is_complication(type):
		_protection_left = Difficulty.protection(_level)


func remove_from_pool(type: Item.Type) -> void:
	_pool.erase(type)


func pool() -> Array[Item.Type]:
	return _pool


## Ставит объект на клетку, до которой змейка может доехать.
## Возвращает null, если свободных клеток нет совсем.
func place(type: Item.Type, board: Board, occupied: Dictionary, head: Vector2i) -> Item:
	var free := board.free_cells(occupied)
	if free.is_empty():
		return null
	var reachable := board.reachable_from(head, occupied)
	# Если змейка временно отрезала себя телом, ставим в любую свободную клетку.
	var candidates: Array[Vector2i] = reachable.keys() if not reachable.is_empty() else free
	if type == Item.Type.BIG_APPLE:
		var corners: Array[Vector2i] = []
		for cell in candidates:
			if _fits_2x2(cell, reachable):
				corners.append(cell)
		if not corners.is_empty():
			var corner := corners[_rng.randi_range(0, corners.size() - 1)]
			var cells: Array[Vector2i] = [
				corner, corner + Vector2i(1, 0), corner + Vector2i(0, 1), corner + Vector2i(1, 1),
			]
			return Item.new(type, cells)
		var single := candidates[_rng.randi_range(0, candidates.size() - 1)]
		return Item.new(type, [single], true)
	var cell := candidates[_rng.randi_range(0, candidates.size() - 1)]
	return Item.new(type, [cell])


func _fits_2x2(corner: Vector2i, reachable: Dictionary) -> bool:
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		if not reachable.has(corner + offset):
			return false
	return true
