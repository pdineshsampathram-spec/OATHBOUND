shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.98, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.7, 0.3, 1.0, 0.85);
uniform float expansion_phase : hint_range(0.0, 1.0) = 0.0;
uniform float explosion_speed : hint_range(0.0, 10.0) = 4.0;
uniform float emission_strength : hint_range(0.0, 20.0) = 8.0;

void vertex() {
    float t = TIME * explosion_speed;
    vec3 n = normalize(VERTEX);
    float spike = sin(n.x * 12.0 + t) * cos(n.y * 12.0 + t) * sin(n.z * 12.0 + t);
    VERTEX += n * (spike * 0.6 * expansion_phase);
}

void fragment() {
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.8);
    // Hollow epicenter: Alpha is concentrated at expanding rim
    float rim_alpha = smoothstep(0.1, 0.7, fresnel);
    
    vec4 col = mix(rim_color, core_color, fresnel * 0.8);
    
    ALBEDO = col.rgb;
    EMISSION = col.rgb * (emission_strength * (1.0 - expansion_phase * 0.4));
    ALPHA = rim_alpha * (1.0 - expansion_phase) * col.a;
}
