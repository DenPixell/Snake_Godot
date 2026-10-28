// Экран Game Boy в плоском окне, без 3D.
shader_type canvas_item;

#include "res://screen/lcd.gdshaderinc"

uniform sampler2D screen_data : filter_nearest;

void fragment() {
	// Блик слегка гуляет по экрану, чтобы были заметны выключенные сегменты.
	float glint = 0.05 * max(0.0, sin(TIME * 0.7 + UV.x * 3.0 - UV.y * 2.0));
	COLOR = vec4(lcd_color(screen_data, UV, glint), 1.0);
}
