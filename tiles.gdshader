/*
Shader from Godot Shaders - the free shader library.
https://godotshaders.com/shader/quick-procedural-floor-tiles/

This shader is under CC0 license. Feel free to use, improve and 
change this shader according to your needs and consider sharing 
the modified result to godotshaders.com.
*/

shader_type spatial;

group_uniforms material_settings;
uniform vec3 tile_color : source_color = vec3(1.0);
uniform vec3 grout_color : source_color = vec3(0.0);
uniform vec3 accent_color : source_color = vec3(0.92, 0.70, 0.25);
uniform float roughness : hint_range(0.0, 1.0) = 0.2;
uniform bool use_normal_map = false;
uniform sampler2D normal_map : filter_linear_mipmap_anisotropic;
uniform float normal_intensity = 0.06;

group_uniforms scale_parameters;
uniform bool rotate_45 = false;
uniform float tile_scale = 2.0;
uniform float diamond_size : hint_range(0.0, 1.0) = 0.565;
uniform float grout_thickness : hint_range(0.0, 1.0) = 0.007;
uniform float diamond_accent_size : hint_range(0.0, 1.0) = 0.537;
uniform float grout_accent_size : hint_range(0.0, 1.0) = 0.018;

varying vec4 world_pos;

vec2 rotate(vec2 st, float angle) {
	st -= 0.5;
	vec2 xp = vec2(cos(angle), sin(angle));
	vec2 yp = vec2(-sin(angle), cos(angle));
	mat2 rotmat = mat2(xp, yp);
	return st * rotmat + 0.5;
}

float deg2rad(float deg) {
	return deg * (PI/180.0);
}

void vertex() {
	world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
}

void fragment() {
	//Set worldUV
	vec2 world_uv = vec2(world_pos.x, world_pos.z);
	if (rotate_45) {
		world_uv = rotate(vec2(world_pos.x, world_pos.z), deg2rad(45.0));
	}
	world_uv = fract(world_uv * tile_scale);
	
	//Draw circles
	float c = distance(vec2(0.5), world_uv);
	c = 1.0 - step(diamond_size, c);
	
	//Draw vertical lines
	float vl1 = step(grout_thickness, world_uv.x);
	float vl2 = 1.0 - step(1.0 - grout_thickness, world_uv.x);
	
	//Draw horizontal lines
	float hl1 = step(grout_thickness, world_uv.y);
	float hl2 = 1.0 - step(1.0 - grout_thickness, world_uv.y);
	
	//Combine lines
	float lines = vl1 * vl2 * hl1 * hl2;
	
	//Create pattern mask
	float pattern_mask = clamp(lines * c, 0.0, 1.0);
	
	//Draw accent circles
	float ac = distance(vec2(0.5), world_uv);
	ac = 1.0 - step(diamond_accent_size, ac);
	
	//Draw accent vertical lines
	float avl1 = step(grout_accent_size, world_uv.x);
	float avl2 = 1.0 - step(1.0 - grout_accent_size, world_uv.x);
	
	//Draw accent horizontal lines
	float ahl1 = step(grout_accent_size, world_uv.y);
	float ahl2 = 1.0 - step(1.0 - grout_accent_size, world_uv.y);
	
	//Combine accent lines
	float cal = avl1 * avl2 * ahl1 * ahl2;
	
	//Combine accent lines and accent diamonds
	float accent_mask = clamp(cal * ac, 0.0, 1.0);
	
	//Make separate tile mask
	float tile_mask = clamp(accent_mask * pattern_mask, 0.0, 1.0);
	
	//Mix colors
	vec3 color = mix(accent_color, vec3(1.0), accent_mask);
	color = mix(grout_color, color, pattern_mask);
	color = mix(color, tile_color, tile_mask);
	
	//Set outputs
	ALBEDO = color;
	ROUGHNESS = roughness;
	
	if (use_normal_map) {
		// If you want to use a normal map, tick the use normal map box in the inspector
		// You can either use an external normal map, or use the built in noise tool
		// To use built in noise tool, open normal map texture dropdown and select NewNoiseTexture2D
		// Set the resolution you like, make sure to check "seamless" and "as normal map"
		// Then, under "Noise," set the noise type you'd like to use
		NORMAL_MAP = texture(normal_map, world_uv).rgb;
		NORMAL_MAP_DEPTH = normal_intensity;
	}
	
}