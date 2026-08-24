shader_type spatial;
render_mode cull_disabled, depth_draw_never, blend_add, unshaded;

// OATHBOUND Atmospheric Shock Wave Distortion & Emission Shader
// Renders expanding 3D compression shock front with refractive-like edge glow and dust agitation.

uniform vec4 shock_color : source_color = vec4(0.85, 0.65, 1.0, 0.7);
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float expansion_progress : hint_range(0.0, 1.0) = 0.0;
uniform float distortion_intensity : hint_range(0.0, 5.0) = 2.5;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fresnel = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 2.5);
	float edge_rim = smoothstep(0.2, 0.8, fresnel);
	
	vec3 col = mix(shock_color.rgb * distortion_intensity, highlight_color.rgb * (distortion_intensity * 2.0), edge_rim);
	float alpha = clamp(fresnel * shock_color.a * (1.0 - expansion_progress), 0.0, 1.0);
	
	ALBEDO = vec3(0.0);
	EMISSION = col * alpha;
	ALPHA = alpha;
}
