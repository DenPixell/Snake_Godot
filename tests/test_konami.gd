extends TestCase


func _feed(code: KonamiCode, actions: Array) -> bool:
	var done := false
	for action: String in actions:
		done = code.feed(action)
	return done


func test_full_code_works() -> void:
	check(_feed(KonamiCode.new(), KonamiCode.SEQUENCE), "код введён")


func test_wrong_button_breaks_code() -> void:
	var actions := KonamiCode.SEQUENCE.duplicate()
	actions[5] = "gb_up"
	check(not _feed(KonamiCode.new(), actions), "ошибка в середине")


func test_extra_presses_before_code_are_fine() -> void:
	# Лишнее «вверх» в начале не мешает: важны последние десять нажатий.
	check(_feed(KonamiCode.new(), ["gb_up", "gb_a"] + KonamiCode.SEQUENCE), "лишнее перед кодом")


func test_code_works_again() -> void:
	var code := KonamiCode.new()
	_feed(code, KonamiCode.SEQUENCE)
	check(_feed(code, KonamiCode.SEQUENCE), "второй раз тоже")
