extends Node2D
var script_name = "listmenu"
var wait_signal = "tree_exited"

var scene_name:String
var root_path
var z

var IButtonS = preload("res://System/UI/IButton.gd")
var back_button
var choice_art
var choice_high_art

var button_y = 30

var allow_back_button = true
var fail = "none"

func add_button(normal, highlight, button_name):
	print(normal, highlight)
	var button = IButtonS.new(
		Filesystem.load_atlas_frames(
			Filesystem.lookup_file(normal, root_path)
		)[0],
		Filesystem.load_atlas_frames(
			Filesystem.lookup_file(highlight, root_path)
		)[0]
	)
	button.menu = self
	button.button_name = button_name
	add_child(button)
	return button

# TODO figure out how we decide whther to show the back button or not
	
func load_art(root_path):
	self.root_path = root_path
	if allow_back_button:
		back_button = add_button(
			"art/general/back.png",
			"art/general/back_high.png",
			"_^BACK^_"
		)
		back_button.position = Vector2(
			back_button.width/2,
			192-back_button.height/2
		)
	position = Vector2(0, 192)
	z = ZLayers.z_sort[script_name]
	
func add_item(text, result):
	var button = add_button(
		"art/general/talkchoice.png",
		"art/general/talkchoice_high.png",
		result
	)
	button.position = Vector2((256-button.width)/2+button.width/2, button_y)
	button_y += button.height+5
	var button_label := Label.new()
	button_label.set("custom_colors/font_color", Color(0,0,0))
	button_label.align = Label.ALIGN_CENTER
	button_label.valign = Label.VALIGN_CENTER
	button_label.rect_position = Vector2(-button.width/2, -button.height/2)
	button_label.rect_size = Vector2(button.width, button.height)
	button_label.text = text
	button.add_child(button_label)
	add_child(
		button
	)

func click_option(option):
	if option == "_^BACK^_":
		queue_free()
	else:
		Commands.call_goto(
			Commands.main.stack.scripts[-1],
			[
				option
			]
		)
		queue_free()
