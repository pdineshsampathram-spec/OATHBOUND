shader_type spatial;
render_mode cull_disabled, depth_draw_never, blend_add, unshaded;

// OATHBOUND Radial Detonation Shader — Catastrophic Release VFX
// Multi-layer expanding hemispherical blast wave with:
// - 4-octave FBM noise driving internal density (ULTRA), scalable via quality_level
// - Fresnel-driven bright leading edge (white-violet core glow)
// - Interior lightning filaments via high-frequency noise thresholding
// - Distance-based alpha fadeout (blast dissipates as it expands)
// - Ground-scorching darkening at low Y values
// - Vertex displacement for organic expanding silhouette

uniform vec4 core_color : source_color = vec4(0.98, 0.95, 1.0, 1.0);
uniform vec4 blast_color : source_color = vec4(0.72, 0.28, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.55, 0.12, 0.95, 0.8);
uniform vec4 ground_scorch_color : source_color = vec4(0.4, 0.08, 0.12, 1.0);

uniform float expansion_progress : hint_range(0.0, 1.0) = 0.0;
uniform float blast_intensity : hint_range(0.5, 20.0) = 8.0;
uniform float turbulence_scale : hint_range(0.5, 8.0) = 2.8;
uniform float flow_speed : hint_range(0.5, 12.0) = 6.0;
uniform float vertex_displacement : hint_range(0.0, 3.0) = 0.8;
uniform float lightning_threshold : hint_range(0.3, 0.7) = 0.48;
uniform int quality_level : hint_range(0, 3) = 3;  // 0=LOW, 1=MEDIUM, 2=HIGH, 3=ULTRA

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

// Quality-adaptive FBM: ULTRA=4 octaves, HIGH=3, MEDIUM=2, LOW=1
float fbm_quality(vec3 p) {
	int octaves = 1 + quality_level;
	float val = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 4; i++) {
		if (i >= octaves) break;
		val += amp * noise3D(p * freq);
		freq *= 2.1;
		amp *= 0.46;
	}
	return val;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_height_norm = clamp(v_world_pos.y / 40.0, -0.5, 1.0);
	
	// Organic vertex displacement — blast wave isn't a perfect sphere
	vec3 disp_pos = VERTEX * turbulence_scale * 0.4 + vec3(0.0, -TIME * flow_speed * 0.3, 0.0);
	float disp_noise = (fbm_quality(disp_pos) - 0.5) * 2.0;
	
	// Displacement strongest at the leading edge of expansion
	float edge_strength = smoothstep(0.6, 0.9, expansion_progress) * (1.0 - expansion_progress);
	VERTEX += NORMAL * disp_noise * vertex_displacement * (0.3 + edge_strength * 0.7);
}

void fragment() {
	// Radial distance from blast center
	float dist_from_center = length(v_world_pos.xz);
	float normalized_dist = dist_from_center / max(40.0 * expansion_progress, 0.1);
	
	// Leading edge glow — the brightest part of the blast
	float leading_edge = smoothstep(0.7, 1.0, normalized_dist) * smoothstep(1.3, 1.0, normalized_dist);
	
	// Internal turbulent density — the body of the blast
	vec3 noise_pos = v_world_pos * turbulence_scale + vec3(0.0, -TIME * flow_speed, TIME * flow_speed * 0.3);
	float density = fbm_quality(noise_pos);
	
	// Interior lightning filaments (high-frequency noise thresholding)
	float lightning = 0.0;
	if (quality_level >= 2) {
		vec3 lightning_pos = v_world_pos * turbulence_scale * 4.0 + vec3(TIME * flow_speed * 2.0, 0.0, -TIME * flow_speed * 1.5);
		float ln = fbm_quality(lightning_pos);
		lightning = smoothstep(lightning_threshold, lightning_threshold + 0.04, ln) * 3.0;
	}
	
	// Fresnel rim — bright edge where blast meets atmosphere
	float fresnel = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 2.5);
	
	// Color stratification: white-violet core → deep violet edge → dark dissipation
	vec3 body_color = mix(blast_color.rgb * 2.0, core_color.rgb * blast_intensity, pow(density, 1.6));
	vec3 edge_glow = mix(body_color, core_color.rgb * blast_intensity * 1.5, leading_edge);
	vec3 final_color = edge_glow + core_color.rgb * lightning + core_color.rgb * fresnel * 2.0;
	
	// Ground scorching — darken and warm color near ground
	float ground_factor = smoothstep(2.0, -0.5, v_world_pos.y);
	final_color = mix(final_color, ground_scorch_color.rgb * 2.0, ground_factor * 0.3);
	
	// Alpha: dense at leading edge, fading behind and at distance
	float alpha_density = clamp(density * 0.8 + leading_edge * 0.6, 0.0, 1.0);
	float alpha_distance_fade = 1.0 - smoothstep(0.0, 1.0, expansion_progress);  // Fade as blast expands
	float alpha_edge_fade = 1.0 - smoothstep(0.85, 1.2, normalized_dist);  // Fade at blast boundary
	float final_alpha = alpha_density * (0.3 + alpha_distance_fade * 0.7) * alpha_edge_fade * edge_color.a;
	
	ALBEDO = vec3(0.0);
	EMISSION = final_color * clamp(final_alpha, 0.0, 1.0);
	ALPHA = clamp(final_alpha, 0.0, 0.95);
}
