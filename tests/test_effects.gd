extends TestCase


func test_effect_lasts_five_seconds() -> void:
	var effects := Effects.new()
	effects.add(Effects.Kind.BLIND)
	effects.tick(4.9)
	check(effects.is_active(Effects.Kind.BLIND), "ещё действует")
	effects.tick(0.2)
	check(not effects.is_active(Effects.Kind.BLIND), "закончился")


func test_repeat_adds_five_seconds() -> void:
	var effects := Effects.new()
	effects.add(Effects.Kind.BLIND)
	effects.tick(2.0)
	effects.add(Effects.Kind.BLIND)
	check(is_equal_approx(effects.time_left(Effects.Kind.BLIND), 8.0), "3 + 5 = 8 секунд")


func test_items_map_to_effects() -> void:
	check_eq(Effects.from_item(Item.Type.ROTTEN_APPLE), Effects.Kind.INVERT, "гнилое яблоко")
	check_eq(Effects.from_item(Item.Type.ROTTEN_BANANA), Effects.Kind.BLIND, "гнилой банан")
	check_eq(Effects.from_item(Item.Type.LIGHTNING), Effects.Kind.SPEED, "молния")
	check_eq(Effects.from_item(Item.Type.DOT), -1, "у точки эффекта нет")
