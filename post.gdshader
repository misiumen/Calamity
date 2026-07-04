shader_type canvas_item;
// filmic finish: vignette + grain + edge chromatic aberration + shock ripple
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain_amt : hint_range(0.0, 0.2) = 0.05;
uniform float vig_amt : hint_range(0.0, 1.0) = 0.42;
uniform float ca_amt : hint_range(0.0, 4.0) = 1.4;
uniform vec2 shock_c = vec2(0.5, 0.5);
uniform float shock_p = 1.0; // ripple progress, >=1 idle

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	// expanding shock ring bends the image outward
	if (shock_p < 1.0) {
		vec2 sc = uv - shock_c;
		sc.x *= 1.777;
		float sd = length(sc);
		float ring = sd - shock_p * 0.75;
		float w = 0.05;
		if (abs(ring) < w) {
			vec2 dir = normalize(uv - shock_c + vec2(1e-4));
			uv -= dir * sin(ring / w * 3.14159) * 0.016 * (1.0 - shock_p);
		}
	}
	vec2 c = uv - 0.5;
	float d = length(c);
	// chromatic aberration grows toward the edges
	vec2 off = c * d * ca_amt / 640.0;
	float r = texture(screen_tex, uv + off).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - off).b;
	vec3 col = vec3(r, g, b);
	// film grain
	col += (rand(uv * TIME) - 0.5) * grain_amt;
	// vignette
	col *= 1.0 - smoothstep(0.35, 0.85, d) * vig_amt;
	COLOR = vec4(col, 1.0);
}
