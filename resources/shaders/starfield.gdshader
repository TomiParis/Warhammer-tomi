shader_type canvas_item;

// Fondo galáctico con brazos espirales procedurales
// Vía Láctea vista desde arriba con densidad de estrellas en los brazos

uniform float star_density : hint_range(50.0, 500.0) = 200.0;
uniform float star_brightness : hint_range(0.2, 1.0) = 0.6;
uniform float twinkle_speed : hint_range(0.0, 2.0) = 0.3;
uniform float arm_count : hint_range(2.0, 8.0) = 4.0;
uniform float arm_tightness : hint_range(0.2, 1.5) = 0.55;
uniform float arm_spread : hint_range(0.1, 1.0) = 0.45;
uniform vec4 bg_color : source_color = vec4(0.008, 0.008, 0.025, 1.0);
uniform vec4 arm_color_1 : source_color = vec4(0.12, 0.08, 0.2, 1.0);
uniform vec4 arm_color_2 : source_color = vec4(0.06, 0.1, 0.22, 1.0);
uniform vec4 core_color : source_color = vec4(0.25, 0.18, 0.08, 1.0);

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

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

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise(p);
		p *= 2.1;
		amp *= 0.5;
	}
	return val;
}

// Calcula la densidad de los brazos espirales en un punto
float spiral_density(vec2 uv) {
	// Centro de la galaxia en UV 0.5, 0.5
	vec2 center = uv - vec2(0.5);
	float r = length(center);
	float theta = atan(center.y, center.x);

	// Distancia al brazo espiral más cercano
	// Espiral logarítmica: theta = arm_tightness * ln(r) + offset
	float min_dist = 1.0;
	for (float arm = 0.0; arm < 8.0; arm += 1.0) {
		if (arm >= arm_count) break;
		float arm_offset = arm * (6.28318 / arm_count);
		// Ángulo esperado del brazo a esta distancia radial
		float expected_theta = arm_tightness * log(max(r, 0.001)) * 10.0 + arm_offset;
		// Distancia angular al brazo (wrapeada)
		float diff = theta - expected_theta;
		diff = mod(diff + 3.14159, 6.28318) - 3.14159;
		float arm_dist = abs(diff);
		min_dist = min(min_dist, arm_dist);
	}

	// Convertir distancia a densidad con spread
	float density = smoothstep(arm_spread, 0.0, min_dist);

	// Atenuar en el centro (core galáctico) y en los bordes
	float core_mask = smoothstep(0.0, 0.08, r); // Hueco central mínimo
	float edge_mask = smoothstep(0.5, 0.35, r); // Fade en los bordes
	float core_glow = smoothstep(0.15, 0.0, r); // Brillo del núcleo

	return density * core_mask * edge_mask + core_glow;
}

void fragment() {
	vec2 uv = UV;
	vec3 col = bg_color.rgb;

	// Densidad de los brazos espirales
	float sp = spiral_density(uv);

	// Noise para romper la regularidad de los brazos
	float distortion = fbm(uv * 8.0 + vec2(3.7, 1.2)) * 0.15;
	float sp_noisy = spiral_density(uv + vec2(distortion, -distortion));
	sp = mix(sp, sp_noisy, 0.6);

	// Color de los brazos (mezcla azul/violeta)
	vec3 arm_col = mix(arm_color_1.rgb, arm_color_2.rgb, fbm(uv * 5.0));
	col += arm_col * sp * 0.6;

	// Núcleo galáctico (brillo cálido central)
	vec2 center = uv - vec2(0.5);
	float r = length(center);
	float core = smoothstep(0.12, 0.0, r);
	col += core_color.rgb * core * 0.8;
	// Halo del core
	float halo = smoothstep(0.25, 0.05, r) * 0.15;
	col += vec3(0.2, 0.15, 0.08) * halo;

	// Nebulosas sutiles adicionales en los brazos
	float neb = fbm(uv * 6.0 + vec2(5.5, 2.2));
	col += vec3(0.1, 0.04, 0.12) * neb * sp * 0.3;

	// Disco galáctico general (muy tenue, elíptico)
	float disk = smoothstep(0.5, 0.2, r) * 0.04;
	col += vec3(0.1, 0.1, 0.15) * disk;

	// === ESTRELLAS ===
	// Capa 1: estrellas brillantes (más densas en los brazos)
	vec2 grid = floor(uv * star_density);
	float star_val = hash(grid);
	float star_threshold = mix(0.95, 0.88, sp); // Más estrellas en brazos

	if (star_val > star_threshold) {
		vec2 star_pos = grid + vec2(hash(grid + 0.5), hash(grid + 1.5));
		star_pos /= star_density;
		float dist = length(uv - star_pos) * star_density;
		float brightness = star_val * star_brightness;
		brightness *= 0.8 + 0.2 * sin(TIME * twinkle_speed + star_val * 50.0);
		float glow = smoothstep(0.8, 0.0, dist) * brightness;
		vec3 star_col = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.95, 0.8), hash(grid + 3.0));
		col += star_col * glow;
	}

	// Capa 2: estrellas tenues de fondo
	vec2 grid2 = floor(uv * star_density * 2.5);
	float star_val2 = hash(grid2 + vec2(7.7, 3.3));
	float threshold2 = mix(0.97, 0.93, sp);

	if (star_val2 > threshold2) {
		vec2 star_pos2 = grid2 + vec2(hash(grid2 + 2.5), hash(grid2 + 4.5));
		star_pos2 /= (star_density * 2.5);
		float dist2 = length(uv - star_pos2) * star_density * 2.5;
		float glow2 = smoothstep(0.6, 0.0, dist2) * star_val2 * star_brightness * 0.3;
		col += vec3(0.6, 0.65, 0.8) * glow2;
	}

	COLOR = vec4(col, 1.0);
}
