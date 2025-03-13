shader_type canvas_item;

const vec4 background = vec4(1., 1., 1., 0.);

// image_filters.shader
uniform float greyscale_amt = 0.0;
uniform float to_color_amount = 0.0;
uniform vec4 to_color = vec4(1.0, 1.0, 1.0, 1.0);

float dist(vec4 c1, vec4 c2) {
	return (c1 == c2) ? 0.0 : abs(c1.r - c2.r) + abs(c1.g - c2.g) + abs(c1.b - c2.b);
}

bool similar(vec4 c1, vec4 c2, vec4 input) {
	return (c1 == c2 || (dist(c1, c2) <= dist(input, c2) && dist(c1, c2) <= dist(input, c1)));
}

bool different(vec4 c1, vec4 c2, vec4 input) {
	return !similar(c1, c2, input);
}


// rotsprite 2x enlargement algorithm:
// suppose we are looking at input pixel cE which is surrounded by 8 other 
// pixels:
//  cA cB cC
//  cD cE cF
//  cG cH cI
// and for that 1 input pixel cE we want to output 4 pixels oA, oB, oC, and oD:
//  oA oB
//  oC oD
vec4 scale2x(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec4 input = texture(tex, uv);

	vec4 cD = texture(tex, uv + pixel_size * vec2(-1., .0));
	cD.a = 1.0;
	vec4 cF = texture(tex, uv + pixel_size * vec2(1., .0));
	cF.a = 1.0;
	vec4 cH = texture(tex, uv + pixel_size * vec2(.0, 1.));
	cH.a = 1.0;
	vec4 cB = texture(tex, uv + pixel_size * vec2(.0, -1.));
	cB.a = 1.0;
	vec4 cA = texture(tex, uv + pixel_size * vec2(-1., -1.));
	cA.a = 1.0;
	vec4 cI = texture(tex, uv + pixel_size * vec2(1., 1.));
	cI.a = 1.0;
	vec4 cG = texture(tex, uv + pixel_size * vec2(-1., 1.));
	cG.a = 1.0;
	vec4 cC = texture(tex, uv + pixel_size * vec2(1., -1.));
	cC.a = 1.0;

	if (different(cD,cF, input)
     && different(cH,cB, input)
     && ((similar(input, cD, input) || similar(input, cH, input) || similar(input, cF, input) || similar(input, cB, input) ||
         ((different(cA, cI, input) || similar(input, cG, input) || similar(input, cC, input)) &&
          (different(cG, cC, input) || similar(input, cA, input) || similar(input, cI, input))))))
    {
		vec2 unit = uv - (floor(uv / pixel_size) * pixel_size);
		vec2 pixel_half_size = pixel_size / 2.0;
		if (unit.x < pixel_half_size.x && unit.y < pixel_half_size.y) {
			return ((similar(cB, cD, input) && ((different(input, cA, input) || different(cB, background, input)) && (different(input, cA, input) || different(input, cI, input) || different(cB, cC, input) || different(cD, cG, input)))) ? cB : input);
		}

		if (unit.x >= pixel_half_size.x && unit.y < pixel_half_size.y) {
			return ((similar(cF, cB, input) && ((different(input, cC, input) || different(cF, background, input)) && (different(input, cC, input) || different(input, cG, input) || different(cF, cI, input) || different(cB, cA, input)))) ? cF : input);
		}

		if (unit.x < pixel_half_size.x && unit.y >= pixel_half_size.y) {
			return ((similar(cD, cH, input) && ((different(input, cG, input) || different(cD, background, input)) && (different(input, cG, input) || different(input, cC, input) || different(cD, cA, input) || different(cH, cI, input)))) ? cD : input);
		}

        return ((similar(cH, cF, input) && ((different(input, cI, input) || different(cH, background, input)) && (different(input, cI, input) || different(input, cA, input) || different(cH, cG, input) || different(cF, cC, input)))) ? cH : input);
    }

	return input;
}

vec4 image_filter(vec4 input_color) {
	vec4 col = input_color;
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
		// Only blend alpha values if we are heading to a transparent value
		if (to_color.a < 0.99) {
			col.a = (1.0-to_color_amount)*col.a + (to_color_amount)*to_color.a;
		}
	}
	return col;
}

void fragment() {
	vec4 col = scale2x(TEXTURE, UV, TEXTURE_PIXEL_SIZE);
	COLOR = image_filter(col);
}