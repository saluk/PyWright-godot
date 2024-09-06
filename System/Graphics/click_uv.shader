shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float texture_width = 300;
uniform float texture_height = 300;
uniform int region_shades;
uniform vec4 region1;
uniform vec4 region2;
uniform vec4 region3;
uniform vec4 region4;
uniform vec4 region5;
uniform vec4 region6;
uniform vec4 region7;
uniform vec4 region8;
uniform vec4 region9;
uniform int region_max;

bool in_region(vec2 uv, vec4 region) {
	float x = uv.x * texture_width;
	float y = uv.y * texture_height;
	if((x >= region.x && x < (region.x + region.b)) && (y >= region.y && y < (region.y + region.a))) {
		return true;
	}
	return false;
}

void fragment() {
	float click_colors[] = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9};
	vec4 regions[] = {region1, region2, region3, region4, region5, region6, region7, region8, region9};
	for(int i; i<min(click_colors.length(), region_max); i++) {
		if(in_region(UV, regions[i])) {
			ALBEDO.x = click_colors[i];
			break;
		}
	}
	//ALBEDO.x = UV.y;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	//ALBEDO.y = 0.5;
}