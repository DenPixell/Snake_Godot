// Слепота: всё поле, кроме круга вокруг головы, затягивается пиксельным дизерингом.
// Чем дальше от головы, тем больше точек внутри клетки горит.
shader_type canvas_item;

uniform vec2 area_size;       // размер поля в пикселях
uniform vec2 head_center;     // центр головы в пикселях поля
uniform float clear_radius;   // до этого радиуса всё видно
uniform float fade_width;     // ширина перехода
uniform float max_darkness = 0.92;
uniform float strength = 1.0; // для плавного появления и исчезновения

// Матрица Байера 4 × 4: порядок, в котором загораются точки.
const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec2 p = floor(UV * area_size);
	float dist = distance(p + 0.5, head_center);
	float darkness = clamp((dist - clear_radius) / fade_width, 0.0, 1.0) * max_darkness * strength;
	int index = int(mod(p.y, 4.0)) * 4 + int(mod(p.x, 4.0));
	float threshold = (BAYER[index] + 0.5) / 16.0;
	// Красный — горящий пиксель, синий сохраняет матрицу поля.
	COLOR = darkness > threshold ? vec4(1.0, 0.0, 1.0, 1.0) : vec4(0.0);
}
