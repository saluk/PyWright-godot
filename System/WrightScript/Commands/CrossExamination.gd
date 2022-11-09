extends Reference

var main

func _init(commands):
	main = commands.main

func ws_cross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("_statement_line_num", "")
	main.stack.variables.set_val("_cross_line_num", script.line_num)
	
func ws_endcross(script, arguments):
	main.stack.variables.set_val("_statement", "")
	main.stack.variables.set_val("_statement_line_num", "")
	main.stack.variables.set_val("_cross_line_num", "")

# TODO IMPLEMENT
#    @category([],type="crossexam")
#    def _cross_restart(self,command,*args):
#        """Go to the first line in the current cross examination"""
#        if assets.variables.get("currentcross",None) is not None:
#            self.si = assets.variables.get("currentcross",None)
func ws_cross_restart(script, arguments):
	pass
	
# TODO IMPLEMENT
#    def _clearcross(self,command):
#        """Clears all cross exam related variables. A good idea to call this after a testimony
#        is officially over, to ensure that 'resumes' don't mistakenly go back to the cross exam, 
#        and prevent other bugs from occuring."""
#        self.cross = None
#        self.lastline = 0
#        self.statement = ""
#        self.instatement = False
func ws_clearcross(script, arguments):
	pass

# TODO test these
func ws_next_statement(script, arguments):
	script.next_statement()
	
func ws_prev_statement(script, arguments):
	script.prev_statement()
	
func ws_statement(script, arguments):
	var test = Commands.keywords(arguments).get("test", "")
	if test:
		if not main.stack.variables.get_truth(test):
			script.next_statement()
			return
	main.stack.variables.set_val("_statement", arguments[0])
	main.stack.variables.set_val("_statement_line_num", script.line_num)

func ws_resume(script, arguments):
	script.goto_line_number(main.stack.variables.get_int("_statement_line_num"))
	script.next_statement()

# Press the current statement
func ws_callpress(script, arguments):
	main.get_tree().call_group(Commands.TEXTBOX_GROUP, "queue_free")
	script.goto_label(
		"press "+main.stack.variables.get_string("_statement"),
		"none"
	)

# Show the court record to allow an evidence to be selected to present
func ws_present(script, arguments):
	var cr = Commands.create_object(
		script, 
		"evidence_menu",
		"res://System/UI/CourtRecord.gd",
		[Commands.SPRITE_GROUP],
		arguments
	)
	return cr

# Show the court record to allow an evidence to be selected to present
# TODO verify difference between present
# I *think* showpresent is meant to be called from an official cross examination
# while present can be used outside of cross examinations
func ws_showpresent(script, arguments):
	Commands.call_command("present", script, arguments)

# Actually do the presenting of evidence after it's selected from
# the court record
# >>> callpresent
# lookup selected evidence from court record via [_selected]
# goto the label '[_statement] maya' if we are in a statement
# goto the label 'maya' if we are not in a statement
func ws_callpresent(script, arguments):
	main.get_tree().call_group(Commands.TEXTBOX_GROUP, "queue_free")
	var ev = main.stack.variables.get_string("_selected")
	var statement = main.stack.variables.get_string("_statement")
	if statement:
		ev = ev + " " + statement
	Commands.call_command(
		"goto",
		main.stack.scripts[-1],
		[ev, "fail=none"]
	)

# TODO IMPLEMENT
#    @category([],type="interface")
#    def _showrecord(self,command,*args):
#        print "show ev menu"
#        assets.addevmenu()
#        return True
func ws_showrecord(script, arguments):
	pass
