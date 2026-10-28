class_name Handheld
extends Node2D
## Всё, что показывает Game Boy: меню, выбор сложности, рекорды, игра, ввод имени, Game Over.
## Кнопки: крестовина — выбор, A — выбрать, B — назад, Start — в меню Game Boy.

enum Page { MAIN, DIFFICULTY, LEADERBOARD, GAME, NAME_ENTRY, GAME_OVER }

const MAIN_ITEMS := ["PLAY", "LEADERBOARD"]
const LEVEL_ITEMS := ["EASY", "NORMAL", "HARD"]
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const FIELD_ORIGIN := GameScreen.FIELD_ORIGIN
const FIELD_SIZE := GameScreen.FIELD_SIZE

var page := Page.MAIN
var _cursor := 0
var _level := Difficulty.Level.NORMAL
## Какую таблицу рекордов показываем.
var _board_level := Difficulty.Level.NORMAL
var _last_score := 0
var _last_won := false
var _last_rank := -1
## Имя в рекордах: номера букв и какая сейчас выбрана.
var _name_letters: Array[int] = [0, 0, 0]
var _name_cursor := 0

@onready var _game: GameScreen = $GameScreen
@onready var _menu_layer: Node2D = $MenuLayer


func _ready() -> void:
	_game.finished.connect(_on_game_finished)
	# Меню рисуется отдельным узлом поверх экрана игры.
	_menu_layer.draw.connect(_draw_menu)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("gb_start") and page != Page.MAIN:
		_game.stop()
		_open(Page.MAIN)
	match page:
		Page.MAIN:
			_handle_list(MAIN_ITEMS.size(), _on_main_selected, Callable())
		Page.DIFFICULTY:
			_handle_list(LEVEL_ITEMS.size(), _on_level_selected, _open.bind(Page.MAIN, 0))
		Page.LEADERBOARD:
			_handle_leaderboard()
		Page.NAME_ENTRY:
			_handle_name_entry()
		Page.GAME_OVER:
			if Input.is_action_just_pressed("gb_a"):
				_start_game()
			elif Input.is_action_just_pressed("gb_b"):
				_open(Page.MAIN)
	_menu_layer.queue_redraw()


func _open(new_page: Page, cursor := 0) -> void:
	page = new_page
	_cursor = cursor


## Вертикальный список: вверх-вниз двигают курсор, A выбирает, B — назад.
func _handle_list(count: int, on_select: Callable, on_back: Callable) -> void:
	if Input.is_action_just_pressed("gb_up"):
		_cursor = wrapi(_cursor - 1, 0, count)
	elif Input.is_action_just_pressed("gb_down"):
		_cursor = wrapi(_cursor + 1, 0, count)
	elif Input.is_action_just_pressed("gb_a"):
		on_select.call(_cursor)
	elif Input.is_action_just_pressed("gb_b") and on_back.is_valid():
		on_back.call()


func _on_main_selected(index: int) -> void:
	if index == 0:
		_open(Page.DIFFICULTY, _level)
	else:
		_open(Page.LEADERBOARD)


func _on_level_selected(index: int) -> void:
	_level = index as Difficulty.Level
	_start_game()


func _start_game() -> void:
	page = Page.GAME
	_game.start(_level)


func _on_game_finished(score: int, won: bool) -> void:
	_game.stop()
	_last_score = score
	_last_won = won
	_last_rank = -1
	if Records.qualifies(_level, score):
		_name_cursor = 0
		_open(Page.NAME_ENTRY)
	else:
		_open(Page.GAME_OVER)


func _handle_leaderboard() -> void:
	if Input.is_action_just_pressed("gb_left") or Input.is_action_just_pressed("gb_right"):
		_board_level = Difficulty.Level.HARD if _board_level == Difficulty.Level.NORMAL \
				else Difficulty.Level.NORMAL
	elif Input.is_action_just_pressed("gb_b"):
		_open(Page.MAIN, 1)


