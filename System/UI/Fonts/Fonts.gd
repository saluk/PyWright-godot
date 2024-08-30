extends Resource
class_name Fonts

# TODO this should use StandardVar
static func get_font_for_type(type, stack):
	return {
		"font_path": stack.variables.get_string("_font_"+type, "arial.ttf"),
		"font_size": stack.variables.get_int("_font_"+type+"_size", "16")
	}

static func get_font(type, stack):
	var font_data = get_font_for_type(type, stack)
	var font = DynamicFont.new()
	var font_path = Filesystem.lookup_file("fonts/"+font_data["font_path"], stack.scripts[-1].root_path)
	if not font_path:
		return null
	print("font_path:", font_path)
	var loaded_font = stack.main.font_cache.get_cached(font_path, null)
	if not loaded_font:
		loaded_font = load(font_path)
		stack.main.font_cache.set_cached(font_path, loaded_font)
	font.font_data = loaded_font
	font.size = font_data["font_size"]
	return font

static func set_element_font(el, type, stack):
	var font = get_font(type, stack)
	if font:
		el.set("custom_fonts/font", font)
		el.set("custom_fonts/normal_font", font)
		el.set("custom_fonts/bold_font", font)
		el.set("custom_fonts/italics_font", font)
	else:
		var font_data = get_font_for_type(type, stack)
		GlobalErrors.log_error("Error setting font for type "+str(font_data))
