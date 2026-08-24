shader_type spatial;
render_mode blend_add, depth_draw_never, unshaded, cull_disabled;

// OATHBOUND Organic Particle Flare Shader
// Replaces square billboard quads with smooth exponential radial & streak energy profiles.

uniform vec4 core_color : source_color = vec4(0.95, 0.9, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.55, 0.15, 0.95, 1.0);
uniform float falloff_power : hint_range(1.0, 8.0) = 3.5;
uniform bool is_streak = false;

void fragment() {
	vec2 center_uv = UV - vec2(0.5);
	if (is_streak) {
		center_uv.y *= 2.5; // Elongated streak profile
	}
	float dist = length(center_uv) * 2.0;
	if (dist > 1.0) {
		discard;
	}
	
	float intensity = pow(1.0 - dist, falloff_power);
	vec3 color = mix(edge_color.rgb * 2.5, core_color.rgb * 5.0, pow(intensity, 2.0));
	
	ALBEDO = vec3(0.0);
	EMISSION = color * COLOR.rgb * intensity;
	ALPHA = intensity * edge_color.a * COLOR.a;
}
