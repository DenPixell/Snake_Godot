// Общая часть шейдера ЖК-экрана. Подключается и в 2D-превью, и на 3D-корпусе.
// Текстура экрана хранит каналы: R — горящий пиксель, G — напечатанный сегмент,
// B — точечная матрица поля. Здесь они превращаются в цвета старого ЖК.

uniform vec2 screen_size = vec2(160.0, 144.0);
uniform vec3 backlight : source_color = vec3(0.60, 0.70, 0.22);
uniform vec3 ink_color : source_color = vec3(0.08, 0.13, 0.05);
// Насколько видны выключенные сегменты и матрица без бликов.
uniform float ghost_strength = 0.07;
uniform float matrix_strength = 0.03;
// Чит по коду Конами: подсветка переливается радугой (0 — обычная, 1 — радуга).
uniform float rainbow = 0.0;

vec3 hue_to_rgb(float hue) {
	vec3 k = abs(fract(vec3(hue) + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0;
	return clamp(k, 0.0, 1.0);
}

// time — время в секундах, нужно только для радуги (TIME недоступен во вспомогательных функциях).
vec3 lcd_color(sampler2D data, vec2 uv, float glint, float time) {
	vec2 pixel = 1.0 / screen_size;
	vec4 d = texture(data, uv);
	// Тень пикселя на подложке, чуть ниже и правее — так выглядят старые ЖК.
	float shadow = texture(data, uv - pixel * 0.6).r;

	// Промежутки между пикселями: каждая точка матрицы видна отдельно.
	// Края сглажены через fwidth, иначе при мелком экране сетка рябит.
	vec2 grid = uv * screen_size;
	vec2 f = fract(grid);
	vec2 gap = clamp((0.12 - f) / max(fwidth(grid), vec2(0.0001)) + 0.5, 0.0, 1.0);
	float cell = (1.0 - gap.x * 0.7) * (1.0 - gap.y * 0.7);

	float ink = d.r * cell * 0.92;
	float ghost = d.g * (ghost_strength + glint);
	float matrix = d.b * cell * (matrix_strength + glint * 0.4);
	float shade = max(ink, max(ghost, max(matrix, shadow * 0.18)));

	// Радужные полосы бегут по экрану по диагонали.
	vec3 light = mix(backlight, hue_to_rgb(uv.x * 0.6 + uv.y * 0.4 - time * 0.35) * 0.85 + 0.1, rainbow);
	vec3 color = mix(light, ink_color, clamp(shade, 0.0, 1.0));
	// Подсветка неравномерная: к краям темнее.
	vec2 centered = uv - 0.5;
	color *= 1.0 - dot(centered, centered) * 0.9;
	return color;
}
