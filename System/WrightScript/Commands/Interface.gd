extends Reference

var main

# TODO might not be the best place for this kind of temporary global variable but it works
var next_examine := {}

func _init(commands):
	main = commands.main

func ws_menu(script, arguments):
	var menu_name = arguments[0]
	var kw = Commands.keywords(arguments)
	var menu = ws_localmenu(script, arguments)
	menu.scene_name = menu_name
	for option in ["examine", "move", "talk", "present"]:
		print(kw)
		print(script.has_script(menu_name+"."+option))
		if (
			(not kw and script.has_script(menu_name+"."+option))
			or option in kw
		):
			menu.enabled_options.append(option)
	# As we end the current script, the scene is changing
	main.stack.run_macro_set(main.stack.run_macros_on_scene_change)
	script.end()
	return menu

func ws_localmenu(script, arguments):
	var menu_name = arguments[0]
	var kw = Commands.keywords(arguments)
	#if kw.get("bg","NOT SET") == "NOT SET":
	#	Commands.call_command("bg", script, ["main2", "y=192", "stack"])
	if "bg" in kw:
		main.stack.variables.set_val("script._override_bg", kw["bg"])
	var menu = ObjectFactory.create_from_template(
		script,
		"investigate",
		{}
	)
	for option in ["examine", "move", "talk", "present"]:
		if WSExpression.string_to_bool(kw.get(option, "false")):
			menu.enabled_options.append(option)
	menu.fail_label = kw.get("fail", "none")
	Commands.call_macro("show_court_record_button", script, [])
	return menu
	
func ws_lmenu(script, arguments):
	return ws_localmenu(script, arguments)

# Note - we handle region definitions in a bit of a weird way
#  - in pywright, we create the examine interface, and then 
#    step through the script adding regions to the object
#  - no other object functions this way in wrightscript
#  - From now on, we will add a command showexamine, similar to showlist
#  - the region commands will buffer the regions and then they will be
#    read by the examine object created by showexamine
#  - For backwards compatibility:
#      - showexamine will be added to scripts when preprocessing in the appropriate place
#      - future wrightscript versions may require showexamine to be in the script
func ws_examine(script, arguments):
	next_examine = {
		"hidden": false,
		"regions": [],
		"fail": "none"
	}
	next_examine["hidden"] = "hide" in arguments
	next_examine["fail"] = Commands.keywords(arguments).get("fail", "none")
	
func ws_region(script, arguments):
	next_examine["regions"].append(arguments)
	
# NEW
func ws_showexamine(script, arguments):
	if not next_examine:
		GlobalErrors.log_error("Examine must first be created with examine and region commands before it can be shown.", {"script": script})
		return
	var examine_menu = ObjectFactory.create_from_template(
		script,
		"examine_menu",
		{},
		arguments
	)
	examine_menu.position = Vector2(0, 192)
	for region_args in next_examine["regions"]:
		examine_menu.add_region_args(region_args)
	if next_examine["hidden"]:
		examine_menu.reveal_regions = false
		examine_menu.allow_back_button = false
		# TODO probably need a backwards compatible way to disable the backbutton while still showing regions
	examine_menu.fail = next_examine["fail"]
	examine_menu.update()
	next_examine = {}
	return examine_menu
	
func ws_region3d(script, arguments):
	return Commands.NOTIMPLEMENTED
	
func ws_examine3d(script, arguments):
	return Commands.NOTIMPLEMENTED

func ws_list(script, arguments):
	Commands.delete_object_group(Commands.LIST_GROUP)
	var noback = "noback" in arguments
	if noback:
		arguments.erase("noback")
	var tag
	if arguments:
		tag = arguments[0]
	var list_menu = ObjectFactory.create_from_template(
		script,
		"list_menu"
	)
	list_menu.tag = tag
	list_menu.position = Vector2(0, 192)
	list_menu.allow_back_button = true
	if noback or not main.stack.variables.get_truth("_list_back_button"):
		list_menu.allow_back_button = false
	list_menu.update()
	
func ws_li(script, arguments):
	var list_menu = main.get_tree().get_nodes_in_group(Commands.LIST_GROUP)
	if not list_menu:
		GlobalErrors.log_error("Couldn't find list menu to add item to", {"script": script})
		return
	list_menu = list_menu[0]
	var result = Commands.keywords(arguments).get("result", null)
	if result:
		arguments.erase("result="+result)
	var text = Commands.join(arguments)
	if not result:
		result = text
	list_menu.add_item(text, result)

# Sets checkmark details for most recent list item - will enable the checkmark no matter
# what is stored in variables regarding whether the player has seen the item or not
# Can be used to show a psyche lock, or used to mark an item as seen even if the text changes
func ws_lo(script, arguments):
	var kw = Commands.keywords(arguments)
	var list_menu = main.get_tree().get_nodes_in_group(Commands.LIST_GROUP)
	if not list_menu:
		GlobalErrors.log_error("Couldn't find list menu to set list options for", {"script": script})
		return
	list_menu[0].set_list_item_options(kw)
	
func ws_showlist(script, arguments):
	var list_menu = main.get_tree().get_nodes_in_group(Commands.LIST_GROUP)
	if not list_menu:
		GlobalErrors.log_error("Couldn't find list menu to show", {"script": script})
		return
	list_menu[0].update()
	return list_menu[0]

func ws_forgetlist(script, arguments):
	var tag = arguments.pop_front()
	if main.stack.variables.get_string("_pwlist_checked_items_"+tag, ""):
		main.stack.variables.del_val("_pwlist_checked_items_"+tag)

func ws_forgetlistitem(script, arguments):
	var tag = arguments.pop_front()
	var item = PoolStringArray(arguments).join(" ")
	var items = Array(main.stack.variables.get_string("_pwlist_checked_items_"+tag, "").split(";;"))
	if items:
		if item in items:
			items.erase(item)
		main.stack.variables.set_val("_pwlist_checked_items_"+tag, PoolStringArray(items).join(";;"))

# TODO IMPLEMENT
# still needs graphics
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
			if next_file_name.begins_with("."):
				next_file_name = case_listing.get_next()
				continue
			if next_file_name in ["art", "music", "sfx", "fonts", "movies"]:
				next_file_name = case_listing.get_next()
				continue
			if case_listing.current_is_dir():
				cases.append(next_file_name)
			next_file_name = case_listing.get_next()
		cases.sort()
	var casemenu = load("res://System/UI/CaseMenu.tscn").instance()
	casemenu.cases = cases
	casemenu.wrightscript = script
	script.screen.clear()
	script.screen.add_child(casemenu)
	return casemenu

# TODO IMPLEMENT
#    @category([COMBINED("destination","The destination label to move to"),
#                    KEYWORD("fail","A label to jump to if the destination can't be found")],type="logic")
#    @category([VALUE("folder","List all games in this folder, relative to current game directory")],type="gameflow")
#    def _gamemenu(self,command,folder,*args):
#        """Can be used to list games in a folder"""
#        cm = assets.choose_game()
#        cm.pause = True
#        cm.list_games(assets.game+"/"+folder)
#        if "close" in args:
#            cm.close_button(True)
#        self.add_object(cm,True)
#        self._gui("gui","Wait")
#        return True
func ws_gamemenu(script, arguments):
	pass