## Имя как в аркадах: вверх-вниз меняют букву, влево-вправо — позицию, A — готово.
func _handle_name_entry() -> void:
	var letters := LETTERS.length()
	if Input.is_action_just_pressed("gb_up"):
		_name_letters[_name_cursor] = wrapi(_name_letters[_name_cursor] + 1, 0, letters)
	elif Input.is_action_just_pressed("gb_down"):
		_name_letters[_name_cursor] = wrapi(_name_letters[_name_cursor] - 1, 0, letters)
	elif Input.is_action_just_pressed("gb_left"):
		_name_cursor = maxi(_name_cursor - 1, 0)
	elif Input.is_action_just_pressed("gb_right"):
		_name_cursor = mini(_name_cursor + 1, Leaderboard.NAME_LENGTH - 1)
	elif Input.is_action_just_pressed("gb_a"):
		_last_rank = Records.add(_level, _entered_name(), _last_score)
		_open(Page.GAME_OVER)


func _entered_name() -> String:
	var result := ""
	for index in _name_letters:
		result += LETTERS[index]
	return result


func _draw_menu() -> void:
	var canvas := _menu_layer
	match page:
		Page.MAIN:
			var title_width := PixelArt.text_width("SNAKE", 2)
			PixelArt.draw_text(canvas, "SNAKE",
					Vector2i(FIELD_ORIGIN.x + (FIELD_SIZE.x - title_width) / 2, FIELD_ORIGIN.y + 30),
					PixelArt.INK, 2)
			_draw_list(canvas, MAIN_ITEMS, FIELD_ORIGIN.y + 80)
		Page.DIFFICULTY:
			GameScreen.draw_lines(canvas, ["DIFFICULTY"], FIELD_ORIGIN.y + 30)
			_draw_list(canvas, LEVEL_ITEMS, FIELD_ORIGIN.y + 60)
		Page.LEADERBOARD:
			_draw_leaderboard(canvas)
		Page.NAME_ENTRY:
			_draw_name_entry(canvas)
		Page.GAME_OVER:
			var lines := ["YOU WIN" if _last_won else "GAME OVER", "", "SCORE %d" % _last_score]
			if _last_rank >= 0:
				lines.append("RANK %d" % (_last_rank + 1))
			lines.append_array(["", "A - RETRY", "B - MENU"])
			GameScreen.draw_lines(canvas, lines)


## Пункты списка с треугольником-курсором слева от выбранного.
func _draw_list(canvas: CanvasItem, items: Array, top: int) -> void:
	var left := FIELD_ORIGIN.x + 26
	for i in items.size():
		var y := top + i * 14
		PixelArt.draw_text(canvas, items[i], Vector2i(left, y))
		if i == _cursor:
			PixelArt.draw_text(canvas, ">", Vector2i(left - 10, y))


func _draw_leaderboard(canvas: CanvasItem) -> void:
	var title := "< %s >" % Difficulty.Level.keys()[_board_level]
	GameScreen.draw_lines(canvas, [title], FIELD_ORIGIN.y + 12)
	var entries := Records.board(_board_level).entries
	for i in Leaderboard.SIZE:
		var y := FIELD_ORIGIN.y + 28 + i * 11
		var row := "%2d ---  ----" % (i + 1)
		if i < entries.size():
			row = "%2d %s  %04d" % [i + 1, entries[i]["name"], entries[i]["score"]]
		PixelArt.draw_text(canvas, row, Vector2i(FIELD_ORIGIN.x + 14, y))


func _draw_name_entry(canvas: CanvasItem) -> void:
	GameScreen.draw_lines(canvas, ["NEW RECORD", "", "SCORE %d" % _last_score], FIELD_ORIGIN.y + 40)
	var scale := 2
	var step := (PixelArt.GLYPH_WIDTH + 3) * scale
	var left := FIELD_ORIGIN.x + (FIELD_SIZE.x - step * Leaderboard.NAME_LENGTH) / 2
	var y := FIELD_ORIGIN.y + 80
	for i in Leaderboard.NAME_LENGTH:
		var x := left + i * step
		PixelArt.draw_text(canvas, LETTERS[_name_letters[i]], Vector2i(x, y), PixelArt.INK, scale)
		if i == _name_cursor:
			canvas.draw_rect(Rect2(x, y + 17, PixelArt.GLYPH_WIDTH * scale, 2), PixelArt.INK)
	GameScreen.draw_lines(canvas, ["A - OK"], FIELD_ORIGIN.y + 125)
