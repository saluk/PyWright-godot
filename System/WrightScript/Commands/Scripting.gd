extends Reference

var main

func _init(commands):
	main = commands.main

# TODO IMPLEMENT
# (should set debug mode on
#         """Used to turn debug mode on or off. Debug mode will print more errors to the screen,
#        and allow you to skip through any text."""
#        if value.lower() in ["on","1","true"]:
#            assets.variables["_debug"] = "on"
#        else:
#            assets.variables["_debug"] = "off"
func ws_debug(script, arguments):
	print(" OBJECT LIST ")
	for object in ScreenManager.get_objects():
		var script_name = ""
		if object.get_script():
			script_name = object.get_script().resource_name
		var id_name = "(None)"
		if "script_name" in object:
			id_name = object.script_name
		var s = " OBJECT LIST - class:" + script_name + "  id_name:"+id_name+"  id:"+object.to_string()
		if "position" in object:
			s += "  pos:"+str(object.position)
		if "modulate" in object:
			s += "  fade:"+str(object.modulate)
		print(s)
	print(" END OBJECT LIST ")
	return Commands.DEBUG

func ws_print(script, arguments):
	print("OUTPUT: ", Commands.join(arguments))

# No need to implement
func ws_step(script, arguments):
	return Commands.NOTIMPLEMENTED

func ws_goto(script, arguments):
	var fail = Commands.keywords(arguments).get("fail", null)
	return script.goto_label(arguments[0], fail)

func ws_top(script, arguments):
	script.goto_line_number(0)

func ws_label(script, arguments):
	StandardVar.LASTLABEL.store(arguments[0], script.variables)

# TODO
# need to verify some of the specifics. mainly why did we need parent?
#@category(
#    [VALUE('script_name',"name of the new script to load. Will look for 'script_name.script.txt', 'script_name.txt', or simple 'script_name', in the current case folder."),
#KEYWORD('label','A label in the loading script to jump to after it loads.','Execution starts at the top of the script instead of a label'),
#TOKEN('noclear','If this token is present, all the objects that exist will carry over into the new script.','Otherwise, the scene will be cleared.'),
#TOKEN('stack','Puts the new script on top of the current script, instead of replacing it. When the new script exits, the current script will resume following this "script" command.','The new script will replace the current script.')],
#type="gameflow")
#    def _script(self,command,scriptname,*args):
#        """Stops or pauses execution of the current script and loads a new script. If the token stack is included, then the current script will
#resume when the new script exits, otherwise, the current script will vanish."""
#        print "RUNNING SCRIPT:",scriptname
#        print assets.stack
#        label = None
#        for a in args:
#            if a.startswith("label="):
#                label = a.split("=",1)[1]
#        if "noclear" not in args:
#            for o in self.obs:
#                o.delete()
#        name = scriptname+".script"
#        try:
#            assets.open_script(name,False,".txt")
#        except file_error:
#            name = scriptname
#        if "stack" in args:
#            assets.addscene(name)
#        else:
#            p = self.parent
#            self.init(name)
#            self.parent = p
#        print "New stack:",assets.stack
#        while assets.cur_script.parent:
#            parent = assets.cur_script.parent
#            assets.cur_script.parent = parent.parent
#            #FIXME - How can we be removing a parent that's not there?
#            if parent in assets.stack:
#                assets.stack.remove(parent)
#        if label:
#            self.goto_result(label,backup=None)
#        print "Stack after clean up:",assets.stack
#        print "cur script",assets.cur_script
#        print "buildmode",assets.cur_script.buildmode
#        print "SCRIPT DEFAULTS"
#        self.execute_macro("defaults")
func ws_script(script, arguments, script_text=null):
	var args = Commands.keywords(arguments, true)
	var label = args[0].get("label",null)
	arguments = args[1]

	var new_screen = false
	var replace_script = true

	if "stack" in arguments:
		new_screen = true
		replace_script = false
		arguments.erase("stack")
	if "return" in arguments:
		new_screen = false
		replace_script = false
		arguments.erase("return")

	if replace_script:
		main.stack.clear_scripts()

	if not "noclear" in arguments:
		script.screen.clear()
	else:
		arguments.erase("noclear")
	var path = Commands.join(arguments)
	var scr
	if script_text:
		scr = main.stack.add_script(script_text, script.root_path)
	else:
		path = script.has_script(path)
		if path:
			print("loading path:", path)
			scr = main.stack.load_script(path)
		else:
			return
	if new_screen:
		scr.screen = ScreenManager.add_screen()
	else:
		scr.screen = script.screen
	if scr and label:
		scr.goto_label(label)
	main.stack.run_macro_set(main.stack.run_macros_on_scene_change)
	return Commands.YIELD

# TODO IMPLEMENT
#    @category([VALUE("game","Path to game. Should be from the root, i.e. games/mygame or games/mygame/mycase"),
#                    VALUE("script","Script to look for in the game folder to run first","intro")],type="gameflow")
func ws_game(script, arguments):
	pass

func ws_endscript(script, arguments):
	script.end()
	return Commands.NEXTLINE

func ws_exit(script, arguments):
	return ws_endscript(script, arguments)

# FIXME IMPLEMENT
# we should detect any click anywhere or the enter key
func ws_waitenter(script, arguments):
	pass

# FIXME implement - not hard
func ws_savegame(script, arguments):
	return Commands.NOTIMPLEMENTED

func ws_loadgame(script, arguments):
	return Commands.NOTIMPLEMENTED

func ws_screenshot(script, arguments):
	return Commands.NOTIMPLEMENTED
