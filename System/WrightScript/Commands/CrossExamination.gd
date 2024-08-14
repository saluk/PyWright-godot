extends Reference

var main

func _init(commands):
	main = commands.main

func ws_cross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("_statement_line_num", "")
	main.stack.variables.set_val("currentcross", script.line_num)
	#script.connect("GOTO_RESULT", self, "ws_endcross", [script, []])
	
func ws_endcross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("_statement_line_num", "")

# TODO Maybe deprecate this command
func ws_cross_restart(script, arguments):
	var li = main.stack.variables.get_int("currentcross", null)
	if li != null:
		script.goto_line_number(li)

func ws_clearcross(script, arguments):
	main.stack.variables.del_val("_statement")
	main.stack.variables.del_val("_statement_line_num")
	main.stack.variables.del_val("currentcross")

# TODO test these
func ws_next_statement(script, arguments):
	var cross = main.cross_exam_script()
	if cross:
		cross.next_statement()
	Commands.delete_object_group(Commands.TEXTBOX_GROUP)
	
func ws_prev_statement(script, arguments):
	var cross = main.cross_exam_script()
	if cross:
		cross.prev_statement()
	Commands.delete_object_group(Commands.TEXTBOX_GROUP)
	
# TODO
# Cross exam model:
#	when we encounter cross, we enter cross exam mode. when we hit endcross we exit
#	when we encounter a statement, we add that statement line to the current cross exam model of statements
#	we also remember this statement as our most recent statement
#	when we jump, we see if we land inside the current cross exam, inside a new cross exam, or outside of 
#	a cross exam. remember what line we were at when we jumped
#	Remember the state of each cross exam we have encountered within a script (when the script is unloaded we can forget)
#	When we resume, go to the last line encountered on the last encountered cross exam
#		data stored: 
#		cross_[script]_[line]_statement_1 = yes - user saw statement 1
#		cross_[script]_[line]_statement_2 = no - user did not see statement 2
#		cross_[script]_[line]_statement_3 = yes - user saw statement 3
#		cross_[script]_[line]_statement_last = 3 - 
#		currentcross = cross line number
#	when we go to the previous statement, we should go to the "statement" line that we LAST REMEMBER before the current
#	statement, or the existing statement if it is first. Need a memory of encountered statements
#	When we go to the next statement, we just advance text.
func ws_statement(script, arguments):
	var test = Commands.keywords(arguments).get("test", "")
	if test:
		if not main.stack.variables.get_truth(test):
			script.next_statement()
			return
	main.stack.variables.set_val("_statement", arguments[0])
	var line_num = script.line_num
	main.stack.variables.set_val("_statement_line_num", script.line_num)

func ws_resume(script, arguments):
	var line_num = main.stack.variables.get_int("_statement_line_num")
	script.goto_line_number(line_num)
	script.next_statement()

# Press the current statement
func ws_callpress(script, arguments):
	Commands.delete_object_group(Commands.TEXTBOX_GROUP)
	return script.goto_label(
		"press "+main.stack.variables.get_string("_statement"),
		"none"
	)

# Show the court record to allow an evidence to be selected to present
# Also used internally to trigger creating the court record ui
func ws_present(script, arguments):
	# If we are running this, we should be outside of the cross examination
	Commands.delete_object_group(Commands.COURT_RECORD_GROUP)
	var present = not "nopresent" in arguments
	arguments.erase("nopresent")
	var clearcross = not "noclearcross" in arguments
	arguments.erase("noclearcross")
	if clearcross and present:
		ws_endcross(script, [])
	var cr = ObjectFactory.create_from_template(
		script,
		"court_record",
		{},
		[]
	)
	if not present:
		cr.in_presentation_context = false
	else:
		cr.in_presentation_context = true
	return cr

# Show the court record to allow an evidence to be selected to present
# TODO verify difference between present
# TODO maybe this is what should hide the back button?
# I *think* showpresent is meant to be called from an official cross examination
# while present can be used outside of cross examinations
#
# Called by court record button
func ws_showpresent(script, arguments):
	if not "noclearcross" in arguments:
		arguments.append("noclearcross")
	return Commands.call_command("present", script, arguments)

# Show court record but dont allow evidence to be presented
func ws_showrecord(script, arguments):
	arguments.append("nopresent")
	return ws_present(script, arguments)

# Actually do the presenting of evidence after it's selected from
# the court record
# >>> callpresent
# lookup selected evidence from court record via [_selected]
# goto the label '[_statement] maya' if we are in a statement
# goto the label 'maya' if we are not in a statement
func ws_callpresent(script, arguments):
	Commands.delete_object_group(Commands.TEXTBOX_GROUP)
	var ev = main.stack.variables.get_string("_selected")
	var statement = main.stack.variables.get_string("_statement")
	if statement:
		ev = ev + " " + statement
	Commands.call_command(
		"goto",
		main.stack.scripts[-1],
		[ev, "fail=none"]
	)
