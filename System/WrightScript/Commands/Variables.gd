extends Reference

var main
var rng

func _init(commands):
	main = commands.main
	rng = RandomNumberGenerator.new()
	rng.randomize()

func ws_set(script, arguments):
	var key = arguments.pop_front()
	var value = Commands.join(arguments)
	main.stack.variables.set_val(key, value)

func ws_setvar(script, arguments):
	return ws_set(script, arguments)

# NEW
func ws_delvar(script, arguments):
	main.stack.variables.del_val(arguments[0])

func ws_set_ex(script, arguments):
	var variableName = arguments.pop_front()
	var value = WSExpression.EVAL_STR(Commands.join(arguments))
	main.stack.variables.set_val(variableName, value)

func ws_setvar_ex(script, arguments):
	return ws_set_ex(script, arguments)

func ws_getvar(script, arguments):
	var save_to = arguments.pop_front()
	var get_from = Commands.join(arguments, "")
	main.stack.variables.set_val(save_to, main.stack.variables.get_string(get_from))

func ws_get(script, arguments):
	return ws_getvar(script, arguments)

func ws_getprop(script, arguments):
	var variable = arguments.pop_front()
	var kw = Commands.keywords(arguments)
	for object in ScreenManager.get_objects(kw["name"]):
		var value
		if kw["prop"] in "xy":
			value = object.position[{"x":0, "y":1}[kw["prop"]]]
		elif kw["prop"] == "z":
			value = object.z
		elif kw["prop"] == "frame":
			value = object.current_sprite.animated_sprite.frame
		main.stack.variables.set_val(variable, value)

func ws_setprop(script, arguments):
	var variable = arguments.pop_front()
	var kw = Commands.keywords(arguments)
	var value
	for object in ScreenManager.get_objects(kw["name"]):
		if kw["prop"] in "xy":
			value = main.stack.variables.get_int(variable)
			object.position[{"x":0, "y":1}[kw["prop"]]] = value
		elif kw["prop"] == "z":
			value = main.stack.variables.get_int(variable)
			object.z = value
		elif kw["prop"] == "frame":
			value = main.stack.variables.get_int(variable)
			object.current_sprite.animated_sprite.frame = value

func ws_random(script, arguments):
	var key = arguments.pop_front()
	var minimum = Values.to_num(arguments.pop_front())
	var maximum = Values.to_num(arguments.pop_front())
	var random_integer = rng.randi() % (maximum - minimum  + 1) + minimum
	main.stack.variables.set_val(key, random_integer)

func ws_joinvar(script, arguments):
	var key = arguments.pop_front()
	main.stack.variables.set_val(key, Commands.join(arguments, ""))

func ws_addvar(script, arguments):
	var numa = main.stack.variables.get_num(arguments[0])
	var numb = Values.to_num(arguments[1])
	if numa==null:
		return GlobalErrors.log_error(arguments[0]+"="+str(numa)+" not a number", {"script": script})
	main.stack.variables.set_val(arguments[0], numa + numb)

func ws_subvar(script, arguments):
	var numa = main.stack.variables.get_num(arguments[0])
	var numb = Values.to_num(arguments[1])
	if numa==null:
		return GlobalErrors.log_error(arguments[0]+"="+str(numa)+" not a number", {"script": script})
	if numa != null and numb != null:
		main.stack.variables.set_val(arguments[0], numa - numb)
	else:
		GlobalErrors.log_error(arguments[0]+"="+str(numa)+" not a number or "+arguments[1]+"="+str(numb)+" not a number", {"script": script})

func ws_mulvar(script, arguments):
	var numa = main.stack.variables.get_num(arguments[0])
	var numb = Values.to_num(arguments[1])
	if numa==null:
		return GlobalErrors.log_error(arguments[0]+"="+str(numa)+" not a number", {"script": script})
	main.stack.variables.set_val(arguments[0], numa * numb)

