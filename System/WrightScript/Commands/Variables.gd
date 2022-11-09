extends Reference

var main

func _init(commands):
	main = commands.main

func ws_set(script, arguments):
	var key = arguments.pop_front()
	var value = Commands.join(arguments)
	main.stack.variables.set_val(key, value)
	
func ws_setvar(script, arguments):
	return ws_set(script, arguments)
	
# TODO IMPLEMENT
#    @category([VALUE("variable","variable name to set"),COMBINED("expression2","The results of the expression will be stored in the variable.")],type="logic")
#    def _set_ex(self,command,variable,*args):
#        """Sets a variable to some value based on an expression"""
#        value = EVAL_EXPR(EXPR(" ".join(args)))
#        assets.variables[variable]=value
func ws_set_ex(script, arguments):
	pass
	
func ws_setvar_ex(script, arguments):
	return ws_set_ex(script, arguments)

# TODO IMPLEMENT
#    @category([VALUE("variable","The variable to save the value into"),COMBINED("source variable","The variable to get the value from. Can use $x to use another variable to point to which variable to copy from, like a signpost.")],type="logic")
#    def _getvar(self,command,variable,*args):
#        """Copies the value of one variable into another."""
#        value = u"".join(args)
#        assets.variables[variable]=assets.variables.get(value,"")
func ws_getvar(script, arguments):
	pass
	
func ws_get(script, arguments):
	return ws_get(script, arguments)
	
# TODO IMPLEMENT
#    @category([VALUE("variable","The variable to save the value into"),KEYWORD("name","The object to get the property from"),KEYWORD("prop","The property to get from the object")],type="logic")
#    def _getprop(self,command,variable,*args):
#        """Copies the value of some property of an object into a variable"""
#        name = None
#        prop = None
#        for a in args:
#            if a.startswith("name="):
#                name = a.split("=",1)[1]
#            if a.startswith("prop="):
#                prop = a.split("=",1)[1]
#        if not name or not prop:
#            raise script_error("getprop: need to supply an object name= and a prop= to get")
#        for o in self.obs:
#            if getattr(o,"id_name",None)==name:
#                p = str(o.getprop(prop))
#                assets.variables[variable]=p
#                return
#        raise script_error("getprop: object not found")
func ws_getprop(script, arguments):
	pass
	
# TODO IMPLEMENT
#    @category([VALUE("variable","The variable to save the value into"),KEYWORD("name","The object to get the property from"),KEYWORD("prop","The property to get from the object")],type="logic")
#    def _setprop(self,command,*args):
#        """Copies the value of a variable to some property of an object"""
#        name = None
#        prop = None
#        val = []
#        for a in args:
#            if a.startswith("name="):
#                name = a.split("=",1)[1]
#            elif a.startswith("prop="):
#                prop = a.split("=",1)[1]
#            else:
#                val.append(a)
#        val = " ".join(val)
#        if not name or not prop:
#            raise script_error("setprop: need to supply an object name= and a prop= to set")
#        for o in self.obs:
#            if getattr(o,"id_name",None)==name:
#                o.setprop(prop,val)
#                return
#        raise script_error("setprop: object not found")
func ws_setprop(script, arguments):
	pass
	
# TODO IMPLEMENT
#    @category([VALUE("variable","variable name to save random value to"),VALUE("start","smallest number to generate"),VALUE("end","largest number to generate")],type="logic")
#    def _random(self,command,variable,start,end):
#        """Generates a random integer with a minimum
#        value of START, a maximum value of END, and
#        stores that value to VARIABLE"""
#        random.seed(pygame.time.get_ticks()+random.random())
#        value = random.randint(int(start),int(end))
#        assets.variables[variable]=str(value)
func ws_random(script, arguments):
	pass

func ws_joinvar(script, arguments):
	var key = arguments.pop_front()
	main.stack.variables.set_val(key, Commands.join(arguments, ""))

func ws_addvar(script, arguments):
	var numa = main.stack.variables.get_num(arguments[0])
	var numb = main.stack.variables.to_num(arguments[1])
	if not numa:
		return main.log_error(arguments[0]+"="+str(numa)+" not a number")
	main.stack.variables.set_val(arguments[0], numa + numb)

func ws_subvar(script, arguments):
	var numa = main.stack.variables.get_num(arguments[0])
	var numb = main.stack.variables.to_num(arguments[1])
	if not numa:
		return main.log_error(arguments[0]+"="+str(numa)+" not a number")
	main.stack.variables.set_val(arguments[0], numa - numb)

func ws_mulvar(script, arguments):
	var numa = main.stack.variables.get_num(arguments[0])
	var numb = main.stack.variables.to_num(arguments[1])
	if not numa:
		return main.log_error(arguments[0]+"="+str(numa)+" not a number")
	main.stack.variables.set_val(arguments[0], numa * numb)
	
func ws_divvar(script, arguments):
	var numa = main.stack.variables.get_num(arguments[0])
	var numb = main.stack.variables.to_num(arguments[1])
	if not numa:
		return main.log_error(arguments[0]+"="+str(numa)+" not a number")
	main.stack.variables.set_val(arguments[0], numa / numb)

func ws_absvar(script, arguments):
	var inta = main.stack.variables.get_num(arguments[0])
	if not inta:
		return main.log_error(arguments[0]+"="+str(inta)+" not a number")
	main.stack.variables.set_val(arguments[0], abs(inta))
	
# TODO IMPLEMENT
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
	
# TODO IMPLEMENT
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
	var truth = WSExpression.EVAL_EXPR(
		WSExpression.SIMPLE_TO_EXPR(
			Commands.join(arguments)
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
	var truth = WSExpression.GV(arguments[0])
	if truth:
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
		Commands.join(arguments)
	)
	truth = WSExpression.string_to_bool(truth)
	if truth:
		script.succeed(label)
	else:
		script.fail(label, fail)

# TODO IMPLEMENT
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
