extends WrightObject

var scene_name:String

var back_button
var called_court_record_button = false
var choice_art
var choice_high_art
var _items = []

var button_y = 30

var allow_back_button = true
var fail = "none"


var tag = ""
var check_image = ""
var check_offset_x = -10
var check_offset_y = -10

var blocks_action_advance := true

# TODO figure out how we decide whther to show the back button or not

func _init():
	save_properties += ["scene_name", "allow_back_button", "fail", "_items", "check_image", "check_offset_x", "check_offset_y", "tag"]

func _ready():
	script_name = "listmenu"
	wait_signal = "tree_exited"
	
	# Set these after initialization  with `lo`
	check_image = main.stack.variables.get_string("_list_checked_img","general/checkmark")
	check_offset_x = main.stack.variables.get_int("_list_checked_x",-10)
	check_offset_y = main.stack.variables.get_int("_list_checked_y",-10)
	
func _get_checked_list():
	if not tag:
		return []
	var checked = main.stack.variables.get_string("_pwlist_checked_items_"+tag, "")
	checked = checked.split(";;")
	return checked
	
func is_checked(label):
	return label in _get_checked_list()
	
func set_checked(label):
	if not tag:
		return
	var checked = _get_checked_list()
	if not label in checked:
		checked.append(label)
		main.stack.variables.set_val("_pwlist_checked_items_"+tag, checked.join(";;"))
	
func build():
	add_list_items()
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
	if not called_court_record_button:
		Commands.call_macro("show_court_record_button", wrightscript, [])
		called_court_record_button = true
	
func add_item(text, result, options={}):
	_items.append([text, result, options])

func add_list_items():
	var bg = ObjectFactory.create_from_template(
		main.top_script(),
		"graphic",
		{},
		[main.stack.variables.get_string("_list_bg_image", "general/main2")],
		script_name
	)
	bg.cannot_save = true
	# Ensure interface doesn't allow clicks below it
	# TODO - it's weird to have to make guis to block things off, should be
	# built into ObjectFactory template maybe?
	var blocker = Control.new()
	blocker.name = "BLOCKER"
	blocker.rect_size = Vector2(bg.width, bg.height)
	bg.add_child(blocker)

	for item in _items:
		var text = item[0]
		var result = item[1]
		var options = item[2]
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
				"select_macro": "{select_list_item}",
				"select_args": [result]
			},
			["name="+text],
			script_name
		)
		button.cannot_save = true
		button.position = Vector2((256-button.width)/2, button_y)
		button_y += button.height+5
		# TODO we could probably bake this into button text
		var button_label := Label.new()
		Fonts.set_element_font(button_label, "list", main.stack)
		button_label.set("custom_colors/font_color", Colors.string_to_color(main.stack.variables.get_string("_list_text_color", "6e1414")))
		button_label.align = Label.ALIGN_CENTER
		button_label.valign = Label.VALIGN_CENTER
		#button_label.rect_position = Vector2(button.width/2, button.height/2)
		button_label.rect_size = Vector2(button.width, button.height)
		button_label.text = text
		button.add_child(button_label)
		# TODO enable setting the text color, font, size of the option
		if is_checked(result) or Values.to_truth(options.get("force_check", "false")):
			var lcheck_image = options.get("checkmark", check_image)
			var lcheck_offset_x = options.get("check_x", check_offset_x)
			var lcheck_offset_y = options.get("check_y", check_offset_y)
			var check_ob = ObjectFactory.create_from_template(
				get_tree().root.get_node("Main").top_script(),
				"graphic",
				{
					"sprites": {
						"default": {"path":"art/"+lcheck_image+".png"},
					}
				},
				[],
				button
			)
			check_ob.position = Vector2(lcheck_offset_x, lcheck_offset_y)
			check_ob.cannot_save = true
		
func set_list_item_options(options):
	_items[-1][2] = options
	
func ws_click_back_from_list(script, arguments):
	queue_free()
	Commands.call_command("sound_list_menu_cancel", script, [])
	
func ws_click_list_item(script, arguments):
	set_checked(" ".join(arguments))
	Commands.call_command(
		"goto",
		stack.scripts[-1],
		[
			" ".join(arguments)
		]
	)
	Commands.call_command("sound_list_menu_confirm", stack.scripts[0], [])
	queue_free()
	
func ws_select_list_item(script, arguments):
	var result = arguments[0]
	for item in _items:
		if result == item[1]:
			var select_macro = item[2].get("on_select", null)
			if select_macro:
				Commands.call_command(select_macro, stack.scripts[0], [])
				return
	Commands.call_command("sound_list_menu_select", stack.scripts[0], [])


#SAVE/LOAD
func after_load(tree:SceneTree, saved_data:Dictionary):
	var copy_items = _items.duplicate()
	_items = []
	for item in copy_items:
		var text = item[0]
		var result = item[1]
		var options = {}
		if item.size()>2:
			options = item[2]
		add_item(text, result, options)
	.after_load(tree, saved_data)
	build()