func ws_divvar(script, arguments):
	var numa = main.stack.variables.get_num(arguments[0])
	var numb = Values.to_num(arguments[1])
	if numa==null:
		return GlobalErrors.log_error(arguments[0]+"="+str(numa)+" not a number", {"script": script})
	main.stack.variables.set_val(arguments[0], numa / numb)

func ws_absvar(script, arguments):
	var inta = main.stack.variables.get_num(arguments[0])
	if inta==null:
		return GlobalErrors.log_error(arguments[0]+"="+str(inta)+" not a number", {"script": script})
	main.stack.variables.set_val(arguments[0], abs(inta))

# FIXME IMPLEMENT
#@category([VALUE("filename","file to export variables into, relative to the case folder"),
#            ETC("variable_names",
#                "The names of variables to export. If none are listed, all variables will be exported",
#                "all variables")],type="files")
#    def _exportvars(self,command,filename,*vars):
#        """Saves the name and value of listed variables to a file. They can later be restored. Can be used to make
#        ad-hoc saving systems, be a way to store achievements separate from saved games, or other uses."""
#        d = {}
#        if not vars:
#            vars = assets.variables.keys()
#        for k in vars:
#            d[k] = assets.variables.get(k,"")
#        filename = filename.replace("..","").replace(":","")
#        while filename.startswith("/"):
#            filename = filename[1:]
#        f = open(assets.game+"/"+filename,"w")
#        f.write(repr(d))
#        f.close()
func ws_exportvars(script, arguments):
	pass

func ws_filewrite(script, arguments):
	return Commands.NOTIMPLEMENTED

# FIXME IMPLEMENT
#    @category([VALUE("filename","file to import variables from, relative to the case folder")],type="files")
#    def _importvars(self,command,filename):
#        """Restores previously exported variables from the file."""
#        filename = filename.replace("..","").replace(":","")
#        while filename.startswith("/"):
#            filename = filename[1:]
#        try:
#            f = open(assets.game+"/"+filename)
#        except:
#            return
#        txt = f.read()
#        f.close()
#        if txt.strip():
#            d = eval(txt)
#            assets.variables.update(d)
func ws_importvars(script, arguments):
	pass

func ws_flag(script, arguments:Array, return_true=true):
	var label = arguments.pop_back()
	var fail = Commands.keywords([label]).get("fail", null)
	if fail:
		# FIXME - should make sure we are removing the fail= keyword from the arguments not just the last one
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
		return
	script.fail(label, fail)

func ws_setflag(script, arguments):
	main.stack.variables.set_val(arguments[0], "true")

func ws_delflag(script, arguments):
	if main.stack.variables.get_string(arguments[0], null) != null:
		main.stack.variables.del_val(arguments[0])

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
	if WSExpression.EVAL_SIMPLE(Commands.join(arguments)):
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
	if not WSExpression.EVAL_SIMPLE(Commands.join(arguments)):
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
	var truth = main.stack.variables.get_string(arguments[0])
	if truth == "":
		script.succeed(label)
	else:
		script.fail(label, fail)

func ws_isnotempty(script, arguments):
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
	var truth = main.stack.variables.get_string(arguments[0])
	if truth == "":
		script.fail(label, fail)
	else:
		script.succeed(label)

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
		Commands.join(arguments, " ")
	)
	truth = WSExpression.string_to_bool(truth)
	if truth:
		script.succeed(label)
	else:
		script.fail(label, fail)

# FIXME IMPLEMENT
#    @category([VALUE('variable','Variable to check if it exists'),
#                    CHOICE([VALUE('label','a label to jump to if the variable has been set and is not blank'),TOKEN('?','execute next line only if variable is set and not blank')])],type="logic")
#    def _isnumber(self,command,*args):
#        """If the variable contains a number jump to the given label or execute the next line if the given
#        label is a '?'"""
#        args = list(args)
#        label = args.pop(-1)
#        if label.endswith("?"):
#            args.append(label[:-1])
#            label = "?"
#        value = " ".join(args)
#        if value.isdigit():
#            return self.succeed(label)
#        return self.fail(label)
func ws_is_number(script, arguments):
	pass
