class_name TitleArt
extends RefCounted
## Пиксельная надпись SNAKE для главного меню в духе граффити 2000-х.
## Строит маленькую картинку-маску: R — заливка буквы, G — чёрная обводка, B — белая обводка.
## Цвета, градиент и переливание добавляет шейдер title.gdshader.

## Буквы 7 × 9, штрих в два пикселя.
const GLYPHS := {
	"S": [".#####.", "##...##", "##.....", "###....", ".#####.", "....###", ".....##", "##...##", ".#####."],
	"N": ["##...##", "###..##", "####.##", "##.####", "##..###", "##...##", "##...##", "##...##", "##...##"],
	"A": ["..###..", ".##.##.", "##...##", "##...##", "#######", "##...##", "##...##", "##...##", "##...##"],
	"K": ["##...##", "##..##.", "##.##..", "####...", "###....", "####...", "##.##..", "##..##.", "##...##"],
	"E": ["#######", "##.....", "##.....", "######.", "##.....", "##.....", "##.....", "##.....", "#######"],
}
const GLYPH_SIZE := Vector2i(7, 9)
const SPACING := 2
## Наклон вправо: верхние строки сдвигаются сильнее нижних.
const SLANT := 3
const MARGIN := 3


static func build(text := "SNAKE") -> ImageTexture:
	var width := text.length() * (GLYPH_SIZE.x + SPACING) - SPACING + SLANT + MARGIN * 2
	var height := GLYPH_SIZE.y + MARGIN * 2
	var fill := {}
	var x := MARGIN
	for ch in text:
		var rows: Array = GLYPHS[ch]
		for y in GLYPH_SIZE.y:
			var shift := SLANT * (GLYPH_SIZE.y - 1 - y) / (GLYPH_SIZE.y - 1)
			var row: String = rows[y]
			for gx in GLYPH_SIZE.x:
				if row[gx] == "#":
					fill[Vector2i(x + gx + shift, MARGIN + y)] = true
		x += GLYPH_SIZE.x + SPACING
	var inner := _grow(fill)
	var outer := _grow(inner)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for cell: Vector2i in outer:
		var color := Color(0, 0, 1, 1)
		if fill.has(cell):
			color = Color(1, 0, 0, 1)
		elif inner.has(cell):
			color = Color(0, 1, 0, 1)
		image.set_pixelv(cell, color)
	return ImageTexture.create_from_image(image)


## Клетки плюс все соседние (в том числе по диагонали) — так получается обводка в 1 пиксель.
static func _grow(cells: Dictionary) -> Dictionary:
	var result := cells.duplicate()
	for cell: Vector2i in cells:
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				result[cell + Vector2i(dx, dy)] = true
	return result
