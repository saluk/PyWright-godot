extends Resource
class_name Fonts

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

static func get_font(type, stack):
	var variables = stack.variables
	# TODO - until we are storing font information in the variables somewhere...
	var font_path = variables.get_string("_font_"+type, "arial.ttf")
	var font_size = int(variables.get_string("_font_"+type+"_size", "16"))
	var font = DynamicFont.new()
	font_path = Filesystem.lookup_file("fonts/"+font_path, stack.scripts[-1].root_path)
	print("font_path:", font_path)
	font.font_data = load(font_path)
	font.size = font_size
	return font

static func set_element_font(el, type, stack):
	var font = get_font(type, stack)
	el.set("custom_fonts/font", font)
