extends Reference
class_name WrightScript

var main:Node
var screen:Screen
var stack
var root_path := ""
var filename := ""
var lines := []
var labels := {}  # each label will have a list of line numbers
var variables:Variables  # local variables accessed with script.x
var line_num := 0
var line:String

var u_id # For saving

var allow_goto_parent_script := false
var allowed_commands := []  #If any commands are in this list, only process those commands

var allow_next_line = true

var processing   # TODO unsure if used

signal GOTO_RESULT

static func one_frame(dt:float) -> float:
	#  Determine how many frames, at 60 frames per second, have passed over dt
	return dt * 60.0

func _init(main, stack, screen:Screen=null):
	assert(main)
	assert(stack)
	self.main = main
	self.stack = stack
	if screen:
		self.screen = screen
	else:
		self.screen = ScreenManager.top_screen()
	u_id = OS.get_system_time_msecs()
	variables = Variables.new()

func has_script(scene_name) -> String:
	var names = [scene_name+".script.txt", scene_name+".txt"]
	for name in names:
		print(root_path+"; "+name)
		var found = Filesystem.lookup_file(name, root_path)
		if found:
			return found
	GlobalErrors.log_error("File Error: Unable to find or load script, searched [%s] at root path %s" % [",".join(names), root_path])
	return ""

func fullpath() -> String:
	return Filesystem.path_join(root_path, filename)

func load_txt_file(path:String):
	lines = []
	root_path = path.get_base_dir()+"/"
	filename = path.get_file()
	var f = File.new()
	var err = f.open(path, File.READ)
	var buffer := ""
	if err == OK:
		buffer = f.get_as_text(false)
		f.close()
		buffer = buffer.replace("\r\n", "\n")
		buffer = buffer.replace("\r", "\n")
		lines = buffer.split("\n")
		preprocess_lines()
	else:
		print("Error loading wrightscript file ", path)

func load_string(string:String):
	lines = []
	if not root_path:
		#root_path = "res://"
		root_path = main.current_game+"/"
	for line in string.split("\n"):
		lines.append(line)
	preprocess_lines()

func add_label(label, line_num):
	if not label in labels:
		labels[label] = []
	if not line_num in labels[label]:
		labels[label].append(line_num)
	labels[label].sort()

var label_statements = [
	"label", "list", "statement", "result", "cross"
]
var statement_args = {
	"label": [],
	"list": ["noback"],
	"statement": [],
	"cross": []
}

func preprocess_lines():
	var line:String
	var segments:Array
	var i = 0
	var macro = {}
	var examining = false
	while 1:
		if i >= lines.size():
			return
		line = lines[i]
		line = line.strip_edges(true, true)
		# TODO terrible hack for live editing
		if line.begins_with("#> "):
			line = line.substr(3)
		lines[i] = line
		segments = line.split(" ", true, 1)

		# TODO still kind of don't like doing this
		if macro or segments[0] == "macro":
			if macro:
				if segments and segments[0] == "endmacro":
					stack.macros[macro["name"]] = macro["lines"]
					macro = {}
				else:
					macro["lines"].append(line)
				lines[i] = "#> "+lines[i]
				i += 1
			elif segments[0] == "macro":
				macro = {"name": line.split(" ")[1].strip_edges(), "lines": []}
				lines[i] = "#> "+lines[i]
				i += 1
			continue

		# See comment above ws_examine
		if examining:
			if segments and segments[0]!="region" and segments[0].strip_edges():
				examining = false
				if segments[0] != "showexamine":
					lines.insert(i,"showexamine")
					i += 1
		elif segments and segments[0] == "examine":
			examining = true

		if segments and segments[0] in label_statements and segments.size()>1:
			var tag = segments[1].strip_edges()
			var args = Array(tag.split(" "))
			for arg in args.slice(1, args.size()-1):
				if "=" in arg or arg in statement_args[segments[0]]:
					args.erase(arg)
			tag = " ".join(args)
			add_label(tag, i)
			i += 1
			continue
		elif segments and segments[0] == "include":
			var include_scr = load("res://System/WrightScript/WrightScript.gd").new(main, self.stack)
			include_scr.load_txt_file(root_path+segments[1]+".txt")
			var off = 1
			lines.insert(i+off, "#i- " + line)
			off += 1
			for include_line in include_scr.lines:
				lines.insert(i+off, include_line)
				off += 1
			lines.remove(i)
			continue
		elif segments and segments[0] and segments[0][0] == "{":
			segments[0] = segments[0].substr(1)
			segments[-1] = segments[-1].substr(0,segments[-1].length()-1)
			var command = segments[0]
			var args = []
			if segments.size() > 1:
				args = segments[1].split(" ")
			if Commands.is_macro(command):
				var script_lines = Commands.get_processed_macro_lines(command, args, line_num)
				lines[i] = "#im- " + line
				for off in range(script_lines.size()):
					lines.insert(i+1+off, script_lines[off])
			else:
				GlobalErrors.log_error("no macro found to include:"+command)
		i += 1
	print("SCRIPT STARTING:", to_string())

