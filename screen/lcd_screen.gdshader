// Экран Game Boy на 3D-корпусе: ЖК с подсветкой, царапины, блики под углом.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://screen/lcd.gdshaderinc"

uniform sampler2D screen_data : filter_nearest;
// Участок UV модели, на который натянут экран. Пересчитываем его в 0..1.
uniform vec2 uv_min = vec2(0.0);
uniform vec2 uv_max = vec2(1.0);
uniform bool flip_x = false;
uniform bool flip_y = false;
uniform float brightness = 1.0;
uniform float scratch_amount = 0.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Тонкие светлые царапины: несколько отрезков под случайными углами.
float scratches(vec2 uv) {
	float result = 0.0;
	for (int i = 0; i < 14; i++) {
		float fi = float(i);
		vec2 center = vec2(hash(vec2(fi, 1.3)), hash(vec2(fi, 7.9)));
		float angle = hash(vec2(fi, 3.1)) * 3.14159;
		vec2 dir = vec2(cos(angle), sin(angle));
		vec2 d = uv - center;
		float along = dot(d, dir);
		float across = abs(dot(d, vec2(-dir.y, dir.x)));
		float len = 0.05 + hash(vec2(fi, 5.5)) * 0.25;
		float line = smoothstep(0.0012, 0.0, across) * step(abs(along), len);
		result = max(result, line * (0.4 + 0.6 * hash(vec2(fi, 9.2))));
	}
	return result;
}

void fragment() {
	vec2 uv = (UV - uv_min) / (uv_max - uv_min);
	if (flip_x) uv.x = 1.0 - uv.x;
	if (flip_y) uv.y = 1.0 - uv.y;

	// Чем сильнее смотрим вбок, тем заметнее выключенные сегменты, как на настоящем ЖК.
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float glint = pow(1.0 - facing, 2.0) * 0.6;

	vec3 color = lcd_color(screen_data, uv, glint, TIME) * brightness;
	color += vec3(0.08, 0.09, 0.05) * scratches(uv) * scratch_amount;
	ALBEDO = color;
}
