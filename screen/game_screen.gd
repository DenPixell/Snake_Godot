class_name GameScreen
extends Node2D
## Экран Game Boy во время партии: поле, счёт, эффекты, пауза.
## Рисует в «каналы» (см. PixelArt), цвета ЖК добавляет шейдер.
## Без партии рисует только напечатанные на стекле элементы и пустое поле — поверх него меню.

signal finished(score: int, won: bool)

enum Mode { IDLE, COUNTDOWN, PLAYING, PAUSED, DYING }

## Пропорции как у экрана настоящего Game Boy: 160 × 144.
## По краям оставлен запас в 3 пикселя: рамка корпуса чуть перекрывает края экрана.
const SIZE := Vector2i(160, 144)
const CELL := 5
const FIELD_ORIGIN := Vector2i(29, 10)
## Правая колонка со счётом и рекордом.
const SIDE_X := 131
const FIELD_SIZE := Vector2i(Board.WIDTH * CELL, Board.HEIGHT * CELL)
const COUNTDOWN_TIME := 3.0
const DYING_TIME := 1.5
## Видимая зона при слепоте, в клетках.
const BLIND_CLEAR_CELLS := 4.0
const BLIND_FADE_CELLS := 2.5

## Слоты эффектов слева от поля: значок и таймер.
const EFFECT_SLOTS := [
	{"kind": Effects.Kind.INVERT, "icon": PixelArt.ICON_INVERT, "y": 14},
	{"kind": Effects.Kind.BLIND, "icon": PixelArt.ICON_EYE, "y": 58},
	{"kind": Effects.Kind.SPEED, "icon": PixelArt.ICON_LIGHTNING, "y": 100},
]

var game: SnakeGame
var mode := Mode.IDLE
var _timer := 0.0

@onready var _blind: ColorRect = $Blind


func _ready() -> void:
	_blind.position = Vector2(FIELD_ORIGIN)
	_blind.size = Vector2(FIELD_SIZE)
	_blind.material.set_shader_parameter("area_size", Vector2(FIELD_SIZE))
	_blind.material.set_shader_parameter("clear_radius", BLIND_CLEAR_CELLS * CELL)
	_blind.material.set_shader_parameter("fade_width", BLIND_FADE_CELLS * CELL)


func start(level: Difficulty.Level) -> void:
	game = SnakeGame.new(level)
	game.died.connect(_on_died)
	game.won.connect(_on_won)
	_start_countdown()


func stop() -> void:
	game = null
	mode = Mode.IDLE
	_blind.visible = false


func _process(delta: float) -> void:
	queue_redraw()
	if game == null:
		return
	_handle_input()
	match mode:
		Mode.COUNTDOWN:
			_timer -= delta
			if _timer <= 0.0:
				mode = Mode.PLAYING
		Mode.PLAYING:
			game.tick(delta)
		Mode.DYING:
			_timer -= delta
			if _timer <= 0.0:
				finished.emit(game.score, false)
				return
	_update_blind()


func _handle_input() -> void:
	match mode:
		Mode.PLAYING:
			for action: String in ["gb_up", "gb_down", "gb_left", "gb_right"]:
				if Input.is_action_just_pressed(action):
					game.turn(_direction_of(action))
			if Input.is_action_just_pressed("gb_a"):
				mode = Mode.PAUSED
		Mode.PAUSED:
			if Input.is_action_just_pressed("gb_b"):
				_start_countdown()


func _direction_of(action: String) -> Vector2i:
	match action:
		"gb_up":
			return Vector2i.UP
		"gb_down":
			return Vector2i.DOWN
		"gb_left":
			return Vector2i.LEFT
	return Vector2i.RIGHT


func _start_countdown() -> void:
	mode = Mode.COUNTDOWN
	_timer = COUNTDOWN_TIME


func _on_died() -> void:
	mode = Mode.DYING
	_timer = DYING_TIME


func _on_won() -> void:
	finished.emit(game.score, true)


func _update_blind() -> void:
	var blind := game.effects.is_active(Effects.Kind.BLIND) \
			and mode in [Mode.PLAYING, Mode.COUNTDOWN, Mode.DYING]
	_blind.visible = blind
	if blind:
		var center := Vector2(game.head() * CELL) + Vector2.ONE * CELL * 0.5
		_blind.material.set_shader_parameter("head_center", center)


func _draw() -> void:
	_draw_hud()
	match mode:
		Mode.IDLE:
			draw_rect(Rect2(FIELD_ORIGIN, FIELD_SIZE), PixelArt.MATRIX)
		Mode.PAUSED:
			draw_rect(Rect2(FIELD_ORIGIN, FIELD_SIZE), PixelArt.MATRIX)
			draw_lines(self, ["PAUSE", "", "B - PLAY"])
		_:
			_draw_field()
			if mode == Mode.COUNTDOWN:
				_draw_countdown()