func get_next_line(offset:int):
	if line_num+offset >= lines.size():
		return ""
	return lines[line_num+offset]

func goto_line_number(offset:int, relative:bool=false):
	allow_next_line = false
	if relative:
		line_num = line_num+offset
	else:
		line_num = offset
	if line_num < 0:
		line_num = 0

func next_line():
	# Goto the next line - unless we have used goto recently
	if allow_next_line:
		line_num += 1

# TODO add test for we can have multiple labels with the same name in a file, and we should go to the nearest one
func goto_label(label, fail=null):
	allow_next_line = false
	var line_nums
	if label in labels:
		line_nums = labels[label]
	elif fail in labels:
		line_nums = labels[fail]
	else:
		stack.variables.del_val("_lastline")
		if allow_goto_parent_script:
			end()
			stack.scripts.pop_back()
			if stack.scripts:
				emit_signal("GOTO_RESULT")
				return stack.scripts[-1].goto_label(label, fail)
		GlobalErrors.log_error("Tried to go somewhere non existent "+label, {"script": self})
		allow_next_line = true
		return
	stack.variables.set_val("_lastline", str(line_num+1))
	StandardVar.CURRENTLABEL.store(label)
	# Try to go to next line number
	for possible_line_num in line_nums:
		if possible_line_num > line_num:
			line_num = possible_line_num
			emit_signal("GOTO_RESULT")
			return
	# We couldn't find it, go to the first match
	line_num = line_nums[0]
	emit_signal("GOTO_RESULT")

func resume():
	# If there is a cross examination in progress, goto the last statement on its stack
	if resume_cross():
		return
	var lastline = stack.variables.get_int("_lastline", null)
	if lastline != null:
		# TODO probably not what anyone expects
		goto_line_number(lastline)

func resume_cross():
	var resume_line = stack.variables.get_int("_cross_resume_line", null)
	if resume_line == null:
		return false
	stack.variables.del_val("_cross_resume_line")
	stack.variables.del_val("_lastline")
	stack.variables.set_val("_in_statement", "true")
	goto_line_number(resume_line)
	return true

# Go to the label, unless label is ? in which case we execute the next line
func succeed(label):
	if label == "?":
		return
	goto_label(label)

# Go to the dest, unless label is ? in which case we skip the next line
func fail(label, dest=null):
	if label == "?":
		line_num += 1
	elif dest:
		goto_label(dest)

func is_statement(line):
	line = split_line(line).to_lower()
	return line.begins_with("statement ") or line.strip_edges() == "statement"

func is_cross(line):
	line = split_line(line).to_lower()
	return line.begins_with("cross ") or line.strip_edges() == "cross"

func is_endcross(line):
	line = split_line(line).to_lower()
	return line.begins_with("endcross ") or line.strip_edges() == "endcross"

func is_inside_cross():
	var currentcross = stack.variables.get_int("currentcross", null)
	if currentcross==null:
		return false
	# double check that the global currentcross value actually matches up with a cross statement
	# currentcross may have been set by a different script
	# TODO - maybe script namespace would work here
	if currentcross >= lines.size():
		return false
	if not is_cross(lines[currentcross]):
		return false
	return true

func next_statement():
	# not actually implemented, on purpose
	# the cross exam arrow right just calls main_button_advance_text
	# Some case writers include logic BEFORE a statement tag to determine
	# whether the statement should appear or not
	return

