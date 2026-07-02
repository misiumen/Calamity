shader_type canvas_item;
// filmic finish: vignette + grain + edge chromatic aberration
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain_amt : hint_range(0.0, 0.2) = 0.05;
uniform float vig_amt : hint_range(0.0, 1.0) = 0.42;
uniform float ca_amt : hint_range(0.0, 4.0) = 1.4;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
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
