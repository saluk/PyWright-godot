extends Reference

var main
var command

func _init(commands):
	main = commands.main
	command = commands

func ws_menu(script, arguments):
	var menu_name = arguments[0]
	var kw = Commands.keywords(arguments)
	var menu = Commands.create_object(
		script,
		"menu",
		"res://System/UI/Investigate.gd",
		[Commands.SPRITE_GROUP],
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

func ws_examine(script, arguments):
	var hide = "hide" in arguments
	var fail = Commands.keywords(arguments).get("fail", "none")
	var examine_menu = Commands.create_object(
		script,
		"examine_menu",
		"res://System/UI/Examine.gd",
		[Commands.SPRITE_GROUP],
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

func ws_list(script, arguments):
	main.get_tree().call_group(Commands.LIST_GROUP, "queue_free")
	var noback = "noback" in arguments
	if noback:
		arguments.erase("noback")
	var tag
	if arguments:
		tag = arguments[0]
	var list_menu = Commands.create_object(
		script,
		"listmenu",
		"res://System/UI/PWList.gd",
		[Commands.SPRITE_GROUP, Commands.LIST_GROUP],
		arguments
	)
	
func ws_li(script, arguments):
	var list_menu = main.get_tree().get_nodes_in_group(Commands.LIST_GROUP)
	if not list_menu:
		main.log_error("Couldn't find list menu to add item to")
		return
	list_menu = list_menu[0]
	var result = Commands.keywords(arguments).get("result", null)
	if result:
		arguments.erase("result="+result)
	var text = PoolStringArray(arguments).join(" ")
	if not result:
		result = text
	list_menu.add_item(text, result)
	
func ws_showlist(script, arguments):
	var list_menu = main.get_tree().get_nodes_in_group(Commands.LIST_GROUP)
	if not list_menu:
		main.log_error("Couldn't find list menu to show")
		return
	return list_menu[0]

func ws_casemenu(script, arguments):
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
	var casemenu = load("res://System/UI/CaseMenu.tscn").instance()
	casemenu.cases = cases
	casemenu.wrightscript = script
	Commands.clear_main_screen()
	Commands.main_screen.add_child(casemenu)
	return casemenu
