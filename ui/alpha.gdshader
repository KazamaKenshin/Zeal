shader_type spatial;
render_mode depth_prepass_alpha;
uniform vec4 base_color : source_color;
uniform float transparency : hint_range(0.0, 1.0);

void fragment() {
SPECULAR = 0.5;
ROUGHNESS = 0.3;
ALBEDO = base_color.rgb;
ALPHA = transparency;
}