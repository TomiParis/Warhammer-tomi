shader_type canvas_item;

// Fondo de estrellas procedural para el mapa galáctico
// Genera estrellas como puntos brillantes sobre fondo negro

uniform float star_density : hint_range(50.0, 500.0) = 200.0;
uniform float star_brightness : hint_range(0.2, 1.0) = 0.6;
uniform float twinkle_speed : hint_range(0.0, 2.0) = 0.4;
uniform vec4 bg_color : source_color = vec4(0.01, 0.01, 0.03, 1.0);
uniform vec4 nebula_color_1 : source_color = vec4(0.15, 0.05, 0.2, 0.08);
uniform vec4 nebula_color_2 : source_color = vec4(0.05, 0.1, 0.25, 0.06);

// Hash para generar pseudo-random por posición
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Noise suave para nebulosas
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;

	// Fondo base
	vec3 col = bg_color.rgb;

	// Nebulosas sutiles (ruido a escala grande)
	float n1 = noise(uv * 3.0 + vec2(0.5, 0.3));
	float n2 = noise(uv * 4.5 + vec2(2.1, 1.7));
	col += nebula_color_1.rgb * nebula_color_1.a * smoothstep(0.35, 0.7, n1);
	col += nebula_color_2.rgb * nebula_color_2.a * smoothstep(0.4, 0.75, n2);

	// Capa de estrellas
	vec2 grid = floor(uv * star_density);
	float star_val = hash(grid);

	if (star_val > 0.92) {
		// Posición de la estrella dentro de su celda
		vec2 star_pos = grid + vec2(hash(grid + 0.5), hash(grid + 1.5));
		star_pos /= star_density;
		float dist = length(uv - star_pos) * star_density;

		// Brillo con falloff suave
		float brightness = star_val * star_brightness;
		// Twinkle sutil
		brightness *= 0.8 + 0.2 * sin(TIME * twinkle_speed + star_val * 50.0);

		float glow = smoothstep(0.8, 0.0, dist) * brightness;

		// Color de la estrella (variación sutil azul-blanco-amarillo)
		vec3 star_col = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.95, 0.8), hash(grid + 3.0));
		col += star_col * glow;
	}

	// Segunda capa de estrellas más tenues (profundidad)
	vec2 grid2 = floor(uv * star_density * 2.5);
	float star_val2 = hash(grid2 + vec2(7.7, 3.3));

	if (star_val2 > 0.95) {
		vec2 star_pos2 = grid2 + vec2(hash(grid2 + 2.5), hash(grid2 + 4.5));
		star_pos2 /= (star_density * 2.5);
		float dist2 = length(uv - star_pos2) * star_density * 2.5;
		float glow2 = smoothstep(0.6, 0.0, dist2) * star_val2 * star_brightness * 0.3;
		col += vec3(0.6, 0.65, 0.8) * glow2;
	}

	COLOR = vec4(col, 1.0);
}