func get_prev_statement():
	if not is_inside_cross():
		print("NOT INSIDE CROSS SO NO PREV STATEMENT")
		return null
	var si = line_num-1
	var seen_statements = StandardVar.STATEMENTS.retrieve()
	if seen_statements.size() < 2:
		print("SEEN STATEMENTS:", seen_statements," so no left arrow")
		return null
	return int(seen_statements[-2])

func prev_statement():
	var si = get_prev_statement()
	if si != null:
		CrossExamination.pop_rightmost_statement(main)
		return goto_line_number(si)

func read_macro():
	if not lines[line_num].to_lower().begins_with("macro "):
		return
	# Start macro
	var macro_name = lines[line_num].split(" ", true, 1)[1]
	if macro_name.length() <= 0:
		GlobalErrors.log_error("Macro has no name", {"script": self})
		return
	var macro_lines = []
	line_num += 1
	while line_num < lines.size():
		var line = lines[line_num]
		if line.strip_edges() == "endmacro":
			# TODO
			# FOR some reason if we do this we will end up skipping a macro
			# that immediately follows an endmacro
			line_num += 1
			break
		macro_lines.append(line)
		line_num += 1
	stack.macros[macro_name] = macro_lines
	if line_num >= lines.size():
		end()

class Frame:
	var scr
	var line_num
	var line
	var sig
	var command = ""
	var args = []
	func _init(scr, line_num, line, sig):
		self.scr = scr
		self.line_num = line_num
		self.line = line
		self.sig = sig
		if " " in line:
			var spl = Array(line.split(" "))
			command = spl.pop_front()
			args = spl

func get_frame(sig):
	return Frame.new(self, line_num, line, sig)

# Returns the part of the line that doesn't have a command and has non-blank text
func split_line(line):
	var comment
	if "#" in line and "//" in line:
		if line.find_last("#") < line.find_last("//"):
			line = line.substr(0, line.find_last("#"))
		else:
			line =line.substr(0, line.find_last("//"))
	if "#" in line:
		line = line.rsplit("#", true, 1)[0]
	elif "//" in line:
		line = line.rsplit("//", true, 1)[0]
	return line.strip_edges()

func process_wrightscript() -> Frame:
	allow_next_line = true
	if not main:
		return Frame.new(self, -1, "", Commands.YIELD)
	if line_num >= lines.size():
		print("SCRIPT REMOVAL:", to_string())
		return Frame.new(self, line_num, "", Commands.END)
	print("SCRIPT EXECUTION:", to_string())
	self.stack.emit_signal("line_executed", lines[line_num])
	line = split_line(lines[line_num])
	var watch_sig = Commands.NEXTLINE
	for watch_search in main.stack.watched_commands:
		if watch_search.to_lower() in line.to_lower():
			watch_sig = Commands.DEBUG
			break
	if not line:
		return Frame.new(self, line_num, line, watch_sig)
	if allowed_commands.size() > 0 and not line.split(" ")[0] in allowed_commands:
		return Frame.new(self, line_num, line, watch_sig)
	# TODO should be able to use # inside at least a text string, if not inside an argument
	if line[0] == '"' or line[0] == "'":
		line = "text "+line
	var split = line.split(" ") as Array
	var call_command = split[0].to_lower()
	var sig = Commands.call_command(
		call_command, self, split.slice(1, split.size())
	)
	if watch_sig == Commands.DEBUG:
		sig = watch_sig
	print("SIGNAL:", sig)
	if sig == null:
		sig = Commands.NEXTLINE
	return get_frame(sig)

func to_string():
	var l = ""
	if line_num < lines.size():
		l = lines[line_num]
	var stack_index = stack.scripts.find(self)
	return "SCRIPT("+"si:"+str(stack_index)+" "+filename+":"+str(line_num)+") - "+l

#Force script to end
func end():
	#processing = null
	lines.append("")
	line_num = len(lines)-1


#Save/Load
var save_properties = [
	"root_path", "filename", "lines", "labels",
	# "variables",
	"line_num", "line", "allow_goto_parent_script",
	"allowed_commands", "allow_next_line", "label_statements","u_id"
]
func save_node(data):
	data["variables"] = SaveState._save_node(variables)

static func create_node(saved_data:Dictionary):
	pass

func load_node(tree, saved_data:Dictionary):
	SaveState._load_node(tree, variables, saved_data["variables"])

func after_load(tree, saved_data:Dictionary):
	pass
