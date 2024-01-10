extends Reference

var main

func _init(commands):
	main = commands.main
	
func ws_textbox(script, arguments):
	#There can be only one!
	ws_advance_text(script, [])
	var text = Commands.join(arguments)
	var quote_char = text.substr(0,1)
	text = text.substr(1,text.length())
	# Allow lines that don't terminate the quote
	if text.ends_with(quote_char):
		text = text.substr(0, text.length()-1)
	# Default to green text in cross examine
	if script.is_inside_cross():
		text = "{c292}" + text
	return Commands.create_textbox(script, text)
	
func ws_text(script, arguments):
	return ws_textbox(script, arguments)

func ws_nt(script, arguments):
	var nametag = Commands.join(arguments)
	main.stack.variables.set_val("_speaking", "")    		  # Set no character as speaking
	main.stack.variables.set_val("_speaking_name", nametag)   # Next character will have this name

# NEW 
# finds the textbox and makes it continue
func ws_advance_text(script, arguments):
	for obj in Commands.get_objects(null, null, Commands.TEXTBOX_GROUP):
		obj.click_continue()
		return

func ws_textblock(script, arguments:Array):
	if not main.get_tree():
		return
	var ret = Commands.keywords(arguments, true)
	var keywords = ret[0]
	var ret_args = ret[1]
	var pos = [ret_args[0], ret_args[1]]
	var obj:Node = ObjectFactory.create_from_template(
		script,
		"textblock",
		{},
		["name="+keywords.get("name", "textblock"),
		"x="+pos[0],
		"y="+pos[1]]
	)
	obj.text_contents = String.join(ret_args.slice(4,ret_args.size()))
	obj.text_width = int(ret_args[2])
	obj.text_height = int(ret_args[3])
	obj.text_color = keywords.get("color", "000")
	obj.script_name = keywords.get("name", "textblock")
	return obj
