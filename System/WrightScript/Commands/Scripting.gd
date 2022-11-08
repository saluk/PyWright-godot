extends Reference

var main
var command

func _init(commands):
	main = commands.main
	command = commands


func ws_debug(script, arguments):
	return Commands.DEBUG

func ws_script(script, arguments, script_text=null):
	if Commands.keywords(arguments).get("label",null):
		# TODO jump to label when loading script
		print("DO SOMETHING WITH SCRIPTS LOADING A LABEL")
	if not "noclear" in arguments:
		Commands.clear_main_screen()
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
	Commands.save_scripts()
	return Commands.YIELD
	
