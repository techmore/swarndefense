shader_type sky;

uniform float star_brightness: hint_range(0.0, 2.0) = 1.2;
uniform vec3 nebula_color1: source_color = vec3(0.12, 0.02, 0.18);
uniform vec3 nebula_color2: source_color = vec3(0.02, 0.04, 0.16);
uniform vec3 nebula_color3: source_color = vec3(0.06, 0.01, 0.10);

vec3 hash33(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, 19.27);
	return fract(vec3(p.x * p.y, p.y * p.z, p.z * p.x));
}

float star_field(vec3 p) {
	vec3 id = floor(p);
	vec3 h = hash33(id);
	float brightness = h.x;
	float size = h.y;
	float star = step(0.998 - size * 0.002, 1.0);
	return star * (0.5 + brightness * 0.5);
}

void fragment() {
	vec3 dir = normalize(EYE_DIR);

	float n1 = sin(dir.x * 1.5 + dir.y * 2.0 + dir.z * 1.0) * 0.5 + 0.5;
	float n2 = cos(dir.x * 0.8 + dir.z * 1.5 + dir.y * 1.2) * 0.5 + 0.5;
	float n3 = sin(dir.x * 0.3 - dir.y * 1.8 + dir.z * 2.5) * 0.5 + 0.5;

	float nebula = n1 * n2 * 0.7 + n3 * 0.3;
	vec3 nebula_col = mix(nebula_color1, nebula_color2, n1);
	nebula_col = mix(nebula_col, nebula_color3, n2);
	nebula_col *= nebula * 0.4;

	float stars = star_field(dir * 180.0);

	vec3 space_base = vec3(0.005, 0.003, 0.01);
	vec3 color = space_base + nebula_col + vec3(stars) * star_brightness;

	ALBEDO = color;
}
