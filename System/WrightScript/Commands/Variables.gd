extends Reference

var main

func _init(commands):
	main = commands.main

func ws_set(script, arguments):
	var key = arguments.pop_front()
	var value = PoolStringArray(arguments).join(" ")
	main.stack.variables.set_val(key, value)
	
func ws_setvar(script, arguments):
	return ws_set(script, arguments)

func ws_goto(script, arguments):
	var fail = Commands.keywords(arguments).get("fail", null)
	script.goto_label(arguments[0], fail)

func ws_label(script, arguments):
	main.stack.variables.set_val("_lastlabel", arguments[0])

func ws_flag(script, arguments:Array, return_true=true):
	var label = arguments.pop_back()
	var fail = Commands.keywords([label]).get("fail", null)
	if fail:
		label = arguments.pop_back()
	if label.ends_with("?"):
		arguments.append(label.substr(0, label.length()-1))
		label = "?"
	var mode = 0
	var line = ""
	for word in arguments:
		if mode == 0:
			line += main.stack.variables.get_truth_string(word)
		elif mode == 1:
			if word == "AND":
				line += " and "
			elif word == "OR":
				line += " or "
			else:
				print("flag logic has command that's not AND or OR")
				return Commands.UNDEFINED
		mode = 1-mode
	var expression = Expression.new()
	expression.parse(line)
	var result = expression.execute()
	if result == return_true:
		script.succeed(label)
	if fail:
		script.fail(label, fail)

func ws_setflag(script, arguments):
	main.stack.variables.set_val(arguments[0], "true")
	
func ws_delflag(script, arguments):
	if arguments[0] in main.stack.variables:
		main.stack.variables.erase(arguments[0])
		
func ws_noflag(script, arguments):
	# NOT YET IMPLEMENTED
	return ws_flag(
		script, arguments, false
	)

# NOTE:
# If you use ? AND fail, a success will send the script to the next line, 
# while a failure will to to the fail label. It's valid but a bit weird.
# You should ONLY use one of (?) or (label + fail=)
func ws_is(script, arguments):
	var removed = Commands.keywords(arguments, true)
	var keywords = removed[0]
	var fail = keywords.get("fail", null)
	arguments = removed[1]
	var label
	if arguments[-1].ends_with("?"):
		arguments[-1] = arguments[-1].substr(0, arguments[-1].length()-1)
		label = "?"
	else:
		label = arguments.pop_back()
	if WSExpression.EVAL_SIMPLE(PoolStringArray(arguments).join(" ")):
		script.succeed(label)
	else:
		script.fail(label, fail)
		
func ws_isnot(script, arguments):
	var removed = Commands.keywords(arguments, true)
	var keywords = removed[0]
	var fail = keywords.get("fail", null)
	arguments = removed[1]
	var label
	if arguments[-1].ends_with("?"):
		arguments[-1] = arguments[-1].substr(0, arguments[-1].length()-1)
		label = "?"
	else:
		label = arguments.pop_back()
	var truth = WSExpression.EVAL_EXPR(
		WSExpression.SIMPLE_TO_EXPR(
			PoolStringArray(arguments).join(" ")
		)
	)
	if not WSExpression.string_to_bool(truth):
		script.succeed(label)
	else:
		script.fail(label, fail)
		
func ws_isempty(script, arguments):
	var removed = Commands.keywords(arguments, true)
	var keywords = removed[0]
	var fail = keywords.get("fail", null)
	arguments = removed[1]
	var label
	if arguments[-1].ends_with("?"):
		arguments[-1] = arguments[-1].substr(0, arguments[-1].length()-1)
		label = "?"
	else:
		label = arguments.pop_back()
	var truth = WSExpression.GV(arguments[0])
	if not truth:
		script.succeed(label)
	else:
		script.fail(label, fail)
		
func ws_is_ex(script, arguments):
	var removed = Commands.keywords(arguments, true)
	var keywords = removed[0]
	var fail = keywords.get("fail", null)
	arguments = removed[1]
	var label
	if arguments[-1].ends_with("?"):
		arguments[-1] = arguments[-1].substr(0, arguments[-1].length()-1)
		label = "?"
	else:
		label = arguments.pop_back()
	var truth = WSExpression.EVAL_STR(
		PoolStringArray(arguments).join(" ")
	)
	if not truth:
		script.succeed(label)
	else:
		script.fail(label, fail)
