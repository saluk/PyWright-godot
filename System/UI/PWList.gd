extends WrightObject

var scene_name:String

var back_button
var choice_art
var choice_high_art
var _items = []

var button_y = 30

var allow_back_button = true
var fail = "none"

# TODO figure out how we decide whther to show the back button or not

func _init():
	save_properties += ["scene_name", "allow_back_button", "fail", "_items"]

func _ready():
	script_name = "listmenu"
	wait_signal = "tree_exited"
	
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
				"click_macro": "{click_back_from_list}"
			},
			["name=back"],
			script_name
		)
		back_button.cannot_save = true
		back_button.position = Vector2(
			0,
			192-back_button.height
		)
	.update()
	
func add_item(text, result):
	_items.append([text, result])
	var button = ObjectFactory.create_from_template(
		get_tree().root.get_node("Main").top_script(),
		"button",
		{
			"sprites": {
				"default": {"path":"art/general/talkchoice.png"},
				"highlight": {"path": "art/general/talkchoice_high.png"}
			},
			"click_macro": "{click_list_item}",
			"click_args": [result],
			"select_macro": "{sound_list_menu_select}"
		},
		["name="+text],
		script_name
	)
	button.cannot_save = true
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
	
func ws_click_back_from_list(script, arguments):
	queue_free()
	Commands.call_command("sound_list_menu_cancel", script, [])
	
func ws_click_list_item(script, arguments):
	Commands.call_command(
		"goto",
		stack.scripts[-1],
		[
			" ".join(arguments)
		]
	)
	Commands.call_command("sound_list_menu_confirm", stack.scripts[0], [])
	queue_free()


#SAVE/LOAD
func after_load(tree:SceneTree, saved_data:Dictionary):
	var copy_items = _items.duplicate()
	_items = []
	for item in copy_items:
		add_item(item[0], item[1])
	.after_load(tree, saved_data)
	update()
