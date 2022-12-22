extends Node

var main:Node
var main_screen:Node
var z:int

var textboxScene = preload("res://System/UI/Textbox.tscn")

var last_object

export var PAUSE_MULTIPLIER = 0.10

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
var centered_objects = ["fg"]

var external_commands = {}

# Helper functions
		
func get_objects(script_name, last=null, group=SPRITE_GROUP):
	if not get_tree():
		return []
	if last:
		return [last_object]
	var objects = []
	for object in get_tree().get_nodes_in_group(group):
		if object.is_queued_for_deletion():
			continue
		if not script_name or object.script_name == script_name:
			objects.append(object)
	return objects

func clear_main_screen():
	for child in main_screen.get_children():
		main_screen.remove_child(child)
		child.queue_free()
		
func load_command_engine():
	main = get_tree().get_nodes_in_group("Main")[0]
	main_screen = get_tree().get_nodes_in_group("MainScreen")[0]
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
		if "=" in arg:
			var split = arg.split("=", true, 1)
			d[split[0]] = value_replace(split[1])
		else:
			newargs.append(arg)
	if remove:
		return [d, newargs]
	return d
	
func join(l, sep=" "):
	return PoolStringArray(l).join(sep)

func create_textbox(line) -> Node:
	var l = textboxScene.instance()
	l.main = main
	l.text_to_print = line
	main_screen.add_child(l)
	return l

# TODO implement:
# loops
# flipx
# rotx, roty, rotz
# stack
# fade
var WAITERS = ["fg"]
func create_object(script, command, class_path, groups, arguments=[]):
	var object:Node
	object = load(class_path).new()
	main_screen.add_child(object)
	if "main" in object:
		object.main = main
	var x=int(keywords(arguments).get("x", 0))
	var y=int(keywords(arguments).get("y", 0))
	object.position = Vector2(x, y)
	if command in ["bg", "fg"]:
		var filename = Filesystem.lookup_file(
			"art/"+command+"/"+arguments[0]+".png",
			script.root_path
		)
		if not filename:
			main.log_error("No file found for "+arguments[0]+" tried: "+"art/"+command+"/"+arguments[0]+".png")
			return null
		object.load_animation(filename)
	elif command in ["gui"]:
		var frame = Filesystem.lookup_file(
			"art/"+keywords(arguments).get("graphic", "")+".png",
			script.root_path
		)
		var frameactive = Filesystem.lookup_file(
			"art/"+keywords(arguments).get("graphichigh", "")+".png",
			script.root_path
		)
		object.load_art(frame, frameactive, keywords(arguments).get("button_text", ""))
		object.area.rect_position = Vector2(0, 0)
	elif "PWChar" in class_path:
		object.load_character(
			arguments[0], 
			keywords(arguments).get("e", "normal"),
			script.root_path
		)
	elif "PWEvidence" in class_path:
		object.load_art(script.root_path, arguments[0])
	elif object.has_method("load_animation"):
		object.load_animation(
			Filesystem.lookup_file(
				"art/"+arguments[0]+".png",
				script.root_path
			)
		)
	elif object.has_method("load_art"):
		object.load_art(script.root_path)
	var center = Vector2()
	if command in centered_objects:
		object.position += Vector2(256/2-object.width/2, 192/2-object.height/2)
	last_object = object
	if arguments:
		object.script_name = keywords(arguments).get("name", arguments[0])
		object.add_to_group("name_"+object.script_name)
	if keywords(arguments).get("z", null)!=null:
		object.z = int(keywords(arguments)["z"])
	else:
		object.z = ZLayers.z_sort[command]
	for group in groups:
		object.add_to_group(group)
	object.name = object.script_name
	#Set object to wait mode if possible and directed to
	if "wait" in object:
		object.set_wait(command in WAITERS)
		# If we say to wait or nowait, apply it
		if "wait" in arguments:
			object.set_wait(true)    #Try to make the object wait, if it is a single play animation that has more than one frame
		if "nowait" in arguments:
			object.set_wait(false)
	return object
	
