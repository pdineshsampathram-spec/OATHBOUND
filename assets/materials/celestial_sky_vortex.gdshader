shader_type spatial;
render_mode cull_front, unshaded, depth_draw_never;

// OATHBOUND Celestial Sky Vortex Shader
// Multi-layer rotating storm vortex with distant void filaments, horizon depth fading, and cloud deformation.

uniform vec4 sky_dark_color : source_color = vec4(0.08, 0.02, 0.14, 1.0);
uniform vec4 sky_indigo_color : source_color = vec4(0.24, 0.06, 0.42, 1.0);
uniform vec4 cloud_energy_color : source_color = vec4(0.75, 0.45, 1.0, 1.0);
uniform float vortex_speed : hint_range(0.01, 1.0) = 0.08;
uniform float storm_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float horizon_fade_height : hint_range(-20.0, 20.0) = 2.0;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i + vec2(0.0, 0.0)), hash2(i + vec2(1.0, 0.0)), u.x),
	           mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise2(p);
		p *= 2.1;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	// Polar vortex coordinates
	vec2 polar_uv = vec2(atan(v_world_pos.x, v_world_pos.z) / 6.28318 + 0.5, length(v_world_pos.xz) * 0.015);
	polar_uv.x += TIME * vortex_speed;
	polar_uv.y += TIME * vortex_speed * 0.3;
	
	float clouds1 = fbm(polar_uv * 4.0);
	float clouds2 = fbm(polar_uv * 8.0 - vec2(TIME * vortex_speed * 0.5));
	float vortex_pattern = clamp((clouds1 + clouds2 * 0.5) * storm_intensity, 0.0, 1.0);
	
	// Blend sky layers
	vec3 base_sky = mix(sky_dark_color.rgb, sky_indigo_color.rgb, clamp(v_world_pos.y * 0.02, 0.0, 1.0));
	vec3 final_sky = mix(base_sky, cloud_energy_color.rgb * 2.0, pow(vortex_pattern, 2.5) * 0.7);
	
	// Horizon fade (no hard dome edge)
	float horizon_alpha = clamp((v_world_pos.y - horizon_fade_height) * 0.08, 0.0, 0.85);
	
	ALBEDO = final_sky;
	ALPHA = horizon_alpha;
}
