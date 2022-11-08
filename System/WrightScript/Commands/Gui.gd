extends Reference

var main

func _init(commands):
	main = commands.main
	
func gui_button(script, arguments):
	var macroname = arguments.pop_front()
	var spl = Commands.keywords(arguments, true)
	var kw = spl[0]
	var args = spl[1]
	var text = Commands.join(args)
	var button = Commands.create_object(
		script, 
		"gui", 
		"res://System/UI/IButton.gd", 
		[Commands.SPRITE_GROUP],
		arguments
	)
	button.menu = self
	button.button_name = macroname
	
# TODO IMPLEMENT
func gui_back(script, arguments):
	pass
	
# TODO IMPLEMENT
func gui_input(script, arguments):
	pass
	
# TODO IMPLEMENT
func gui_wait(script, arguments):
	pass

func ws_gui(script, arguments):
	if not main.get_tree():
		return
	var guitype = arguments.pop_front()
	if not has_method("gui_"+guitype.to_lower()):
		return main.log_error("Invalid type for gui - "+guitype)
	return callv("gui_"+guitype.to_lower(), [script, arguments])

func click_option(option):
	Commands.call_macro(Commands.is_macro(option), main.stack.scripts[-1], [])
