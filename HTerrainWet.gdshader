shader_type spatial;

uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D albedo_texture;  // Задаём текстуру вручную

void fragment() {
    vec4 albedo_tex = texture(albedo_texture, UV);  // Берём текстуру с UV-координатами
    vec3 wet_color = mix(albedo_tex.rgb, vec3(0.2, 0.2, 0.2), wetness);
    
    ALBEDO = wet_color;
    ROUGHNESS = mix(1.0, 0.2, wetness);
}
