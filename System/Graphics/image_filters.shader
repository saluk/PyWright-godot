
shader_type canvas_item; 

uniform float greyscale_amt = 0.0;
uniform float to_color_amount = 0.0;
uniform vec3 to_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE,UV).rgba;
	if (greyscale_amt > 0.0) {
		float val = (col.r+col.g+col.b)/3.0;
		col.r = val*greyscale_amt + col.r*(1.0-greyscale_amt);
		col.g = val*greyscale_amt + col.g*(1.0-greyscale_amt);
		col.b = val*greyscale_amt + col.b*(1.0-greyscale_amt);
	}
	if (to_color_amount > 0.0) {
		col.r = (1.0-to_color_amount)*col.r + (to_color_amount)*to_color.r;
		col.g = (1.0-to_color_amount)*col.g + (to_color_amount)*to_color.g;
		col.b = (1.0-to_color_amount)*col.b + (to_color_amount)*to_color.b;
	}
	COLOR=col;
}