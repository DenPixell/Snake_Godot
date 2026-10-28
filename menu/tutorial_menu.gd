class_name TutorialMenu
extends Control
## Обучение: что делает каждый предмет на поле. Числа берутся из правил игры,
## поэтому описание не разойдётся с тем, что происходит в игре.

signal closed

const PIXEL := 3


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.85)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	center.add_child(root)
	root.add_child(_label("TUTORIAL", 8, PixelButton.HOVER))

	var seconds := int(Effects.DURATION)
	_item(root, PixelArt.SPRITES[Item.Type.DOT], [], "DOT", "+1 LENGTH, +1 SCORE", [])
	_item(root, PixelArt.BIG_APPLE, [], "BIG APPLE", "+%d-%d LENGTH, +1 SCORE",
			[SnakeGame.BIG_APPLE_GROWTH_MIN, SnakeGame.BIG_APPLE_GROWTH_MAX])
	_item(root, PixelArt.SPRITES[Item.Type.ROTTEN_APPLE], PixelArt.ICON_INVERT, "ROTTEN APPLE",
			"CONTROLS INVERTED FOR %d SEC", [seconds])
	_item(root, PixelArt.SPRITES[Item.Type.ROTTEN_BANANA], PixelArt.ICON_EYE, "ROTTEN BANANA",
			"BLIND FOR %d SEC: YOU SEE ONLY NEAR THE HEAD", [seconds])
	_item(root, PixelArt.SPRITES[Item.Type.LIGHTNING], PixelArt.ICON_LIGHTNING, "LIGHTNING",
			"+%d SPEED FOR %d SEC", [int(SnakeGame.LIGHTNING_BONUS), seconds])
	_item(root, PixelArt.SPRITES[Item.Type.BRICK], PixelArt.WALL, "BRICK",
			"PUTS A WALL ON THE FIELD FOREVER", [])

	for note: Array in [
		["ICONS ON THE LEFT OF THE SCREEN SHOW TIME LEFT", []],
		["THE SAME EFFECT AGAIN ADDS %d SEC", [seconds]],
		["EASY: NO TRAPS", []],
		["NORMAL: %d SAFE DOTS AFTER A TRAP", [Difficulty.NORMAL_PROTECTION]],
		["HARD: TRAPS AT ANY TIME", []],
	]:
		root.add_child(_text(note[0], note[1], PIXEL, PixelLabel.new().color))

	var back := PixelButton.new()
	back.text = "BACK"
	back.pixel = 4
	back.pressed.connect(close)
	root.add_child(back)


func close() -> void:
	visible = false
	closed.emit()


## Строка: картинка предмета, значок эффекта (если есть), название и описание.
func _item(parent: Control, sprite: Array, effect_icon: Array, title: String,
		description: String, values: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var icon := PixelIcon.new()
	icon.pattern = sprite
	row.add_child(icon)
	var effect := PixelIcon.new()
	effect.pattern = effect_icon
	effect.modulate.a = 1.0 if not effect_icon.is_empty() else 0.0
	row.add_child(effect)
	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_child(_label(title, 4, PixelButton.HOVER))
	texts.add_child(_text(description, values, PIXEL, PixelButton.NORMAL))
	row.add_child(texts)
	parent.add_child(row)


func _label(text: String, pixel: int, color: Color) -> PixelLabel:
	var label := PixelLabel.new()
	label.text = text
	label.pixel = pixel
	label.color = color
	return label


## Подпись с числами: сначала переводим шаблон, потом подставляем значения.
func _text(template: String, values: Array, pixel: int, color: Color) -> PixelLabel:
	var label := _label(template, pixel, color)
	label.values = values
	return label
