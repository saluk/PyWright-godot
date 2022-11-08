extends Reference

var main

func _init(commands):
	main = commands.main

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
	
# TODO IMPLEMENT
#@category([KEYWORD('examine','whether to show the examine button','false'),
#    KEYWORD('talk','whether to show the talk button','false'),
#    KEYWORD('present','whether to show the present button','false'),
#    KEYWORD('move','whether to show the move button','false'),
#    KEYWORD('fail','label to jump to if the label for an action was not found','none')],type="interface")
#    def _localmenu(self,command,*args):
#        """Show an investigation menu of options. Should be run after the background of a scene is loaded. When an option
#        is clicked, PyWright will jump to the label of the action, such as "label examine" or "label talk". You can control which options
#        are shown through the keywords described."""
#        for o in self.obs:
#            if o.__class__ in delete_on_menu:
#                o.delete()
#        m = menu()
#        for a in args:
#            if "=" in a:
#                arg,val = a.split("=")
#                if arg=="fail":
#                    m.fail = val
#                elif vtrue(val):
#                    m.addm(arg)
#        m.open_script = False
#        self.add_object(m,True)
#        m.init_normal()
#        return True
func ws_localmenu(script, arguments):
	pass

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
	
func ws_region3d(script, arguments):
	return Commands.NOTIMPLEMENTED
	
func ws_examine3d(script, arguments):
	return Commands.NOTIMPLEMENTED

# TODO support noback
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
	var text = Commands.join(arguments)
	if not result:
		result = text
	list_menu.add_item(text, result)
	
# TODO IMPLEMENT
# Sets checkmark details
#    @category([KEYWORD('checkmark','image used for checkmark'),
#    KEYWORD('check_x','x position of check image'),
#    KEYWORD('check_y','y position of check image')],type="interface")
#    def _lo(self,command,*keys):
#        for o in self.obs:
#            if isinstance(o,listmenu):
#                for k in keys:
#                    key,value = k.split("=")
#                    if key in ["checkmark","check_x","check_y","on_select"]:
#                        o.options[-1][key]=value
func ws_lo(script, arguments):
	pass
	
func ws_showlist(script, arguments):
	var list_menu = main.get_tree().get_nodes_in_group(Commands.LIST_GROUP)
	if not list_menu:
		main.log_error("Couldn't find list menu to show")
		return
	return list_menu[0]
	
# TODO IMPLEMENT
#    @category([VALUE("tag","list tag to forget")],type="gameflow")
#    def _forgetlist(self,command,tag):
#        """Clears the memory of which options player has chosen from a specific list. Normally, chosen options from a list
#        will be shown with a checkmark to remind the player which options they have tried, and which ones are new. You
#        can make all the options for a list not show checkmarks by clearing the memory."""
#        if tag in assets.lists:
#            del assets.lists[tag]
func ws_forgetlist(script, arguments):
	pass
#    @category([VALUE("tag","list to forget item from"),COMBINED("option","option from list to forget state of")],type="gameflow")
#    def _forgetlistitem(self,command,tag,*item):
#        """Forget checkmark status of a specific option from a specific list."""
#        item = " ".join(item)
#        if tag in assets.lists:
#            if item in assets.lists[tag]:
#                del assets.lists[tag][item]
func ws_forgetlistitem(script, arguments):
	pass

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
			if not next_file_name in [".", ".."]:
				cases.append(next_file_name)
			next_file_name = case_listing.get_next()
	var casemenu = load("res://System/UI/CaseMenu.tscn").instance()
	casemenu.cases = cases
	casemenu.wrightscript = script
	Commands.clear_main_screen()
	Commands.main_screen.add_child(casemenu)
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
