extends Node

var main:Node
var z:int

var textboxScene = preload("res://System/UI/Textbox.tscn")

var last_object

export var PAUSE_MULTIPLIER = 1.0

enum {
	YIELD,              # Pause wrightscript for user input or animation
	END,                # End script
	UNDEFINED,          # Command we don't know about
	DEBUG,              # launch godot debugger
	NOTIMPLEMENTED,     # Command we don't care about
	NEXTLINE            # Run next execution frame
}

var SPRITE_GROUP = "PWSprites"   # Every wrightscript object should be in this
var CHAR_GROUP = "PWChar"        # Objects that are PWChar should be in this
var HIDDEN_CHAR_GROUP = "PWHiddenChar"   # We should only ever have 1 hidden character
var LIST_GROUP = "PWLists"
var BG_GROUP = "PWBG"
var FG_GROUP = "PWFG"
var CLEAR_GROUP = "PWCLEAR"   # Any object that should be cleared when setting a new background
var ARROW_GROUP = "PWARROWS"
var TEXTBOX_GROUP = "TEXTBOX_GROUP"
var PENALTY_GROUP = "PWPENALTY"
var COURT_RECORD_GROUP = "CourtRecord"
var MESH_GROUP = "Meshes"  # Used for anything that is 3d

var external_commands = {}

signal button_clicked

# Helper functions
func on_screen(screen, nodes):
	# Return nodes that are in a given screen
	var onscreen = []
	var children = []
	if screen:
		children = screen.get_children()
	for n in nodes:
		if n in children:
			onscreen.append(n)
		elif n.has_method("get_screen"):
			if n.get_screen() == screen:
				onscreen.append(n)
	return onscreen

func load_command_engine():
	main = get_tree().get_nodes_in_group("Main")[0]
	index_commands()

func value_replace(value):
	# Replace from variables if starts with $
	# TODO move to stack
	if value.begins_with("$"):
		return main.stack.variables.get_string(value.substr(1))
	return value

func keywords(arguments, remove=false):
	# TODO determine if we actually ALWAYS want to replace $ variables here
	var newargs = []
	var d = {}
	for arg in arguments:
		if "=" in arg and not "==" in arg:
			var split = arg.split("=", true, 1)
			d[split[0]] = value_replace(split[1])
		else:
			newargs.append(arg)
	if remove:
		return [d, newargs]
	return d

func join(l, sep=" "):
	return PoolStringArray(l).join(sep)

func create_textbox(script, line) -> Node:
	var l = textboxScene.instance()
	l.main = main
	l.in_statement = main.stack.variables.get_truth("_in_statement", false)
	if l.in_statement:
		line = "{c292}{tbon}" + line
	l.text_to_print = line
	main.stack.variables.del_val("_in_statement")
	script.screen.add_child(l)
	return l

# TODO may not need this
# Although it might be needed for press/present
# Also todo, all the other arrow functions are in textbox... move this there?
func hide_arrows(script):
	call_macro("hide_main_button", script, [])
	call_macro("hide_court_record_button", script, [])
	call_macro("hide_present_button", script, [])
	call_macro("hide_press_button", script, [])
	call_macro("hide_main_button_all", script, [])

func get_speaking_char(speaking=null):
	if not speaking:
		speaking = main.stack.variables.get_string("_speaking", null)
	if not speaking:
		return null
	var characters = ScreenManager.get_objects(null, null, CHAR_GROUP)
	var found = null
	for character in characters:
		if character.script_name == speaking:
			found = character
		if character.base_path == speaking:
			found = character
	if found:
		return found
	# _speaking not set to a character onscreen...
	# assume the case author means to make SOMEBODY talk
	for character in characters:
		return character

# Gets nametag for currently speaking character
func get_nametag():
	var nametag = main.stack.variables.get_string("_speaking_name", "")
	var character = get_speaking_char()
	if character:
		nametag = character.char_name
		# Hide nametag if character sprites didn't load
		if character.sprites and not nametag:
			nametag = character.base_path.capitalize()
	return nametag

