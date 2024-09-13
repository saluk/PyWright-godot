extends Reference

var main

func _init(commands):
	main = commands.main

func ws_cross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("currentcross", script.line_num)
	main.stack.variables.set_val("_statements", "")
	var fail = Commands.keywords(arguments).get("fail", null)
	if fail:
		StandardVar.COURT_FAIL_LABEL.store(fail)
	else:
		StandardVar.COURT_FAIL_LABEL.delete()

func ws_endcross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.del_val("_in_statement")
	main.stack.variables.del_val("_cross_resume_line")

# TODO Maybe deprecate this command
func ws_cross_restart(script, arguments):
	var li = main.stack.variables.get_int("currentcross", null)
	if li != null:
		script.goto_line_number(li)

func ws_clearcross(script, arguments):
	main.stack.variables.del_val("_statement")
	main.stack.variables.del_val("_in_statement")
	main.stack.variables.del_val("currentcross")
	main.stack.variables.del_val("_statements")
	main.stack.variables.del_val("_cross_resume_line")

# TODO test these
func ws_next_statement(script, arguments):
	var cross = main.cross_exam_script()
	if cross:
		cross.next_statement()
	Commands.delete_object_group(Commands.TEXTBOX_GROUP)
	main.stack.variables.set_val("_in_statement", "true")

func ws_prev_statement(script, arguments):
	var cross = main.cross_exam_script()
	if cross:
		cross.prev_statement()
	Commands.delete_object_group(Commands.TEXTBOX_GROUP)

func ws_statement(script, arguments):
	var test = Commands.keywords(arguments).get("test", "")
	if test:
		if not main.stack.variables.get_truth(test):
			script.next_statement()
			return
	main.stack.variables.set_val("_statement", arguments[0])
	main.stack.variables.set_val("_in_statement", "true")
	var cur_statements = main.stack.variables.get_string("_statements","")
	cur_statements = cur_statements.split(",", false)
	if not str(script.line_num) in cur_statements:
		cur_statements.append(str(script.line_num))
		main.stack.variables.set_val("_statements", cur_statements.join(","))

# Press the current statement
func ws_callpress(script, arguments):
	Commands.delete_object_group(Commands.TEXTBOX_GROUP)
	var cross_script = main.cross_exam_script()
	if cross_script:
		# At the context in which ws_callpresent is called, cross_script.line_num is the line after a statement's textbox
		main.stack.variables.set_val("_cross_resume_line", cross_script.line_num)
	return script.goto_label(
		"press "+main.stack.variables.get_string("_statement"),
		StandardVar.COURT_FAIL_LABEL.retrieve()
	)

# Return to the last line we jumped from, or the last statement
# if there is a `currentcross`
func ws_resume(script, arguments):
	script.resume()
	return

# Show the court record to allow an evidence to be selected to present
# Also used internally to trigger creating the court record ui
func ws_present(script, arguments):
	# If we are running this, we should be outside of the cross examination
	Commands.delete_object_group(Commands.COURT_RECORD_GROUP)
	# nopress and noclearcross are internal arguments
	var present = not "nopresent" in arguments
	arguments.erase("nopresent")
	var clearcross = not "noclearcross" in arguments
	arguments.erase("noclearcross")
	if clearcross and present:
		var resume = main.stack.variables.get_string("_cross_resume_line","")
		ws_endcross(script, [])
		if resume:
			main.stack.variables.set_val("_cross_resume_line",resume)
	else:
		var cross_script = main.cross_exam_script()
		if cross_script:
			# At the context in which ws_callpresent is called, cross_script.line_num is the line after a statement's textbox
			main.stack.variables.set_val("_cross_resume_line", cross_script.line_num)
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
	var fail = ""
	if statement:
		ev = ev + " " + statement
		fail = "fail="+StandardVar.COURT_FAIL_LABEL.retrieve()
	Commands.call_command(
		"goto",
		main.stack.scripts[-1],
		[ev, fail]
	)
