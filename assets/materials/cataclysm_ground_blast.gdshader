shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 fissure_color : source_color = vec4(1.0, 0.95, 1.0, 1.0);
uniform vec4 magma_purple : source_color = vec4(0.8, 0.25, 1.0, 1.0);
uniform vec4 stone_tint : source_color = vec4(0.15, 0.12, 0.18, 1.0);
uniform float rupture_phase : hint_range(0.0, 1.0) = 0.0;
uniform float crack_glow_energy : hint_range(0.0, 25.0) = 12.0;

void fragment() {
    float dist = length(VERTEX.xz);
    float wave_front = rupture_phase * 22.0;
    float edge_proximity = 1.0 - clamp(abs(dist - wave_front) / 3.5, 0.0, 1.0);
    
    vec4 emissive_col = mix(magma_purple, fissure_color, edge_proximity * 0.9);
    
    ALBEDO = mix(stone_tint.rgb, emissive_col.rgb, edge_proximity * 0.4);
    EMISSION = emissive_col.rgb * (crack_glow_energy * edge_proximity * (1.0 - rupture_phase * 0.5));
    ALPHA = clamp(1.0 - (rupture_phase * 0.8), 0.0, 1.0);
    ROUGHNESS = 0.75;
}
