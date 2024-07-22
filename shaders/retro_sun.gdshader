shader_type spatial;

uniform sampler2D texture_albedo : source_color;
uniform vec4 color_top : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 1.0;
uniform float position : hint_range(-0.5, 0.5) = 0.0;
uniform float blend : hint_range(0.5, 2.0) = 0.5;
uniform float angle : hint_range(0.0, 360.0) = 90.0;

uniform float line_height_min : hint_range(0.0, 1.0) = 0.01;
uniform float line_height_max : hint_range(0.0, 1.0) = 0.1;
uniform int num_lines : hint_range(1, 10) = 6;
uniform float speed : hint_range(0.0, 1.0) = 0.1;
uniform float vertical_origin : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex_color = texture(texture_albedo, UV);

    float pivot = position + 0.5;
    vec2 uv = UV - vec2(pivot);
    float radians_angle = radians(angle);
    float rotated = uv.x * cos(radians_angle) - uv.y * sin(radians_angle);
    float pos = smoothstep((1.0 - blend) + position, blend + 0.0001 + position, rotated + pivot);
    vec3 gradient_color = mix(color_bottom.rgb, color_top.rgb, pos);

    float alpha = tex_color.a;
	
    float moving_position = mod(TIME * speed, 1.0 + line_height_max); 
    for (int i = 0; i < num_lines; i++) {
        float line_position = mod(moving_position + float(i) / float(num_lines), 1.0 + line_height_max) - line_height_max;
        float adjusted_position = vertical_origin + (1.0 - vertical_origin) * line_position;
        float line_height = mix(line_height_max, line_height_min, clamp(line_position, 0.0, 1.0));

        float line_alpha = smoothstep(adjusted_position - line_height / 2.0, adjusted_position + line_height / 2.0, UV.y) - smoothstep(adjusted_position + line_height / 2.0, adjusted_position + line_height / 2.0 + 0.01, UV.y);
        alpha *= (1.0 - line_alpha);
    }

    ALBEDO = mix(tex_color.rgb, gradient_color, alpha);
    ALPHA = alpha;
    EMISSION = gradient_color * intensity * alpha;
}