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
	var font := FontFile.new()
	var font_path = Filesystem.lookup_file("fonts/"+font_data["font_path"], stack.scripts[-1].root_path)
	if not font_path:
		GlobalErrors.log_error("Error setting font for type "+str(font_data))
		return null
	print("font_path:", font_path)
	var loaded_font = stack.main.font_cache.get_cached(font_path, null)
	if not loaded_font:
		loaded_font = load(font_path)
		# TODO 4.4 see about dynamic load of pwinternational.ttf from COAA
		# let's fall back to a generic font if we can't load it
		if loaded_font:
			stack.main.font_cache.set_cached(font_path, loaded_font)
		else:
			loaded_font = load("res://fonts/VeraSe.ttf")
	font.font_data = loaded_font
	# TODO 4.4 move the size to the theme for whatever is rendering the font
	#font.size = font_data["font_size"]
	#font.use_filter = true
	#font.use_mipmaps = true
	font.set_extra_spacing(0, TextServer.SPACING_SPACE, font_data["font_spacing"])
	return font

static func set_element_font(el, type, main):
	var font_data = _get_font_for_type(type, main)
	var font = _get_font(type, main)
	if font:
		for font_mode in ["", "normal_", "mono_", "italics_", "bold_italics_", "bold_"]:
			el.set("theme_override_fonts/" + "font", font)
			el.set("theme_override_fonts/" + "font_size", font_data["font_size"])
