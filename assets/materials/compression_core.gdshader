shader_type spatial;
render_mode cull_disabled, depth_draw_never, blend_add, unshaded;

// OATHBOUND Compression Core Shader — The Tiny Impossible Core
// Extreme compressed power: all the energy of the Ultimate compacted into a single small point.
// Involuting noise (flowing inward, not outward), core-to-edge color stratification,
// intense emissive pulsing, volumetric heat-haze distortion ring, internal micro-lightning.

uniform vec4 core_white : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 inner_violet : source_color = vec4(0.85, 0.65, 1.0, 1.0);
uniform vec4 outer_deep : source_color = vec4(0.35, 0.05, 0.55, 0.9);
uniform vec4 void_black : source_color = vec4(0.02, 0.0, 0.05, 1.0);

uniform float compression_progress : hint_range(0.0, 1.0) = 0.0;
uniform float core_intensity : hint_range(1.0, 30.0) = 12.0;
uniform float involution_speed : hint_range(1.0, 20.0) = 8.0;
uniform float pulse_frequency : hint_range(0.5, 8.0) = 3.0;
uniform float micro_lightning_density : hint_range(0.0, 2.0) = 1.0;
uniform float haze_ring_radius : hint_range(0.5, 3.0) = 1.2;
uniform int quality_level : hint_range(0, 3) = 3;

varying vec3 v_local_pos;

float hash3D(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}

float noise3D(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash3D(i + vec3(0,0,0)), hash3D(i + vec3(1,0,0)), u.x),
		    mix(hash3D(i + vec3(0,1,0)), hash3D(i + vec3(1,1,0)), u.x), u.y),
		mix(mix(hash3D(i + vec3(0,0,1)), hash3D(i + vec3(1,0,1)), u.x),
		    mix(hash3D(i + vec3(0,1,1)), hash3D(i + vec3(1,1,1)), u.x), u.y), u.z
	);
}

float fbm_involute(vec3 p) {
	int octaves = 1 + quality_level;
	float val = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 4; i++) {
		if (i >= octaves) break;
		// INWARD flow: noise coordinates converge toward center
		vec3 inward_p = p * freq - normalize(p) * TIME * involution_speed * (0.5 + float(i) * 0.3);
		val += amp * noise3D(inward_p);
		freq *= 2.3;
		amp *= 0.42;
	}
	return val;
}

void vertex() {
	v_local_pos = VERTEX;
	
	// Compression-driven vertex implosion: vertices pull toward center as compression increases
	float pull_strength = compression_progress * 0.15;
	vec3 toward_center = -normalize(VERTEX + vec3(0.001));
	VERTEX += toward_center * pull_strength * length(VERTEX);
}

void fragment() {
	float dist_from_core = length(v_local_pos);
	float normalized_dist = clamp(dist_from_core / 0.5, 0.0, 1.0);
	
	// Involuting noise — turbulence flowing inward (the key visual signature)
	vec3 noise_pos = v_local_pos * 6.0;
	float involute = fbm_involute(noise_pos);
	
	// Compression pulse: intensity oscillates faster as compression increases
	float pulse = sin(TIME * pulse_frequency * (1.0 + compression_progress * 4.0)) * 0.5 + 0.5;
	float compression_boost = 1.0 + compression_progress * (core_intensity * 0.5) + pulse * compression_progress * 3.0;
	
	// Core-to-edge color stratification
	// Center: blinding white → inner: bright violet → outer: deep violet → edge: void black
	vec3 c_white = core_white.rgb * core_intensity * compression_boost;
	vec3 c_inner = inner_violet.rgb * core_intensity * 0.6 * compression_boost;
	vec3 c_outer = outer_deep.rgb * 2.0;
	vec3 c_void = void_black.rgb;
	
	float zone1 = smoothstep(0.0, 0.2, normalized_dist);   // White → inner violet
	float zone2 = smoothstep(0.2, 0.5, normalized_dist);   // Inner violet → deep violet
	float zone3 = smoothstep(0.5, 0.85, normalized_dist);  // Deep violet → void
	
	vec3 stratified = mix(c_white, c_inner, zone1);
	stratified = mix(stratified, c_outer, zone2);
	stratified = mix(stratified, c_void, zone3);
	
	// Internal turbulence modulation
	stratified *= (0.7 + involute * 0.6);
	
	// Micro-lightning veins — thin bright filaments through the core
	float micro_lightning = 0.0;
	if (quality_level >= 2 && micro_lightning_density > 0.01) {
		vec3 ml_pos = v_local_pos * 16.0 + vec3(TIME * involution_speed * 0.5, -TIME * involution_speed, TIME * 0.3);
		float ml_n = noise3D(ml_pos);
		micro_lightning = smoothstep(0.47, 0.50, ml_n) * micro_lightning_density * 5.0 * compression_boost;
	}
	
	// Volumetric heat-haze distortion ring — bright ring at the edge of the core
	float haze_ring = exp(-pow((normalized_dist - 0.7) * 4.0, 2.0)) * compression_progress;
	
	// Final color assembly
	vec3 final_color = stratified + core_white.rgb * micro_lightning + inner_violet.rgb * haze_ring * 3.0;
	
	// Alpha: solid at center, fading at edges, with haze ring contribution
	float alpha_core = 1.0 - smoothstep(0.0, 0.9, normalized_dist);
	float alpha_haze = haze_ring * 0.4;
	float final_alpha = clamp(alpha_core + alpha_haze, 0.0, 1.0) * (0.5 + compression_progress * 0.5);
	
	ALBEDO = vec3(0.0);
	EMISSION = final_color * final_alpha;
	ALPHA = final_alpha;
}
