shader_type spatial;
render_mode cull_front, unshaded, depth_draw_never;

// OATHBOUND Celestial Sky Vortex Shader — Final Touch-Up
// Multi-layer rotating celestial storm vortex with domain warping, procedural magical lightning filaments,
// atmospheric depth stratification, and continuous PowerLevel reactivity.

uniform vec4 sky_dark_color : source_color = vec4(0.05, 0.01, 0.10, 1.0);
uniform vec4 sky_indigo_color : source_color = vec4(0.20, 0.04, 0.38, 1.0);
uniform vec4 cloud_energy_color : source_color = vec4(0.70, 0.35, 1.0, 1.0);
uniform vec4 core_glow_color : source_color = vec4(0.95, 0.90, 1.0, 1.0);

uniform float vortex_speed : hint_range(0.01, 2.0) = 0.08;
uniform float storm_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float lightning_intensity : hint_range(0.0, 3.0) = 0.0;
uniform float cloud_density : hint_range(0.1, 3.0) = 1.0;
uniform float horizon_fade_height : hint_range(-20.0, 20.0) = 1.5;

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
		p *= 2.15;
		amp *= 0.48;
	}
	return val;
}

float lightning_filament(vec2 uv, float speed) {
	float n1 = fbm(uv * 12.0 + vec2(TIME * speed * 2.5, -TIME * speed * 1.8));
	float n2 = fbm(uv * 24.0 - vec2(TIME * speed * 3.2, TIME * speed * 2.1));
	float branch = abs(n1 - n2);
	return smoothstep(0.05, 0.005, branch);
}

void fragment() {
	// Polar vortex coordinates with distance warping
	float dist_from_center = length(v_world_pos.xz);
	float angle = atan(v_world_pos.x, v_world_pos.z);
	
	// Spiral arm rotation (faster near eye of storm)
	float arm_twist = dist_from_center * 0.04;
	vec2 polar_uv = vec2(angle / 6.28318 + 0.5 + arm_twist, dist_from_center * 0.018);
	polar_uv.x += TIME * vortex_speed;
	polar_uv.y += TIME * vortex_speed * 0.25;
	
	// Dual-octave domain warping for dense cloud turbulence
	vec2 warp1 = vec2(fbm(polar_uv * 3.0), fbm(polar_uv * 3.0 + vec2(5.2, 1.3)));
	vec2 warp2 = vec2(fbm(polar_uv * 6.0 + warp1 * 1.5), fbm(polar_uv * 6.0 - warp1 * 1.5));
	
	float clouds1 = fbm((polar_uv + warp2 * 0.4) * 4.0);
	float clouds2 = fbm((polar_uv * 8.0 - vec2(TIME * vortex_speed * 0.6)) + warp1 * 0.3);
	float vortex_pattern = clamp((clouds1 * 0.65 + clouds2 * 0.45) * storm_intensity * cloud_density, 0.0, 1.5);
	
	// Magical lightning filaments flashing across void clouds
	float lightning = 0.0;
	if (lightning_intensity > 0.01) {
		float l1 = lightning_filament(polar_uv, vortex_speed);
		float l2 = lightning_filament(polar_uv * 1.5 + vec2(0.3, 0.7), vortex_speed * 1.3);
		lightning = (l1 + l2 * 0.7) * lightning_intensity;
	}
	
	// Multi-tier color stratification
	vec3 base_sky = mix(sky_dark_color.rgb, sky_indigo_color.rgb, clamp(v_world_pos.y * 0.025, 0.0, 1.0));
	vec3 cloud_layer = mix(base_sky, cloud_energy_color.rgb * 1.8, pow(clamp(vortex_pattern, 0.0, 1.0), 2.2));
	vec3 core_burst = mix(cloud_layer, core_glow_color.rgb * 3.5, pow(clamp(vortex_pattern - 0.6, 0.0, 1.0) * 1.8, 3.0));
	
	// Add lightning flashes
	vec3 final_sky = core_burst + core_glow_color.rgb * lightning * 2.5;
	
	// Horizon fade
	float horizon_alpha = clamp((v_world_pos.y - horizon_fade_height) * 0.09, 0.0, 0.92);
	
	ALBEDO = final_sky;
	ALPHA = horizon_alpha;
}

