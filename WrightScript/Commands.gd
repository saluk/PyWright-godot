extends Node

var main:Node
var main_screen:Node
var z:int

var textboxScene = preload("res://UI/Textbox.tscn")

var last_object

export var PAUSE_MULTIPLIER = 0.10

enum {
	YIELD,
	END,
	UNDEFINED,
	DEBUG
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

func create_textbox(line) -> Node:
	var l = textboxScene.instance()
	l.main = main
	l.text_to_print = line
	main_screen.add_child(l)
	return l
	
func create_object(script, command, class_path, groups, arguments=[]):
	var object:Node = load(class_path).new()
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
	main_screen.add_child(object)
	object.name = object.script_name
	return object
	
func refresh_arrows(script):
	get_tree().call_group(ARROW_GROUP, "queue_free")
	var arrow_class = "res://UI/IArrow.gd"
	if script.is_inside_cross():
		arrow_class = "res://UI/IArrowCross.gd"
	var arrow = create_object(
		script,
		"uglyarrow",
		arrow_class,
		[ARROW_GROUP, SPRITE_GROUP],
		[]
	)
	print(script.get_prev_statement())
	if script.get_prev_statement() == null and "left" in arrow:
		arrow.left.get_children()[1].visible = false
		arrow.left.get_children()[2].visible = false
	
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
	main.blockers = []
	main.stack.variables.store = data["variables"]
	main.stack.evidence_pages = data["evidence_pages"]
	main.stack.macros = data["macros"]
	
	for script_data in data["stack"]:
		main.stack.load_script(script_data["root_path"]+"/"+script_data["filename"])
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

func index_commands():
	external_commands["scroll.gd"] = load("res://WrightScript/Commands/Scroll.gd")

func call_command(command, script, arguments):
	command = value_replace(command)
	
	var args = []
	for arg in arguments:
		args.append(value_replace(arg))
	arguments = args

	if has_method("call_"+command):
		return call("call_"+command, script, arguments)

	if command+".gd" in external_commands:
		return external_commands[command+".gd"].call_func(script, arguments)
		
