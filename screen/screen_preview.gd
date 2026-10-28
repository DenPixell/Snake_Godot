extends Control
## Экран Game Boy в обычном окне, без 3D. Нужен, чтобы проверять геймплей отдельно.

const GAME_SCREEN := preload("res://screen/game_screen.tscn")
const LCD_SHADER := preload("res://screen/lcd_preview.gdshader")


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = GameScreen.SIZE
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	var screen: GameScreen = GAME_SCREEN.instantiate()
	viewport.add_child(screen)
	screen.start(Difficulty.Level.NORMAL)

	var material := ShaderMaterial.new()
	material.shader = LCD_SHADER
	material.set_shader_parameter("screen_data", viewport.get_texture())

	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.material = material
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(display)