# Call interface

func generate_command_map(version=""):
	# TODO implement versioning
	var path = "res://System/WrightScript/Commands/"
	var folder = Directory.new()
	if folder.open(path) != OK:
		print("ERROR: NO COMMANDS FOUND")
		assert(false)
	var command_files = []
	var file_name = "yes"
	folder.list_dir_begin()
	while file_name:
		file_name = folder.get_next()
		# Exported source files end in gdc
		if not (file_name.ends_with(".gd") or file_name.ends_with(".gdc")):
			continue
		command_files.append(path+file_name)
	if not command_files:
		print("ERROR: NO COMMANDS FOUND")
		assert(false)
	return command_files

func get_call_methods(object):
	var l = []
	for method in object.get_method_list():
		if method["name"].begins_with("ws_"):
			l.append(method["name"])
	return l

func index_commands():
	external_commands = {}
	for command_file in generate_command_map():
		var extern = load(command_file).new(self)
		for command in get_call_methods(extern):
			external_commands[command] = extern

func is_macro_or_command(command):
	return is_macro(command) or has_method("ws_"+command) or "ws_"+command in external_commands

func call_command(command, script, arguments):
	command = value_replace(command)

	var args = []
	for arg in arguments:
		args.append(value_replace(arg))
	arguments = args

	# gui Buttons use {} to mean either a macro or a label
	if command.begins_with("{") and command.ends_with("}"):
		command = command.substr(1,command.length()-2)

	if is_macro(command):
		return call_macro(command, script, arguments)

	if has_method("ws_"+command):
		return call("ws_"+command, script, arguments)

	if "ws_"+command in external_commands:
		var extern = external_commands["ws_"+command]
		return extern.callv("ws_"+command, [script, arguments])

	for object in script.screen.get_objects(null):
		if object.has_method("ws_"+command):
			return object.callv("ws_"+command, [script, arguments])
	return UNDEFINED

func is_macro(command):
	if main.stack.macros.has(command):
		return command
	return ""

func get_processed_macro_lines(macro_name, arguments, line_num):
	var input_str = PoolStringArray(main.stack.macros[macro_name]).join("\n")
	input_str = input_str.replace("$0", str(line_num))
	var i = 1
	for arg in arguments:
		if "=" in arg:
			var spl = arg.split("=", false, 1)
			input_str = input_str.replace("$"+spl[0].strip_edges(), spl[1].strip_edges())
		else:
			input_str = input_str.replace("$"+str(i), arg)
			i += 1
	return input_str.split("\n", false)

# TODO - may need to support actually replacing macro text with the arguments passed,
# but wont implement till we actually need to
func call_macro(macro_name, script, arguments):
	# FIXME Something weird happened here
	if not script:
		return
	var command = is_macro(macro_name)
	if not command:
		return
	var script_lines = get_processed_macro_lines(macro_name, arguments, script.line_num)
	var new_script = main.stack.add_script(PoolStringArray(script_lines).join("\n"), script.root_path)
	new_script.filename = "{"+command+"}"
	# TODO not sure if this is how to handle macros that try to goto
	new_script.allow_goto_parent_script = true
	return YIELD

func macro_or_label(key, script, arguments):
	var is_macro = is_macro(key)
	if is_macro:
		return call_macro(is_macro, script, [])
	return script.goto_label(key)

# Script commands

func ws_draw_off(script, arguments):
	pass # No op, old pywright needed the user to determine when to pause to load many graphics

func ws_draw_on(script, arguments):
	pass

# Godot specific control commands

func ws_godotdebug(script, arguments):
	# You can use this command to enter the godot debugger
	pass


func save_node(data):
	print(last_object)
	data["last_object"] = SaveState.to_node_path(last_object)

func load_node(tree, saved_data:Dictionary):
	pass

func after_load(tree, saved_data:Dictionary):
	if saved_data["last_object"]:
		if get_tree().root.has_node(saved_data["last_object"]):
			last_object = get_tree().root.get_node(saved_data["last_object"])
