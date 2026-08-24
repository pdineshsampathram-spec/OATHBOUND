shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, blend_mix;

// OATHBOUND Living Plasma Energy Column Shader
// Renders a dense, supernatural atmospheric energy phenomenon from 0m to 65m+.
// Semi-transparent dark plasma body, turbulent vertex roil, internal white-violet filaments,
// and soft atmospheric dissipation without creating an opaque blocking cylinder.

uniform vec4 core_color : source_color = vec4(0.96, 0.92, 1.0, 1.0);
uniform vec4 plasma_mid_color : source_color = vec4(0.58, 0.15, 0.95, 1.0);
uniform vec4 plasma_deep_color : source_color = vec4(0.18, 0.03, 0.32, 0.85);

uniform float flow_speed : hint_range(0.5, 15.0) = 4.8;
uniform float turbulence_scale : hint_range(0.1, 10.0) = 2.4;
uniform float vertex_displacement_amount : hint_range(0.0, 1.5) = 0.35;
uniform float core_glow_intensity : hint_range(1.0, 15.0) = 5.0;
uniform float column_opacity : hint_range(0.0, 1.0) = 0.72;
uniform float lightning_pulse : hint_range(0.0, 2.0) = 0.0;
uniform float vertical_dissipation_power : hint_range(0.1, 4.0) = 1.2;

varying vec3 v_world_pos;
varying float v_height_norm;

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

float fbm3D(vec3 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		val += amp * noise3D(p);
		p *= 2.2;
		amp *= 0.48;
	}
	return val;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_height_norm = clamp(v_world_pos.y / 65.0, 0.0, 1.0);
	
	// Living plasma vertex roil & displacement wave
	vec3 p_disp = v_world_pos * (turbulence_scale * 0.5) + vec3(0.0, -TIME * (flow_speed * 0.8), 0.0);
	float n_disp = (fbm3D(p_disp) - 0.5) * 2.0;
	
	// Displace along normal, scaling with height
	VERTEX += NORMAL * (n_disp * vertex_displacement_amount * (0.4 + v_height_norm * 0.6));
}

void fragment() {
	// Multi-speed vertical plasma scroll
	vec3 p1 = v_world_pos * turbulence_scale + vec3(0.0, -TIME * flow_speed, 0.0);
	vec3 p2 = v_world_pos * (turbulence_scale * 1.8) + vec3(TIME * 0.4, -TIME * (flow_speed * 1.5), -TIME * 0.4);
	
	float n1 = fbm3D(p1);
	float n2 = fbm3D(p2);
	float plasma_density = (n1 * 0.6 + n2 * 0.4);
	
	// Distance from vertical center axis for radial density
	float dist_from_center = length(v_world_pos.xz);
	float radial_core = exp(-dist_from_center * (1.2 / (0.6 + v_height_norm * 2.0)));
	
	// Internal lightning veins
	float lightning_vein = smoothstep(0.48, 0.52, n2) * (1.0 + lightning_pulse * 2.0);
	
	// Multi-tiered color stratification (Dark deep body -> vibrant violet -> bright white-violet core)
	vec3 base_color = mix(plasma_deep_color.rgb, plasma_mid_color.rgb * 1.8, pow(plasma_density, 1.8));
	vec3 core_glow = mix(base_color, core_color.rgb * core_glow_intensity, pow(radial_core, 2.2));
	vec3 final_color = core_glow + (core_color.rgb * lightning_vein * 3.0);
	
	// Fresnel rim to preserve volumetric depth without opaque blocking
	float fresnel = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 2.0);
	float alpha_body = mix(0.25, 0.85, plasma_density * radial_core);
	
	// Taper at very base (near character) to preserve Knight silhouette readability
	float base_readability_taper = smoothstep(0.0, 2.5, v_world_pos.y);
	float final_alpha = clamp(alpha_body * column_opacity * (0.35 + base_readability_taper * 0.65), 0.0, 0.90);
	
	ALBEDO = base_color * 0.2;
	EMISSION = final_color * (0.8 + fresnel * 0.4);
	ALPHA = final_alpha;
}
