// Надпись SNAKE: градиентная заливка, чёрная и белая обводка, бегущий блик и искры по пикселям.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D art : filter_nearest;
uniform vec2 art_size;
uniform vec3 top_color : source_color = vec3(1.0, 0.96, 0.35);
uniform vec3 bottom_color : source_color = vec3(0.35, 0.78, 0.12);
uniform float shimmer_speed = 2.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 15731.743);
}

void fragment() {
	vec4 mask = texture(art, UV);
	if (mask.r + mask.g + mask.b < 0.5) {
		discard;
	}
	vec2 pixel = floor(UV * art_size);
	vec3 color;
	if (mask.r > 0.5) {
		color = mix(top_color, bottom_color, UV.y);
		// Диагональный блик бежит по буквам слева направо.
		float band = sin((pixel.x - pixel.y * 0.7) * 0.3 - TIME * shimmer_speed);
		color += vec3(0.35) * pow(max(band, 0.0), 6.0);
		// Редкие искры в отдельных пикселях.
		if (hash(pixel + floor(TIME * 8.0)) > 0.985) {
			color = vec3(1.0);
		}
	} else if (mask.g > 0.5) {
		color = vec3(0.02);
	} else {
		color = vec3(0.92);
	}
	ALBEDO = color;
}
