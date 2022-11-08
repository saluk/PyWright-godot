extends Reference

var main
var command

func _init(commands):
	main = commands.main
	command = commands

func ws_text(script, arguments):
	var text = PoolStringArray(arguments).join(" ")
	text = text.substr(1,text.length()-2)
	return Commands.create_textbox(text)

func ws_nt(script, arguments):
	var nametag = PoolStringArray(arguments).join(" ")
	main.stack.variables.set_val("_speaking", "")    		  # Set no character as speaking
	main.stack.variables.set_val("_speaking_name", nametag)   # Next character will have this name
