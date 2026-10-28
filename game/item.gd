class_name Item
extends RefCounted
## Объект на поле: точка или одно из усложнений.

enum Type { DOT, BRICK, ROTTEN_APPLE, ROTTEN_BANANA, BIG_APPLE, LIGHTNING }

## Все усложнения. Из этого списка выбирается случайное.
const COMPLICATIONS: Array[Type] = [
	Type.BRICK, Type.ROTTEN_APPLE, Type.ROTTEN_BANANA, Type.BIG_APPLE, Type.LIGHTNING,
]

var type: Type
## Клетки, которые занимает объект. Обычно одна, у большого яблока четыре.
var cells: Array[Vector2i] = []
## Большое яблоко, которому не хватило места 2 × 2: рисуется в одну клетку с «x2».
var compact := false


func _init(item_type: Type, item_cells: Array[Vector2i], is_compact := false) -> void:
	type = item_type
	cells = item_cells
	compact = is_compact


func occupies(cell: Vector2i) -> bool:
	return cells.has(cell)


static func is_complication(item_type: Type) -> bool:
	return item_type != Type.DOT
