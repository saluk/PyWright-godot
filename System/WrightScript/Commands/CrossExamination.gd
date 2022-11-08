extends Reference

var main
var command

func _init(commands):
	main = commands.main
	command = commands

func ws_cross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("_statement_line_num", "")
	main.stack.variables.set_val("_cross_line_num", script.executed_line_num)
	
func ws_endcross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("_statement_line_num", "")
	main.stack.variables.set_val("_cross_line_num", "")
	
func ws_statement(script, arguments):
	main.stack.variables.set_val("_statement", arguments[0])
	main.stack.variables.set_val("_statement_line_num", script.executed_line_num)

func ws_resume(script, arguments):
	script.goto_line_number(main.stack.variables.get_int("_statement_line_num"))
	script.next_statement()
	
func ws_callpress(script, arguments):
	main.get_tree().call_group(command.TEXTBOX_GROUP, "queue_free")
	script.goto_label(
		"press "+main.stack.variables.get_string("_statement"),
		"none"
	)
	
func ws_present(script, arguments):
	var cr = command.create_object(
		script, 
		"evidence_menu",
		"res://System/UI/CourtRecord.gd",
		[command.SPRITE_GROUP],
		arguments
	)
	return cr
	
func ws_showpresent(script, arguments):
	command.call_command("present", script, arguments)

func ws_callpresent(script, arguments):
	main.get_tree().call_group(command.TEXTBOX_GROUP, "queue_free")
	var ev = main.stack.variables.get_string("_selected")
	var statement = main.stack.variables.get_string("_statement")
	if statement:
		ev = ev + " " + statement
	Commands.call_command(
		"goto",
		main.stack.scripts[-1],
		[ev, "fail=none"]
	)
