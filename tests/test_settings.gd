extends TestCase


func test_key_binding_round_trip() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	var text := InputBinding.to_text(key)
	check_eq(text, "key:%d" % KEY_W, "в строку")
	var back := InputBinding.from_text(text) as InputEventKey
	check(back != null and back.physical_keycode == KEY_W, "обратно")


func test_mouse_binding_round_trip() -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	var back := InputBinding.from_text(InputBinding.to_text(mouse)) as InputEventMouseButton
	check(back != null and back.button_index == MOUSE_BUTTON_RIGHT, "правая кнопка мыши")


func test_broken_binding_is_null() -> void:
	check(InputBinding.from_text("") == null, "пустая строка")
	check(InputBinding.from_text("key:abc") == null, "не число")
	check(InputBinding.from_text("joy:1") == null, "неизвестный тип")


func test_mouse_wheel_not_bindable() -> void:
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	check(not InputBinding.is_bindable(wheel), "колесо прокрутки не назначаем")


func test_menu_texts_have_russian() -> void:
	for key: String in ["PLAY", "SETTINGS", "EXIT", "CONTINUE", "MAIN MENU", "BACK"]:
		check(Texts.translate(key, "ru") != key, "есть перевод: " + key)
	check_eq(Texts.translate("PLAY", "en"), "PLAY", "английский как есть")


func test_russian_texts_drawable() -> void:
	# Каждая буква перевода должна быть в пиксельном шрифте.
	for text: String in Texts.RU.values():
		for ch in text.to_upper():
			var glyph: String = PixelArt.SAME_AS_LATIN.get(ch, ch)
			check(ch == " " or PixelArt.FONT.has(glyph), "нет буквы «%s» в «%s»" % [ch, text])
