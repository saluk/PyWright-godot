extends Reference

var main

func _init(commands):
	main = commands.main
	
func gui_button(script, arguments):
	var macroname = arguments.pop_front()
	var spl = Commands.keywords(arguments, true)
	var kw = spl[0]
	var args:Array = spl[1]
	for single in ["try_bottom", "hold"]:
		while single in args:
			args.erase(single)
	var text = Commands.join(args)
	if text:
		arguments.append("button_text="+text)
	var graphic = kw.get("graphic", "")
	var graphichigh = kw.get("graphichigh", "")
	var button
	button = Commands.create_object(
		script, 
		"gui", 
		"res://System/UI/IButton.gd", 
		[Commands.SPRITE_GROUP],
		arguments
	)
	if not button:
		main.log_error("Couldn't create button")
	button.menu = self
	button.button_name = macroname

class GuiWait:
	var wait_signal = "DONE_WAITING"
	signal DONE_WAITING
	func _init(script):
		script.connect("GOTO_RESULT", self, "finish")
	func finish():
		emit_signal("DONE_WAITING")
# TODO make macro script that executes while waiting
func gui_wait(script, arguments):
	return GuiWait.new(script)
	
# TODO IMPLEMENT
func gui_back(script, arguments):
	pass
	
# TODO IMPLEMENT
func gui_input(script, arguments):
	pass

func ws_gui(script, arguments):
	if not main.get_tree():
		return
	var guitype = arguments.pop_front()
	if not has_method("gui_"+guitype.to_lower()):
		return main.log_error("Invalid type for gui - "+guitype)
	return callv("gui_"+guitype.to_lower(), [script, arguments])

func click_option(option):
	Commands.macro_or_label(option, main.stack.scripts[-1], [])
