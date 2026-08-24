shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, blend_add;

// OATHBOUND Dynamic Plasma Ribbon Shader
// Uses dual-simplex scrolling noise, Fresnel edge emission, and alpha erosion to create ethereal flowing energy.

uniform vec4 core_color : source_color = vec4(0.95, 0.9, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.55, 0.12, 0.95, 1.0);
uniform float speed : hint_range(0.1, 5.0) = 1.4;
uniform float frequency : hint_range(1.0, 20.0) = 6.0;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.2;
uniform float alpha_erosion : hint_range(0.0, 1.0) = 0.2;

// 2D Hash Noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 uv_scroll1 = vec2(UV.x * frequency + TIME * speed * 0.5, UV.y * 2.0 - TIME * speed);
	vec2 uv_scroll2 = vec2(UV.x * frequency * 1.5 - TIME * speed * 0.7, UV.y * 3.0 + TIME * speed * 0.3);
	
	float n1 = noise(uv_scroll1);
	float n2 = noise(uv_scroll2);
	float plasma = (n1 + n2) * 0.5;
	
	// Alpha erosion based on plasma noise & UV borders
	float edge_fade = sin(UV.y * 3.14159);
	float alpha = clamp((plasma - alpha_erosion) / (1.0 - alpha_erosion) * edge_fade, 0.0, 1.0);
	
	// Fresnel rim glow
	float fresnel = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), fresnel_power);
	vec3 final_color = mix(edge_color.rgb * 3.0, core_color.rgb * 6.0, plasma * fresnel);
	
	ALBEDO = vec3(0.0);
	EMISSION = final_color * alpha;
	ALPHA = alpha * edge_color.a;
}
