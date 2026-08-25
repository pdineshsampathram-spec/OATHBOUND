shader_type spatial;
render_mode cull_disabled, depth_draw_never, blend_add, unshaded;

// OATHBOUND Cinematic Atmosphere Shader — Localized Energy Haze
// Applied to large invisible spheres around the Knight for atmospheric presence.
// Heat-haze distortion, volumetric energy fog with directional bias:
//   - Pulled TOWARD Knight during compression phases
//   - Pushed OUTWARD during the release
// Dust particle density field for ambient presence.

uniform vec4 haze_color : source_color = vec4(0.55, 0.18, 0.82, 0.3);
uniform vec4 energy_fog_color : source_color = vec4(0.68, 0.35, 0.95, 0.2);
uniform vec4 dust_tint : source_color = vec4(0.8, 0.7, 0.6, 0.15);

uniform float atmosphere_intensity : hint_range(0.0, 2.0) = 0.0;
uniform float distortion_strength : hint_range(0.0, 3.0) = 0.5;
uniform float fog_density : hint_range(0.0, 2.0) = 0.5;
uniform float directional_bias : hint_range(-1.0, 1.0) = 0.0;  // -1 = inward (compression), +1 = outward (release)
uniform float dust_density : hint_range(0.0, 2.0) = 0.3;
uniform float power_level : hint_range(0.0, 1.0) = 0.0;
uniform int quality_level : hint_range(0, 3) = 3;

varying vec3 v_world_pos;
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

float fbm_quality(vec3 p) {
	int octaves = max(1, quality_level);
	float val = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 3; i++) {
		if (i >= octaves) break;
		val += amp * noise3D(p * freq);
		freq *= 2.0;
		amp *= 0.5;
	}
	return val;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_local_pos = VERTEX;
}

void fragment() {
	if (atmosphere_intensity < 0.01) {
		discard;
	}
	
	float dist_from_center = length(v_world_pos.xz);
	float height = v_world_pos.y;
	
	// Directional flow: bias noise coordinates inward or outward
	vec3 flow_dir = normalize(vec3(v_world_pos.x, 0.0, v_world_pos.z) + vec3(0.001));
	vec3 flow_offset = flow_dir * directional_bias * TIME * 2.0;
	
	// Volumetric energy fog
	vec3 fog_pos = v_world_pos * 0.3 + flow_offset + vec3(0.0, TIME * 0.5, 0.0);
	float fog_n = fbm_quality(fog_pos);
	float fog_factor = fog_n * fog_density * atmosphere_intensity;
	
	// Radial density falloff — denser near Knight, thinner at edges
	float radial_falloff = exp(-dist_from_center * 0.08);
	fog_factor *= radial_falloff;
	
	// Height stratification — most dense at ground level, some rising
	float height_factor = exp(-max(height, 0.0) * 0.1) * 0.7 + 0.3;
	fog_factor *= height_factor;
	
	// Dust particle density field — small bright flecks
	float dust = 0.0;
	if (quality_level >= 1 && dust_density > 0.01) {
		vec3 dust_pos = v_world_pos * 2.0 + flow_offset * 0.5 + vec3(TIME * 0.3, -TIME * 0.8, TIME * 0.2);
		float dust_n = noise3D(dust_pos * 8.0);
		dust = smoothstep(0.6, 0.65, dust_n) * dust_density * atmosphere_intensity;
	}
	
	// Heat-haze distortion hint — visual modulation for the fragment
	float haze = 0.0;
	if (quality_level >= 2 && distortion_strength > 0.01) {
		vec3 haze_pos = v_world_pos * 1.5 + vec3(0.0, TIME * 1.5, 0.0);
		haze = (noise3D(haze_pos) - 0.5) * distortion_strength * atmosphere_intensity;
	}
	
	// Color assembly
	vec3 fog_col = energy_fog_color.rgb * (1.5 + power_level * 2.0);
	vec3 haze_col = haze_color.rgb * (1.0 + abs(haze) * 2.0);
	vec3 dust_col = dust_tint.rgb * 3.0;
	
	vec3 final_color = fog_col * fog_factor + haze_col * abs(haze) + dust_col * dust;
	
	// Alpha
	float final_alpha = clamp(fog_factor * 0.5 + abs(haze) * 0.2 + dust * 0.6, 0.0, 0.6) * atmosphere_intensity;
	
	ALBEDO = vec3(0.0);
	EMISSION = final_color;
	ALPHA = final_alpha;
}
