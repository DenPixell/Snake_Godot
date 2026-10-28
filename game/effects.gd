class_name Effects
extends RefCounted
## Временные эффекты от усложнений и их таймеры.

enum Kind { INVERT, BLIND, SPEED }

const DURATION := 5.0

## Сколько секунд осталось у каждого активного эффекта.
var _left: Dictionary[Kind, float] = {}


## Новый эффект длится 5 секунд, повторный добавляет ещё 5 к оставшемуся времени.
func add(kind: Kind) -> void:
	_left[kind] = _left.get(kind, 0.0) + DURATION


func tick(delta: float) -> void:
	for kind: Kind in _left.keys():
		_left[kind] -= delta
		if _left[kind] <= 0.0:
			_left.erase(kind)


func is_active(kind: Kind) -> bool:
	return _left.has(kind)


func any_active() -> bool:
	return not _left.is_empty()


func time_left(kind: Kind) -> float:
	return _left.get(kind, 0.0)


func clear() -> void:
	_left.clear()


## Какой эффект даёт объект. -1, если никакого.
static func from_item(item_type: Item.Type) -> int:
	match item_type:
		Item.Type.ROTTEN_APPLE:
			return Kind.INVERT
		Item.Type.ROTTEN_BANANA:
			return Kind.BLIND
		Item.Type.LIGHTNING:
			return Kind.SPEED
	return -1
