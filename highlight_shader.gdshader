shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform vec4 highlight_color : source_color = vec4(0.0, 0.5, 1.0, 0.3);
uniform float highlight_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb * albedo.rgb;
    
    // Добавляем эмиссию на основе highlight_amount
    EMISSION = highlight_color.rgb * highlight_amount * 0.5;
}