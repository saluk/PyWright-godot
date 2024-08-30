extends WrightObject
class_name TextBlock

var text_contents
var text_width = 0
var text_height = 0
var text_color = "FFFFFF"
var has_objects = false

func _init():
	._init()
	save_properties.append("text_contents")
	save_properties.append("text_width")
	save_properties.append("text_height")
	save_properties.append("text_color")

func reset():
	has_objects = false
	for child in get_children():
		child.queue_free()
	
func _process(dt):
	if has_objects:
		return
	has_objects = true
	load_text()
	
func load_text():
	var desc:Label = Label.new()
	Fonts.set_element_font(desc, "block", stack)
	desc.rect_position = Vector2(1,1)
	desc.rect_size = Vector2(
		text_width,
		text_height
	)
	desc.set("custom_constants/line_spacing", 
		StandardVar.FONT_BLOCK_LINEHEIGHT.retrieve()
	)
	desc.set("custom_colors/font_color", Colors.string_to_color(text_color))
	desc.text = text_contents.replace("{n}","\n")
	desc.clip_text = true
	desc.autowrap = true
	add_child(desc)

#SAVE/LOAD
func load_node(tree:SceneTree, saved_data:Dictionary):
	reset()
	.load_node(tree, saved_data)
