shader_type spatial;
render_mode unshaded, cull_disabled;

void fragment() {
	ALBEDO = vec3(UV.x, UV.y, 1.0);
}