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
	var template = ObjectFactory.get_template("button")
	template["sprites"]["default"]["path"] = "art/{base}.png".format({"base": graphic})
	if graphichigh:
		template["sprites"]["highlight"]["path"] = "art/{base}.png".format({"base": graphichigh})
	else:
		template["sprites"].erase("highlight")
	template["click_macro"] = macroname
	var button
	button = ObjectFactory.create_from_template(
		script,
		template,
		{},
		arguments
	)
	if not button:
		GlobalErrors.log_error("Couldn't create button", {"script": script})

class GuiWait:
	var wait_signal = "DONE_WAITING"
	signal DONE_WAITING
	func _init(script):
		script.connect("GOTO_RESULT", self, "finish")
		Commands.connect("button_clicked", self, "button_finished")
	func finish():
		emit_signal("DONE_WAITING")
	func button_finished(button):
		finish()
# TODO make macro script that executes while waiting
func gui_wait(script, arguments):
	return GuiWait.new(script)
	
func gui_back(script, arguments):
	var macroname = "{delete_gui_back}"
	var template = ObjectFactory.get_template("button")
	template["click_macro"] = macroname
	template["sprites"]["default"]["path"] = "art/general/back.png"
	template["sprites"]["highlight"]["path"] = "art/general/back_high.png"
	template["position"] = [0, 192+159]
	template["default_name"] = "Back"
	print(template)
	var button = ObjectFactory.create_from_template(
		script,
		template,
		{},
		arguments
	)
	button.wait = true
	button.wait_signal = "tree_exited"
	button.variables.set_val("click_sound_macro", "sound_back_button_cancel")
	return button
	
# TODO IMPLEMENT
func gui_input(script, arguments):
	pass

func ws_gui(script, arguments):
	if not main.get_tree():
		return
	var guitype = arguments.pop_front()
	if not has_method("gui_"+guitype.to_lower()):
		return GlobalErrors.log_error("Invalid type for gui - "+guitype, {"script": script})
	return callv("gui_"+guitype.to_lower(), [script, arguments])

# NEW (internal)
func ws_delete_gui_back(script, arguments):
	for node in ScreenManager.top_screen().get_children():
		if "template" in node:
			if node["template"]["default_name"] == "Back":
				node.queue_free()
				return

func click_option(option):
	Commands.macro_or_label(option, main.stack.scripts[-1], [])