	if main.stack.macros.has(command):
		return call_macro(command, script, arguments)
	return UNDEFINED
	
func call_macro(command, script, arguments):
	var i = 1
	for arg in arguments:
		main.stack.variables.set_val(str(i), arg)
		i += 1
	var script_lines = main.stack.macros[command]
	var new_script = main.stack.add_script(PoolStringArray(script_lines).join("\n"))
	new_script.root_path = script.root_path
	new_script.filename = "{"+command+"}"
	return YIELD
	
# Script commands

func call_text(script, arguments):
	var text = PoolStringArray(arguments).join(" ")
	text = text.substr(1,text.length()-2)
	return Commands.create_textbox(text)
	
func call_cross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("_statement_line_num", "")
	main.stack.variables.set_val("_cross_line_num", script.executed_line_num)
	
func call_endcross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("_statement_line_num", "")
	main.stack.variables.set_val("_cross_line_num", "")
	
func call_statement(script, arguments):
	main.stack.variables.set_val("_statement", arguments[0])
	main.stack.variables.set_val("_statement_line_num", script.executed_line_num)

func call_clear(script, arguments):
	clear_main_screen()
	
func call_pause(script, arguments):
	# Need to add priority
	if get_tree():
		return get_tree().create_timer(int(arguments[0])/60.0 * PAUSE_MULTIPLIER)
	
func call_nt(script, arguments):
	var nametag = PoolStringArray(arguments).join(" ")
	main.stack.variables.set_val("_speaking", "")    		  # Set no character as speaking
	main.stack.variables.set_val("_speaking_name", nametag)   # Next character will have this name
	
func call_mus(script, arguments):
	MusicPlayer.play_music(
		Filesystem.path_join("music",PoolStringArray(arguments).join(" ")), 
		script.root_path
	)
	
func call_fade(script, arguments):
	# TODO IMPLEMENT
	pass
	
func call_sfx(script, arguments):
	SoundPlayer.play_sound(
		Filesystem.path_join("sfx", PoolStringArray(arguments).join(" ")), 
		script.root_path
	)

func call_set(script, arguments):
	var key = arguments.pop_front()
	var value = PoolStringArray(arguments).join(" ")
	main.stack.variables.set_val(key, value)
	
func call_delete(script, arguments):
	var name = keywords(arguments).get("name", null)
	if name != null:
		main_screen.sort_children()
		var children = main_screen.get_children()
		for i in range(children.size()):
			if children[-i].script_name == name:
				children[-i].queue_free()
				children[-i].name = "DELETED_"+children[-1].name
				
func call_obj(script, arguments):
	if not get_tree():
		return
	var obj:Node = create_object(
		script,
		"graphic",
		"res://Graphics/PWSprite.gd",
		[SPRITE_GROUP],
		arguments
	)
	
func call_bg(script, arguments):
	if not get_tree():
		return
	if not "stack" in arguments:
		get_tree().call_group(CLEAR_GROUP, "queue_free")
	var bg:Node = create_object(script, "bg", "res://Graphics/PWSprite.gd", [SPRITE_GROUP, BG_GROUP, CLEAR_GROUP], arguments)
	
func call_fg(script, arguments):
	if not get_tree():
		return
	var fg:Node = create_object(script, "fg", "res://Graphics/PWSprite.gd", [SPRITE_GROUP, FG_GROUP, CLEAR_GROUP], arguments)

func call_char(script, arguments):
	if not get_tree():
		return
	# If we don't "stack" then delete existing character
	if not "stack" in arguments and not "hide" in arguments:
		get_tree().call_group(CHAR_GROUP, "queue_free")
	var character = create_object(
		script,
		"portrait", 
		"res://Graphics/PWChar.gd",
		[CHAR_GROUP, SPRITE_GROUP, CLEAR_GROUP],
		arguments
	)
	if "hide" in arguments:
		character.visible = false
		get_tree().call_group(HIDDEN_CHAR_GROUP, "queue_free")
		character.add_to_group(HIDDEN_CHAR_GROUP)
	main.stack.variables.set_val("_speaking", character.char_name)
	
func call_emo(script, arguments):
	var kw = keywords(arguments, true)
	arguments = kw[1]
	kw = kw[0]
	var name = kw.get("name", null)
	var mode = kw.get("mode", null)
	var emotion = ""
	if arguments.size() > 0:
		emotion = arguments[0]
	var characters
	if not name:
		characters = get_speaking_char()
	else:
		characters = get_objects(name, false, CHAR_GROUP)
	if characters:
		characters[0].load_emotion(emotion)
		if mode:
			characters[0].play_state(mode)

func call_ev(script, arguments):
	var ev = create_object(
		script,
		"evidence",
		"res://Graphics/PWEvidence.gd",
		[SPRITE_GROUP, CLEAR_GROUP],
		arguments
	)

func call_addev(script, arguments):
	#tag, [page]
	#if tag ends with $ page = profiles
	#otherwise page defaults to evidence
	var tag:String = arguments[0]
	var page = "evidence"
	if tag.ends_with("$"):
		# TODO make sure the name is set up correctly
		page = "profiles"
	if arguments.size()>1:
		page = arguments[1]
	var page_arr = main.stack.evidence_pages.get(page, [])
	if not tag in page_arr:
		page_arr.append(tag)
		main.stack.evidence_pages[page] = page_arr
		
func call_delev(script, arguments):
	for page in main.stack.evidence_pages:
		var page_array = main.stack.evidence_pages[page]
		if arguments[0] in page_array:
			page_array.erase(arguments[0])

func call_script(script, arguments, script_text=null):
	if keywords(arguments).get("label",null):
		# TODO jump to label when loading script
		print("DO SOMETHING WITH SCRIPTS LOADING A LABEL")
	if not "noclear" in arguments:
		clear_main_screen()
		pass
	else:
		arguments.erase("noclear")
	var path = PoolStringArray(arguments).join(" ")
	if script_text:
		main.stack.add_script(script_text)
	else:
		path = script.has_script(path)
		if path:
			print("loading path:", path)
			main.stack.load_script(path)
	if not "stack" in arguments:
		main.stack.remove_script(script)
	save_scripts()
	return YIELD

func call_menu(script, arguments):
	var menu_name = arguments[0]
	var kw = keywords(arguments)
	var menu = create_object(
		script,
		"menu",
		"res://UI/Investigate.gd",
		[SPRITE_GROUP],
		["name=invest_menu"])
	menu.scene_name = menu_name
	for option in ["examine", "move", "talk", "present"]:
		print(kw)
		print(script.has_script(menu_name+"."+option))
		if (
			(not kw and script.has_script(menu_name+"."+option))
			or option in kw
		):
			menu.add_option(option)
	script.end()
	return menu

func call_examine(script, arguments):
	var hide = "hide" in arguments
	var fail = keywords(arguments).get("fail", "none")
	var examine_menu = create_object(
		script,
		"examine_menu",
		"res://UI/Examine.gd",
		[SPRITE_GROUP],
		arguments
	)
	if hide:
		examine_menu.reveal_regions = false
		examine_menu.allow_back_button = false
	examine_menu.fail = fail
	var offset = 0
	while 1:
		var line = script.get_next_line(offset)
		if line.begins_with("region"):
			examine_menu.add_region_text(line)
		else:
			script.goto_line_number(offset, true)
			break
		offset += 1
	return examine_menu
	
func call_debug(script, arguments):
	return DEBUG

func call_list(script, arguments):
	get_tree().call_group(LIST_GROUP, "queue_free")
	var noback = "noback" in arguments
	if noback:
		arguments.erase("noback")
	var tag
	if arguments:
		tag = arguments[0]
	var list_menu = create_object(
		script,
		"listmenu",
		"res://UI/PWList.gd",
		[SPRITE_GROUP, LIST_GROUP],
		arguments
	)
	
func call_li(script, arguments):
	var list_menu = get_tree().get_nodes_in_group(LIST_GROUP)
	if not list_menu:
		main.log_error("Couldn't find list menu to add item to")
		return
	list_menu = list_menu[0]
	var result = keywords(arguments).get("result", null)
	if result:
		arguments.erase("result="+result)
	var text = PoolStringArray(arguments).join(" ")
	if not result:
		result = text
	list_menu.add_item(text, result)
	
func call_showlist(script, arguments):
	var list_menu = get_tree().get_nodes_in_group(LIST_GROUP)
	if not list_menu:
		main.log_error("Couldn't find list menu to show")
		return
	return list_menu[0]

func call_goto(script, arguments):
	var fail = keywords(arguments).get("fail", null)
	script.goto_label(arguments[0], fail)

func call_label(script, arguments):
	main.stack.variables.set_val("_lastlabel", arguments[0])

func call_flag(script, arguments:Array, return_true=true):
	var label = arguments.pop_back()
	var fail = keywords([label]).get("fail", null)
	if fail:
		label = arguments.pop_back()
	if label.ends_with("?"):
		arguments.append(label.substr(0, label.length()-1))
		label = "?"
	var mode = 0
	var line = ""
	for word in arguments:
		if mode == 0:
			line += main.stack.variables.get_truth_string(word)
		elif mode == 1:
			if word == "AND":
				line += " and "
			elif word == "OR":
				line += " or "
			else:
				print("flag logic has command that's not AND or OR")
				return UNDEFINED
		mode = 1-mode
	var expression = Expression.new()
	expression.parse(line)
	var result = expression.execute()
	if result == return_true:
		call_goto(script, [label])
	if fail:
		call_goto(script, [fail])

func call_setflag(script, arguments):
	main.stack.variables.set_val(arguments[0], "true")
	
func call_delflag(script, arguments):
	if arguments[0] in main.stack.variables:
		main.stack.variables.erase(arguments[0])
		
func call_noflag(script, arguments):
	# NOT YET IMPLEMENTED
	return call_flag(
		script, arguments, false
	)

func call_present(script, arguments):
	var cr = create_object(
		script, 
		"evidence_menu",
		"res://UI/CourtRecord.gd",
		[SPRITE_GROUP],
		arguments
	)
	return cr

# TODO should fade
func call_grey(script, arguments):
	var name = keywords(arguments).get("name", null)
	var value = keywords(arguments).get("value", 1)
	var obs
	if name:
		obs = get_objects(name, null)
	else:
		obs = get_objects(null, null)
	for o in obs:
		if o.has_method("set_grey"):
			o.set_grey(value)
			
func call_penalty(script, arguments):
	var variable = keywords(arguments).get("variable", "penalty")
	var threat = keywords(arguments).get("threat", null)
	var delay = keywords(arguments).get("delay", null)
	var damage_amount
	if arguments:
		if "=" in arguments[0]:
			damage_amount = null
		else:
			damage_amount = arguments[0]
	if delay==null:
		delay = 50
		if not (damage_amount or threat):
			delay = 0
	get_tree().call_group(PENALTY_GROUP, "queue_free")
	var penalty = create_object(script, "penalty", "res://UI/Penalty.gd", 
		[SPRITE_GROUP, PENALTY_GROUP], ["name=penalty"])
	penalty.variable = variable
	if threat:
		penalty.threat_amount = int(threat)
	penalty.delay = int(delay)
	penalty.start_value = main.stack.variables.get_int(variable, 100)
	if damage_amount and damage_amount[0] == "-":
		penalty.end_value = penalty.start_value - int(damage_amount.substr(1))
	elif damage_amount and damage_amount[0] == "+":
		penalty.end_value = penalty.start_value + int(damage_amount.substr(1))
	elif damage_amount:
		penalty.end_value = int(damage_amount)
	else:
		penalty.end_value = penalty.start_value
	penalty.begin()
	if penalty.delay > 0:
		return penalty

# NOTE:
# If you use ? AND fail, a success will send the script to the next line, 
# while a failure will to to the fail label. It's valid but a bit weird.
# You should ONLY use one of (?) or (label + fail=)
func call_is(script, arguments):
	var removed = keywords(arguments, true)
	var keywords = removed[0]
	var fail = keywords.get("fail", null)
	arguments = removed[1]
	var label
	if arguments[-1].ends_with("?"):
		arguments[-1] = arguments[-1].substr(0, arguments[-1].length()-1)
		label = "?"
	else:
		label = arguments.pop_back()
	if WSExpression.EVAL_SIMPLE(PoolStringArray(arguments).join(" ")):
		script.succeed(label)
	else:
		script.fail(label, fail)
		
func call_isnot(script, arguments):
	var removed = keywords(arguments, true)
	var keywords = removed[0]
	var fail = keywords.get("fail", null)
	arguments = removed[1]
	var label
	if arguments[-1].ends_with("?"):
		arguments[-1] = arguments[-1].substr(0, arguments[-1].length()-1)
		label = "?"
	else:
		label = arguments.pop_back()
	var truth = WSExpression.EVAL_EXPR(
		WSExpression.SIMPLE_TO_EXPR(
			PoolStringArray(arguments).join(" ")
		)
	)
	if not WSExpression.string_to_bool(truth):
		script.succeed(label)
	else:
		script.fail(label, fail)

# TODO actually show casemenu instead of just choosing first case
func call_casemenu(script, arguments):
	var cases = []
	var case_num = 1
	var case = main.stack.variables.get_string("_case_"+str(case_num), null)
	while case:
		cases.append(case)
		case_num += 1
		case = main.stack.variables.get_string("_case_"+str(case_num), null)
	if not cases:
		var case_listing = Directory.new()
		if case_listing.open(script.root_path) != OK:
			return null
		case_listing.list_dir_begin()
		var next_file_name = case_listing.get_next()
		while next_file_name != "":
			if not next_file_name in [".", ".."]:
				cases.append(next_file_name)
			next_file_name = case_listing.get_next()
	var casemenu = load("res://UI/CaseMenu.tscn").instance()
	casemenu.cases = cases
	casemenu.wrightscript = script
	clear_main_screen()
	main_screen.add_child(casemenu)
	return casemenu

func call_draw_off(script, arguments):
	pass # No op, old pywright needed the user to determine when to pause to load many graphics
	
func call_draw_on(script, arguments):
	pass

# Godot specific control commands

func call_godotdebug(script, arguments):
	# You can use this command to enter the godot debugger
	pass
