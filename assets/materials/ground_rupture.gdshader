shader_type spatial;
render_mode cull_back, depth_draw_opaque, blend_mix;

// OATHBOUND Ground Rupture Shader — Radial Fracture Effect
// Renders expanding radial cracks with emissive energy glow from within,
// procedural edge burning along fracture lines, and progressive reveal.
// Vertex colors encode: R = crack depth, G = energy intensity, B = crack age.

uniform vec4 crack_glow_color : source_color = vec4(0.75, 0.35, 1.0, 1.0);
uniform vec4 burn_edge_color : source_color = vec4(1.0, 0.5, 0.15, 1.0);
uniform vec4 stone_color : source_color = vec4(0.15, 0.12, 0.10, 1.0);
uniform vec4 scorched_color : source_color = vec4(0.05, 0.02, 0.02, 1.0);

uniform float rupture_progress : hint_range(0.0, 1.0) = 0.0;
uniform float glow_intensity : hint_range(0.5, 12.0) = 5.0;
uniform float burn_width : hint_range(0.01, 0.3) = 0.08;
uniform float crack_depth_scale : hint_range(0.1, 2.0) = 0.5;
uniform int quality_level : hint_range(0, 3) = 3;

varying vec3 v_world_pos;
varying vec4 v_vertex_color;

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

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_vertex_color = COLOR;
	
	// Displace crack vertices downward based on crack depth channel
	float crack_depth = v_vertex_color.r;
	float reveal = smoothstep(0.0, 1.0, rupture_progress);
	VERTEX.y -= crack_depth * crack_depth_scale * reveal;
}

void fragment() {
	float crack_depth = v_vertex_color.r;
	float energy_intensity = v_vertex_color.g;
	float crack_age = v_vertex_color.b;
	
	// Progressive reveal: cracks propagate outward based on rupture_progress and crack_age
	float reveal_threshold = rupture_progress * 1.2;  // Slight overshoot for smooth rolloff
	float crack_visible = smoothstep(crack_age - 0.1, crack_age, reveal_threshold);
	
	// Edge burn along fracture lines
	float burn_zone = smoothstep(0.0, burn_width, crack_depth) * (1.0 - smoothstep(burn_width, burn_width * 2.0, crack_depth));
	
	// Internal glow from within cracks
	float inner_glow = crack_depth * energy_intensity * glow_intensity * crack_visible;
	
	// Noise-driven surface variation
	float surface_noise = noise2(v_world_pos.xz * 4.0);
	
	// Color assembly
	vec3 base = mix(stone_color.rgb, scorched_color.rgb, crack_visible * 0.6);
	
	// Add surface detail noise
	base *= (0.8 + surface_noise * 0.4);
	
	// Emissive crack glow
	vec3 glow = crack_glow_color.rgb * inner_glow;
	
	// Edge burn (hot orange at fracture boundaries)
	vec3 burn = burn_edge_color.rgb * burn_zone * crack_visible * 3.0;
	
	// Fresnel for volumetric crack depth perception
	float fresnel = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 3.0);
	
	ALBEDO = base;
	EMISSION = (glow + burn) * (1.0 + fresnel * 0.3);
	ALPHA = 1.0;  // Opaque ground — cracks don't make ground transparent
	ROUGHNESS = mix(0.85, 0.3, crack_visible * energy_intensity);  // Cracks are shinier from energy
	METALLIC = crack_visible * energy_intensity * 0.2;
}
