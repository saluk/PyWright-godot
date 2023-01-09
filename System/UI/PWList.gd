extends Node2D
var script_name = "listmenu"
var wait_signal = "tree_exited"

var scene_name:String
var root_path
var z

var back_button
var choice_art
var choice_high_art

var button_y = 30

var allow_back_button = true
var fail = "none"

# TODO figure out how we decide whther to show the back button or not
	
func load_art(root_path):
	self.root_path = root_path
	position = Vector2(0, 192)
	z = ZLayers.z_sort[script_name]
	
func update():
	if allow_back_button and not back_button:
		back_button = ObjectFactory.create_from_template(
			get_tree().root.get_node("Main").top_script(),
			"button",
			{
				"sprites": {
					"default": {"path": "art/general/back.png"},
					"highlight": {"path": "art/general/back_high.png"}
				},
				"click_macro": "click_back_from_list"
			},
			[],
			script_name
		)
		back_button.position = Vector2(
			0,
			192-back_button.height
		)
	.update()
	
func add_item(text, result):
	var button = ObjectFactory.create_from_template(
		get_tree().root.get_node("Main").top_script(),
		"button",
		{
			"sprites": {
				"default": {"path":"art/general/talkchoice.png"},
				"highlight": {"path": "art/general/talkchoice_high.png"}
			},
			"click_macro": "click_list_item",
			"click_args": [result],
		},
		[],
		script_name
	)
	button.position = Vector2((256-button.width)/2, button_y)
	button_y += button.height+5
	var button_label := Label.new()
	button_label.set("custom_colors/font_color", Color(0,0,0))
	button_label.align = Label.ALIGN_CENTER
	button_label.valign = Label.VALIGN_CENTER
	#button_label.rect_position = Vector2(button.width/2, button.height/2)
	button_label.rect_size = Vector2(button.width, button.height)
	button_label.text = text
	button.add_child(button_label)
	add_child(
		button
	)
	
func ws_click_back_from_list(script, arguments):
	queue_free()
	
func ws_click_list_item(script, arguments):
		Commands.call_command(
			"goto",
			Commands.main.stack.scripts[-1],
			[
				" ".join(arguments)
			]
		)
		queue_free()
