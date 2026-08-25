shader_type spatial;
render_mode cull_disabled, depth_draw_never, blend_add, unshaded;

// OATHBOUND Sky Bloom Eruption Shader — Upper Atmosphere Expansion
// Massive irregular spreading canopy after the vertical eruption.
// Multi-octave domain-warped cloud turbulence with internal white-violet glow veins,
// dark-violet exterior, and lightning filaments arcing through the bloom volume.
// This shader reinforces the primary sky deformation driven by celestial_sky_vortex.gdshader.

uniform vec4 bloom_core_color : source_color = vec4(0.92, 0.85, 1.0, 1.0);
uniform vec4 bloom_energy_color : source_color = vec4(0.68, 0.32, 0.98, 1.0);
uniform vec4 bloom_dark_exterior : source_color = vec4(0.12, 0.02, 0.22, 0.7);
uniform vec4 lightning_color : source_color = vec4(0.95, 0.90, 1.0, 1.0);

uniform float bloom_progress : hint_range(0.0, 1.0) = 0.0;
uniform float turbulence_speed : hint_range(0.5, 8.0) = 3.0;
uniform float cloud_scale : hint_range(0.5, 5.0) = 1.6;
uniform float glow_vein_intensity : hint_range(0.0, 8.0) = 4.0;
uniform float lightning_arc_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float dissipation_rate : hint_range(0.0, 2.0) = 0.6;
uniform int quality_level : hint_range(0, 3) = 3;

varying vec3 v_world_pos;
varying float v_height_norm;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i + vec2(0.0, 0.0)), hash2(i + vec2(1.0, 0.0)), u.x),
	           mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm_quality(vec2 p) {
	int octaves = 1 + quality_level;
	float val = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 4; i++) {
		if (i >= octaves) break;
		val += amp * noise2(p * freq);
		freq *= 2.15;
		amp *= 0.47;
	}
	return val;
}

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
	v_height_norm = clamp(v_world_pos.y / 80.0, 0.0, 1.0);
	
	// Turbulent vertex displacement for organic non-uniform silhouette
	vec3 disp_p = VERTEX * cloud_scale * 0.3 + vec3(TIME * turbulence_speed * 0.1, -TIME * 0.2, TIME * 0.15);
	float disp_n = (noise3D(disp_p) - 0.5) * 2.0;
	VERTEX += NORMAL * disp_n * 2.0 * bloom_progress;
}

void fragment() {
	// Radial distance from eruption center (XZ plane)
	float radial_dist = length(v_world_pos.xz);
	float normalized_radial = radial_dist / max(60.0 * bloom_progress, 0.1);
	
	// Domain-warped cloud turbulence
	vec2 uv = v_world_pos.xz * cloud_scale * 0.02;
	vec2 warp1 = vec2(
		fbm_quality(uv * 3.0 + vec2(TIME * turbulence_speed * 0.1, 0.0)),
		fbm_quality(uv * 3.0 + vec2(5.2, 1.3) + vec2(0.0, TIME * turbulence_speed * 0.08))
	);
	vec2 warped_uv = uv + warp1 * 0.5;
	float cloud_density = fbm_quality(warped_uv * 5.0);
	
	// Internal glow veins — bright energy channels through the bloom
	float glow_vein = 0.0;
	if (quality_level >= 1) {
		float vein_n = fbm_quality(warped_uv * 12.0 + vec2(TIME * turbulence_speed * 0.3, -TIME * 0.2));
		glow_vein = smoothstep(0.45, 0.55, vein_n) * glow_vein_intensity;
	}
	
	// Lightning arcs through the bloom volume
	float lightning = 0.0;
	if (quality_level >= 2 && lightning_arc_intensity > 0.01) {
		float l1 = fbm_quality(warped_uv * 18.0 + vec2(TIME * turbulence_speed * 2.0, -TIME * 1.5));
		float l2 = fbm_quality(warped_uv * 24.0 - vec2(TIME * turbulence_speed * 2.5, TIME * 1.8));
		float branch = abs(l1 - l2);
		lightning = smoothstep(0.04, 0.005, branch) * lightning_arc_intensity;
	}
	
	// Color assembly:
	// Interior: bright white-violet glow veins
	// Mid: energy-saturated violet cloud
	// Exterior: dark-violet dissipating edge
	vec3 exterior = bloom_dark_exterior.rgb;
	vec3 cloud_body = mix(exterior, bloom_energy_color.rgb * 2.0, pow(cloud_density, 1.5));
	vec3 glow_interior = bloom_core_color.rgb * glow_vein_intensity * glow_vein;
	vec3 lightning_flash = lightning_color.rgb * lightning * 4.0;
	
	vec3 final_color = cloud_body + glow_interior + lightning_flash;
	
	// Radial edge fadeout — bloom dissipates at expanding boundary
	float edge_fade = 1.0 - smoothstep(0.6, 1.0, normalized_radial);
	
	// Vertical fade — stronger at base (where eruption feeds in), fainter at top
	float vertical_fade = smoothstep(0.0, 0.2, v_height_norm);
	
	// Dissipation over time — bloom slowly fades as progress reaches 1.0
	float dissipation = 1.0 - pow(bloom_progress, 1.0 + dissipation_rate);
	
	// Alpha
	float alpha_cloud = clamp(cloud_density * 0.7 + glow_vein * 0.2, 0.0, 1.0);
	float final_alpha = alpha_cloud * edge_fade * vertical_fade * bloom_dark_exterior.a * (0.4 + bloom_progress * 0.6) * dissipation;
	
	ALBEDO = vec3(0.0);
	EMISSION = final_color * clamp(final_alpha, 0.0, 1.0);
	ALPHA = clamp(final_alpha, 0.0, 0.9);
}