func _draw_hud() -> void:
	var score := game.score if game != null else 0
	PixelArt.draw_tiny(self, "SCORE", Vector2i(SIDE_X + 3, 14))
	PixelArt.draw_number(self, score, 4, Vector2i(SIDE_X, 22), game != null)
	# Лучший результат на этой сложности. На Easy рекордов нет — цифры только «призраком».
	var best := _best_score()
	PixelArt.draw_tiny(self, "BEST", Vector2i(SIDE_X + 5, 44))
	PixelArt.draw_number(self, best, 4, Vector2i(SIDE_X, 52), best > 0)
	# Рамка поля напечатана на стекле и горит всегда.
	draw_rect(Rect2(FIELD_ORIGIN - Vector2i.ONE, FIELD_SIZE + Vector2i(2, 2)), PixelArt.INK, false, 1.0)
	for slot: Dictionary in EFFECT_SLOTS:
		_draw_effect_slot(slot)


func _best_score() -> int:
	if game == null or not Difficulty.has_leaderboard(game.level):
		return 0
	var entries := Records.board(game.level).entries
	return entries[0]["score"] if not entries.is_empty() else 0


func _draw_effect_slot(slot: Dictionary) -> void:
	var icon: Array = slot["icon"]
	var icon_width: int = icon[0].length()
	var y: int = slot["y"]
	var icon_origin := Vector2i(13 - icon_width / 2, y)
	var left := game.effects.time_left(slot["kind"]) if game != null else 0.0
	# В последние полторы секунды значок мигает, предупреждая о конце эффекта.
	var blink_off := left < 1.5 and fmod(Time.get_ticks_msec() / 1000.0, 0.3) < 0.15
	var lit := left > 0.0 and not blink_off
	PixelArt.draw_pattern(self, icon, icon_origin, PixelArt.GHOST)
	if lit:
		PixelArt.draw_pattern(self, icon, icon_origin, PixelArt.INK)
	PixelArt.draw_number(self, ceili(left), 2, Vector2i(7, y + 13), left > 0.0)


func _draw_field() -> void:
	draw_rect(Rect2(FIELD_ORIGIN, FIELD_SIZE), PixelArt.MATRIX)
	for brick in game.board.bricks():
		PixelArt.draw_pattern(self, PixelArt.WALL, _cell_origin(brick), PixelArt.INK)
	_draw_item()
	# Во время смерти змейка мигает.
	if mode == Mode.DYING and fmod(_timer, 0.3) < 0.15:
		return
	_draw_snake()


func _draw_item() -> void:
	var item := game.item
	if item == null:
		return
	var origin := _cell_origin(item.cells[0])
	if item.type == Item.Type.BIG_APPLE and not item.compact:
		PixelArt.draw_pattern(self, PixelArt.BIG_APPLE, origin, PixelArt.INK)
		return
	PixelArt.draw_pattern(self, PixelArt.SPRITES[item.type], origin, PixelArt.INK)
	if item.compact:
		# Пометка «x2» над клеткой, а у верхнего края — под ней.
		var above := origin + Vector2i(-1, -CELL - 1)
		if item.cells[0].y == 0:
			above = origin + Vector2i(-1, CELL + 1)
		PixelArt.draw_tiny(self, "x2", above)


func _draw_snake() -> void:
	var body := game.body
	for i in body.size():
		draw_rect(Rect2(_cell_origin(body[i]), Vector2.ONE * (CELL - 1)), PixelArt.INK)
		# Перемычка между соседними сегментами, чтобы тело было сплошным.
		if i > 0:
			var a := _cell_origin(body[i - 1])
			var b := _cell_origin(body[i])
			var top_left := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
			var bottom_right := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y)) + Vector2i.ONE * (CELL - 1)
			draw_rect(Rect2(top_left, bottom_right - top_left), PixelArt.INK)
	_draw_eyes()


## Глаза — два погашенных пикселя на голове, смотрят по ходу движения.
func _draw_eyes() -> void:
	var origin := _cell_origin(game.head())
	var eyes: Array[Vector2i]
	match game.direction:
		Vector2i.UP:
			eyes = [Vector2i(1, 1), Vector2i(2, 1)]
		Vector2i.DOWN:
			eyes = [Vector2i(1, 2), Vector2i(2, 2)]
		Vector2i.LEFT:
			eyes = [Vector2i(1, 1), Vector2i(1, 2)]
		_:
			eyes = [Vector2i(2, 1), Vector2i(2, 2)]
	for eye in eyes:
		draw_rect(Rect2(origin + eye, Vector2.ONE), PixelArt.MATRIX)


func _draw_countdown() -> void:
	var text := str(ceili(_timer))
	var box := Rect2(FIELD_ORIGIN + FIELD_SIZE / 2 - Vector2i(7, 8), Vector2i(15, 15))
	draw_rect(box, PixelArt.MATRIX)
	draw_rect(box, PixelArt.INK, false, 1.0)
	PixelArt.draw_text(self, text, Vector2i(box.position) + Vector2i(5, 4))


## Текст по центру поля, построчно. Нужен и экрану игры, и меню.
static func draw_lines(canvas: CanvasItem, lines: Array, center_y := FIELD_ORIGIN.y + FIELD_SIZE.y / 2) -> void:
	var line_height := PixelArt.GLYPH_HEIGHT + 4
	var y: int = center_y - lines.size() * line_height / 2
	for line: String in lines:
		var x := FIELD_ORIGIN.x + (FIELD_SIZE.x - PixelArt.text_width(line)) / 2
		PixelArt.draw_text(canvas, line, Vector2i(x, y))
		y += line_height


func _cell_origin(cell: Vector2i) -> Vector2i:
	return FIELD_ORIGIN + cell * CELL
