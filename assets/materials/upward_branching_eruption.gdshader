shader_type spatial;
render_mode cull_disabled, depth_draw_never, blend_add, unshaded;

// OATHBOUND Upward Branching Eruption Shader — Catastrophic Release Eruption
// Violent branching plasma lightning tearing from ground to heavens:
// - Blinding white-violet core with vivid void violet sheath
// - Ultra-fast upward flow velocity
// - High-frequency lightning jaggedness and vertex pulse
// - Rapid dissipation for short-lived event lifecycle

uniform vec4 core_color : source_color = vec4(0.98, 0.96, 1.0, 1.0);
uniform vec4 sheath_color : source_color = vec4(0.55, 0.15, 0.98, 1.0);
uniform vec4 edge_color : source_color = vec4(0.20, 0.03, 0.40, 0.8);

uniform float eruption_intensity : hint_range(0.0, 20.0) = 10.0;
uniform float upward_speed : hint_range(5.0, 40.0) = 22.0;
uniform float turbulence_scale : hint_range(0.5, 6.0) = 2.5;
uniform float dissipation : hint_range(0.0, 1.0) = 0.0;
uniform int quality_level : hint_range(0, 3) = 2;

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

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// High-frequency lightning jaggedness along trunk and branches
	float jag = noise3D(v_world_pos * 0.4 + vec3(0.0, -TIME * 15.0, 0.0));
	VERTEX += NORMAL * (jag * 0.35 * (1.0 - dissipation));
}

void fragment() {
	vec3 uv_pos = v_world_pos * turbulence_scale * 0.1;
	uv_pos.y -= TIME * upward_speed * 0.05;
	
	float n1 = noise3D(uv_pos);
	float n2 = noise3D(uv_pos * 2.5 + vec3(TIME * 2.0, 0.0, TIME * 1.5));
	float combined = mix(n1, n2, 0.4);
	
	// Height gradient: bright core at bottom, branching forks hotter at tips
	float height_norm = clamp(v_world_pos.y / 65.0, 0.0, 1.0);
	
	// Core vs Sheath
	float core_weight = smoothstep(0.4, 0.85, combined) * (1.0 - height_norm * 0.3);
	
	vec3 col = mix(edge_color.rgb, sheath_color.rgb, combined);
	col = mix(col, core_color.rgb, core_weight);
	
	float alpha = clamp(combined * 1.2, 0.0, 1.0) * (1.0 - dissipation);
	
	ALBEDO = col;
	EMISSION = col * (eruption_intensity * (1.0 - dissipation * 0.9));
	ALPHA = alpha;
}