func refresh_arrows(script):
	get_tree().call_group(ARROW_GROUP, "queue_free")
	var arrow_class = "res://System/UI/IArrow.gd"
	if script.is_inside_cross():
		arrow_class = "res://System/UI/IArrowCross.gd"
	var arrow = create_object(
		script,
		"uglyarrow",
		arrow_class,
		[ARROW_GROUP, SPRITE_GROUP],
		[]
	)
	if script.get_prev_statement() == null and "left" in arrow:
		arrow.left.get_children()[1].visible = false
		arrow.left.get_children()[2].visible = false
	if script.is_inside_cross():
		call_macro("show_present_button", script, [])
		call_macro("show_press_button", script, [])
	else:
		call_macro("hide_present_button", script, [])
		call_macro("hide_press_button", script, [])
		call_macro("show_court_record_button", script, [])
		
func hide_arrows(script):
	call_macro("hide_court_record_button", script, [])
	call_macro("hide_present_button", script, [])
	call_macro("hide_press_button", script, [])
	
func get_speaking_char():
	var characters = get_objects(null, null, CHAR_GROUP)
	for character in characters:
		if character.script_name == main.stack.variables.get_string("_speaking", null):
			return [character]
	for character in characters:
		return [character]
	return []
	
# Save/Load
func save_scripts():
	var data = {
		"variables": main.stack.variables.store,
		"macros": main.stack.macros,
		"evidence_pages": main.stack.evidence_pages,
		"stack": []
	}
	for script in main.stack.scripts:
		var save_script = {
			"root_path": script.root_path,
			"filename": script.filename
		}
		data["stack"].append(save_script)
	var file = File.new()
	file.open("user://save.txt", File.WRITE)
	file.store_string(
		to_json(data)
	)
	file.close()
	
func _input(event):
	if event and event.is_action_pressed("quickload"):
		load_scripts()
	
func load_scripts():
	var file = File.new()
	var err = file.open("user://save.txt", File.READ)
	if err != OK:
		return false
	var json = file.get_as_text()
	var data = parse_json(json)
	file.close()
	
	clear_main_screen()
	main.stack.clear_scripts()
	main.stack.variables.store = data["variables"]
	main.stack.evidence_pages = data["evidence_pages"]
	main.stack.macros = data["macros"]
	
	for script_data in data["stack"]:
		main.stack.load_script(
			Filesystem.path_join(script_data["root_path"], script_data["filename"])
		)
		var script = main.stack.scripts[-1]
		#var script = load("WrightScript/WrightScript.gd").new()
		#script.main = main
		#main.stack.scripts.append(script)
		#script.root_path = script_data["root_path"]
		#script.filename = script_data["filename"]
		#script.lines = script_data["lines"]
		#script.labels = script_data["labels"]
		#script.line_num = script_data["line_num"]
		#script.line = script_data["line"]
	return true
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
	for command_file in generate_command_map():
		var extern = load(command_file).new(self)
		for command in get_call_methods(extern):
			external_commands[command] = extern

func call_command(command, script, arguments):
	command = value_replace(command)
	
	var args = []
	for arg in arguments:
		args.append(value_replace(arg))
	arguments = args

	if has_method("ws_"+command):
		return call("ws_"+command, script, arguments)

	if "ws_"+command in external_commands:
		var extern = external_commands["ws_"+command]
		return extern.callv("ws_"+command, [script, arguments])
	
	if command.begins_with("{") and command.ends_with("}"):
		return call_macro(command.substr(1,command.length()-2), script, arguments)
	
	if is_macro(command):
		return call_macro(command, script, arguments)
	return UNDEFINED
	
func is_macro(command):
	if command.begins_with("{") and command.ends_with("}"):
		return command.substr(1,command.length()-2)
	if main.stack.macros.has(command):
		return command
	return ""
	
# TODO - may need to support actually replacing macro text with the arguments passed, 
# but wont implement till we actually need to
func call_macro(command, script, arguments):
	command = is_macro(command)
	if not command:
		return
	var i = 1
	for arg in arguments:
		if "=" in arg:
			var spl = arg.split("=")
			main.stack.variables.set_val(
				spl[0].strip_edges(),
				spl[1].strip_edges())
		else:
			main.stack.variables.set_val(str(i), arg)
		i += 1
	var script_lines = main.stack.macros[command]
	var new_script = main.stack.add_script(PoolStringArray(script_lines).join("\n"))
	new_script.root_path = script.root_path
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
