shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 core_color : source_color = vec4(0.95, 0.90, 1.0, 1.0);
uniform vec4 mid_color : source_color = vec4(0.65, 0.25, 0.95, 0.9);
uniform vec4 outer_color : source_color = vec4(0.12, 0.02, 0.28, 0.7);
uniform float bloom_growth : hint_range(0.0, 1.0) = 0.0;
uniform float turbulence_speed : hint_range(0.0, 5.0) = 1.2;
uniform float emission_energy : hint_range(0.0, 15.0) = 4.5;

float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3d(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(hash(p + vec3(0,0,0)), hash(p + vec3(1,0,0)), f.x),
            mix(hash(p + vec3(0,1,0)), hash(p + vec3(1,1,0)), f.x), f.y),
        mix(mix(hash(p + vec3(0,0,1)), hash(p + vec3(1,0,1)), f.x),
            mix(hash(p + vec3(0,1,1)), hash(p + vec3(1,1,1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100.0);
    for (int i = 0; i < 3; ++i) {
        v += a * noise3d(p);
        p = p * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void vertex() {
    float t = TIME * turbulence_speed;
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float n = fbm(world_pos * 0.08 + vec3(t * 0.2, t * 0.15, t * 0.1));
    VERTEX += NORMAL * (n * 3.5 * bloom_growth);
}

void fragment() {
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float t = TIME * turbulence_speed;
    float n = fbm(world_pos * 0.06 - vec3(0.0, 0.0, t * 0.3));
    
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
    
    vec4 col = mix(outer_color, mid_color, clamp(n * 1.8, 0.0, 1.0));
    col = mix(col, core_color, clamp((1.0 - fresnel) * n * 1.5 - 0.3, 0.0, 1.0));
    
    ALBEDO = col.rgb;
    EMISSION = col.rgb * (emission_energy * (0.6 + n * 0.8) * bloom_growth);
    ALPHA = clamp(col.a * bloom_growth * (0.3 + fresnel * 0.7), 0.0, 0.95);
    ROUGHNESS = 0.85;
}
