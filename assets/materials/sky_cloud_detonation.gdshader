shader_type spatial;
render_mode cull_disabled, depth_draw_never, blend_add, unshaded;

// OATHBOUND Sky Cloud Detonation Shader — Massive Celestial Canopy Burst
// Simulates an irregular, billowing upper-atmosphere cloud explosion:
// - Dark void-indigo billowing outer cloud deck
// - Intense white-violet internal core detonation
// - High-frequency lightning arcs and atmospheric distortion
// - Radial shockwave propagation and edge dissipation

uniform vec4 core_color : source_color = vec4(0.98, 0.95, 1.0, 1.0);
uniform vec4 mid_color : source_color = vec4(0.68, 0.25, 0.98, 1.0);
uniform vec4 outer_cloud_color : source_color = vec4(0.12, 0.02, 0.25, 0.9);
uniform vec4 lightning_color : source_color = vec4(0.95, 0.90, 1.0, 1.0);

uniform float detonation_progress : hint_range(0.0, 1.0) = 0.0;
uniform float blast_energy : hint_range(0.0, 15.0) = 8.0;
uniform float cloud_billow_scale : hint_range(0.5, 8.0) = 2.2;
uniform float lightning_activity : hint_range(0.0, 3.0) = 1.5;
uniform float dissipation : hint_range(0.0, 1.0) = 0.0;
uniform int quality_level : hint_range(0, 3) = 2; // 0=LOW, 1=MEDIUM, 2=HIGH, 3=ULTRA

varying vec3 v_world_pos;
varying vec3 v_normal;

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

float fbm(vec3 p, int octaves) {
	float val = 0.0;
	float amp = 0.5;
	vec3 shift = vec3(100.0);
	for (int i = 0; i < octaves; i++) {
		val += amp * noise3D(p);
		p = p * 2.0 + shift;
		amp *= 0.5;
	}
	return val;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// Dynamic billowing vertex expansion based on noise
	float disp_noise = noise3D(v_world_pos * 0.08 + vec3(0.0, TIME * 0.4, 0.0));
	VERTEX += NORMAL * (disp_noise * 1.8 * (1.0 - dissipation));
}

void fragment() {
	int octaves = 3;
	if (quality_level == 3) octaves = 4;
	else if (quality_level == 1) octaves = 2;
	else if (quality_level == 0) octaves = 1;
	
	vec3 sample_pos = v_world_pos * cloud_billow_scale * 0.04;
	sample_pos.y += TIME * 0.15;
	
	float cloud_noise = fbm(sample_pos, octaves);
	float detail_noise = noise3D(sample_pos * 3.5 + vec3(TIME * 0.5, 0.0, TIME * 0.3));
	
	// Radial distance from canopy center (assumed near x=0, z=0)
	float radial_dist = length(v_world_pos.xz);
	float norm_radial = clamp(radial_dist / 60.0, 0.0, 1.0);
	
	// Expanding shock front ring
	float front_pos = detonation_progress * 1.1;
	float front_mask = smoothstep(0.2, 0.0, abs(norm_radial - front_pos));
	
	// Core vs outer cloud blend
	float core_weight = smoothstep(0.7, 0.0, norm_radial) * (1.0 - detonation_progress * 0.6);
	
	// Lightning filaments
	float lightning_mask = 0.0;
	if (lightning_activity > 0.1 && quality_level >= 1) {
		float l_noise = noise3D(sample_pos * 8.0 + vec3(0.0, TIME * 4.0, 0.0));
		lightning_mask = step(0.68, l_noise) * lightning_activity * (1.0 - dissipation);
	}
	
	// Color stratification
	vec3 col = mix(outer_cloud_color.rgb, mid_color.rgb, cloud_noise);
	col = mix(col, core_color.rgb, core_weight * 0.8 + front_mask * 0.6);
	col += lightning_color.rgb * lightning_mask * 2.0;
	
	// Emission & intensity
	float alpha = (cloud_noise * 0.7 + core_weight * 0.5 + front_mask * 0.5) * (1.0 - dissipation);
	alpha = clamp(alpha, 0.0, 1.0);
	
	ALBEDO = col;
	EMISSION = col * (blast_energy * (1.0 - dissipation * 0.8) + lightning_mask * 4.0);
	ALPHA = alpha * (1.0 - dissipation);
}
