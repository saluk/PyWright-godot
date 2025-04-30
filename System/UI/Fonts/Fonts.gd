extends Resource
class_name Fonts

# TODO this should use StandardVar
static func _get_font_for_type(type, main):
	var spacing = 0
	if type == "tb":
		spacing = -2
	return {
		"font_path": main.stack.variables.get_string("_font_"+type, "arial.ttf"),
		"font_size": main.stack.variables.get_int("_font_"+type+"_size", 16),
		"font_spacing": main.stack.variables.get_int("_font_"+type+"_spacing", spacing)
	}

static func _get_font(type, main):
	var stack = main.stack
	var font_data = _get_font_for_type(type, main)
	var font_path = Filesystem.lookup_file("fonts/"+font_data["font_path"], stack.scripts[-1].root_path)
	if not font_path:
		GlobalErrors.log_error("Error setting font for type "+str(font_data))
		return null
	print("font_path:", font_path)
	var font:FontFile = stack.main.font_cache.get_cached(font_path, null)
	if not font:
		font = FontFile.new()
		if font.load_dynamic_font(font_path) == OK:
			stack.main.font_cache.set_cached(font_path, font)
		else:
			font = load("res://fonts/VeraSe.ttf")
	# TODO 4.4 move the size to the theme for whatever is rendering the font
	#font.size = font_data["font_size"]
	#font.use_filter = true
	#font.use_mipmaps = true
	font.set_extra_spacing(0, TextServer.SPACING_SPACE, font_data["font_spacing"])
	print('FONT DATA type:', type, ' path:', font_path, ' data_size:', font.data.size())
	return font

static func set_element_font(el:Control, type, main):
	var font_data = _get_font_for_type(type, main)
	var font = _get_font(type, main)
	if font:
		for font_mode in ["normal_", "mono_", "italics_", "bold_italics_", "bold_"]:
			el.add_theme_font_override(font_mode+"font", font)
			el.add_theme_font_size_override(font_mode+"font", font_data["font_size"])
