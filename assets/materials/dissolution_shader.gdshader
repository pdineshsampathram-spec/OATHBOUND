shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// OATHBOUND 8-Stage Vaporization & Dissolution Shader
// Supports internal energy glow, surface fracture veins, procedural 3D noise discard, and glowing emissive burn borders.

uniform vec4 albedo_color : source_color = vec4(0.8, 0.8, 0.85, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, hint_default_white;
uniform float roughness : hint_range(0.0, 1.0) = 0.4;
uniform float metallic : hint_range(0.0, 1.0) = 0.6;

// Stage 2: Internal Energy Glow
uniform float internal_glow : hint_range(0.0, 5.0) = 0.0;
uniform vec4 internal_glow_color : source_color = vec4(0.55, 0.15, 1.0, 1.0);

// Stage 3: Surface Fracture Veins
uniform float fracture_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fracture_color : source_color = vec4(0.9, 0.7, 1.0, 1.0);

// Stage 4-7: 3D Noise Dissolve & Disintegration
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(0.85, 0.45, 1.0, 1.0);
uniform vec4 burn_core_color : source_color = vec4(1.0, 0.95, 1.0, 1.0);
uniform float burn_width : hint_range(0.0, 0.3) = 0.08;
uniform float noise_scale : hint_range(1.0, 50.0) = 14.0;

// Procedural 3D hash noise
vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
	         dot(p, vec3(269.5, 183.3, 246.1)),
	         dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453123);
}

float noise3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(mix(dot(hash3(i + vec3(0.0,0.0,0.0)), f - vec3(0.0,0.0,0.0)),
	                   dot(hash3(i + vec3(1.0,0.0,0.0)), f - vec3(1.0,0.0,0.0)), u.x),
	               mix(dot(hash3(i + vec3(0.0,1.0,0.0)), f - vec3(0.0,1.0,0.0)),
	                   dot(hash3(i + vec3(1.0,1.0,0.0)), f - vec3(1.0,1.0,0.0)), u.x), u.y),
	           mix(mix(dot(hash3(i + vec3(0.0,0.0,1.0)), f - vec3(0.0,0.0,1.0)),
	                   dot(hash3(i + vec3(1.0,0.0,1.0)), f - vec3(1.0,0.0,1.0)), u.x),
	               mix(dot(hash3(i + vec3(0.0,1.0,1.0)), f - vec3(0.0,1.0,1.0)),
	                   dot(hash3(i + vec3(1.0,1.0,1.0)), f - vec3(1.0,1.0,1.0)), u.x), u.y), u.z) * 0.5 + 0.5;
}

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 base_tex = texture(albedo_texture, UV);
	vec4 color = albedo_color * base_tex;
	
	// Compute 3D spatial noise
	float noise_val = noise3d(v_world_pos * noise_scale);
	float fine_noise = noise3d(v_world_pos * noise_scale * 3.5);
	
	vec3 total_emission = vec3(0.0);

	// 1. Internal Energy Glow
	if (internal_glow > 0.0) {
		float rim = 1.0 - max(0.0, dot(NORMAL, VIEW));
		total_emission += internal_glow_color.rgb * internal_glow * (rim * 0.75 + 0.25);
	}

	// 2. Surface Fracture Veins
	if (fracture_amount > 0.0) {
		float vein = step(0.92 - fracture_amount * 0.4, fine_noise);
		total_emission += fracture_color.rgb * vein * fracture_amount * 3.5;
	}

	// 3. 3D Noise Dissolve Discard & Emissive Burn Border
	if (dissolve_amount > 0.0) {
		float threshold = dissolve_amount;
		if (noise_val < threshold) {
			discard;
		}
		
		float edge = noise_val - threshold;
		if (edge < burn_width) {
			float factor = edge / max(0.001, burn_width);
			vec3 emissive = mix(burn_core_color.rgb * 5.0, burn_color.rgb * 2.5, factor);
			total_emission += emissive;
		}
	}
	
	ALBEDO = color.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = total_emission;
}
