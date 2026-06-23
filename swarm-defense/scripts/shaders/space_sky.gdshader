shader_type sky;

uniform float star_density: hint_range(0.0, 2.0) = 1.2;
uniform float galaxy_brightness: hint_range(0.0, 3.0) = 1.5;

vec3 hash33(vec3 p) {
	p = fract(p * vec3(443.897, 397.297, 491.187));
	p += dot(p.zxy, vec3(19.27));
	return fract(vec3(p.x * p.y, p.y * p.z, p.z * p.x));
}

float star_field(vec3 p) {
	vec3 id = floor(p);
	vec3 h = hash33(id);
	float brightness = h.x;
	float size = h.y * h.y;
	float star = step(0.997 - size * 0.003, 1.0);
	float bloom = max(0.0, 1.0 - abs(size - 0.5) * 8.0) * 0.3;
	return star * (0.3 + brightness * 0.7) + bloom * brightness;
}

float milky_way(vec3 dir) {
	float band = abs(dir.y);
	float density = 1.0 - smoothstep(0.0, 0.3, band);
	float core = exp(-abs(dir.x) * 0.15) * 0.8;
	float twist = sin(dir.x * 4.0 + dir.z * 2.0) * 0.05;
	density = max(density, core);
	density *= 1.0 + twist;
	return density * density;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 col = vec3(0.0);

	float mw = milky_way(dir);
	vec3 mw_col = mix(
		vec3(0.15, 0.08, 0.25),
		vec3(0.05, 0.03, 0.12),
		smoothstep(0.0, 0.5, abs(dir.y))
	);
	mw_col += vec3(0.08, 0.04, 0.02) * exp(-abs(dir.x) * 0.3);
	col += mw_col * mw * galaxy_brightness * 0.15;

	float n1 = sin(dir.x * 2.3 + dir.y * 1.7 + dir.z * 1.1) * 0.5 + 0.5;
	float n2 = cos(dir.x * 1.1 + dir.z * 2.3 + dir.y * 1.9) * 0.5 + 0.5;
	float n3 = sin(dir.x * 0.7 - dir.y * 2.5 + dir.z * 3.1 + 1.2) * 0.5 + 0.5;
	float nebula = n1 * n2 * 0.6 + n3 * 0.4;
	nebula *= nebula * nebula;
	vec3 nebula_col = mix(
		vec3(0.08, 0.01, 0.14),
		vec3(0.01, 0.02, 0.10),
		n1
	);
	nebula_col = mix(nebula_col, vec3(0.04, 0.005, 0.08), n2);
	col += nebula_col * nebula * 0.3;

	float stars = star_field(dir * 250.0);
	vec3 id = floor(dir * 250.0);
	vec3 h = hash33(id);
	float temp = h.z;
	vec3 star_color = mix(
		vec3(0.7, 0.8, 1.0),
		vec3(1.0, 0.9, 0.6),
		step(temp, 0.15)
	);
	star_color = mix(star_color, vec3(1.0, 0.7, 0.3), step(temp, 0.05));
	col += star_color * stars * star_density * 0.3;

	col = max(col, vec3(0.001));

	COLOR = col;
}
