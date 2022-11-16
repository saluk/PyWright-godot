extends Reference
class_name WrightScriptStack

var main
var scripts := []

var variables:Variables
var evidence_pages := {
	
}

var macros := {}

var filesystem

enum {
	STACK_READY,
	STACK_PROCESSING,
	STACK_COMPLETE,
	STACK_YIELD,
	STACK_DEBUG
}
var state = STACK_READY

var blockers = []
var blocked_scripts = []

var REPEAT_MAX = 6  #If nonzero, and the same line is attempted to execute more than this value, drop to the debugger
var repeated = {"line":null, "line_num": -1, "amount": 0}

func _init(main):
	assert(main)
	self.main = main
	variables = Variables.new()
	filesystem = load("res://System/Files/Filesystem.gd").new()

signal stack_empty
signal line_executed   # emit when any script executes a line

var macro_scripts_found = 0

func load_macros_from_path(path):
	if not "res://" in path:
		path = "res://" + path 
	print("SCANNING ", path)
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break
			if file_name == "." or file_name == "..":
				pass
			elif dir.current_is_dir():
				continue
			elif file_name == "macros.txt" or file_name.ends_with(".mcro"):
				var script = WrightScript.new(main, self)
				print("MACRO LOADED: ", path, "/", file_name)
				script.load_txt_file(Filesystem.path_join(path, file_name))
				scripts.append(script)
				script.allowed_commands = ["macro", "endmacro"]
				macro_scripts_found += 1
	else:
		print("COULDN'T OPEN DIRECTORY")

func init_game(path):
	# Used to load a game and then a case inside the game
	filesystem = load("res://System/Files/Filesystem.gd").new()
	load_script(path+"/intro.txt")
	if not scripts[-1].lines.size():
		add_script("casemenu")
		scripts[-1].root_path = path
	# Reverse order load the macro scripts so they run first
	load_macros_from_path("macros")
	if not macro_scripts_found:
		print("MACRO ERROR")
	
func add_script(script_text):
	var new_script = WrightScript.new(main, self)
	new_script.load_string(script_text)
	scripts.append(new_script)
	return new_script
	
func load_script(script_path):
	var new_script = WrightScript.new(main, self)
	new_script.load_txt_file(script_path)
	scripts.append(new_script)
	# TODO - pretty sure we dont want to reload the macros on every script change, but only when starting a game or case
	load_macros_from_path(script_path.rsplit("/", true, 1)[0])
	return new_script
	
func remove_script(script):
	if script in scripts:
		scripts.erase(script)
		script.end()
		
func clear_scripts():
	while scripts:
		scripts[0].end()
		scripts.erase(scripts[0])
		
func show_in_debugger():
	if not main or not main.get_tree():
		return
	var debugger = main.get_tree().get_nodes_in_group("ScriptDebugger")
	if debugger:
		debugger[0].update_current_stack(self)
		
func show_frame(frame):
	if not main or not main.get_tree():
		return
	var framelog = main.get_tree().get_nodes_in_group("FrameLog")
	if framelog:
		framelog[0].add_frame(frame)
		
func clean_scripts():
	"""Remove any scripts that should be ended"""
	var newscripts = []
	for scr in scripts:
		if scr.line_num >= scr.lines.size():
			print("remove script ", scr.filename)
		else:
			newscripts.append(scr)
	scripts = newscripts
	show_in_debugger()
	
func new_state(state):
	self.state = state

func blocked(scr):
	if scr in blocked_scripts:
		return true

func remove_blocker(frame):
	if frame.sig in blockers:
		blockers.erase(frame.sig)
		if not blockers and frame.scr in blocked_scripts:
			frame.scr.next_line()
			blocked_scripts.erase(frame.scr)

func process():
	print("PROCESS BEGINS")
	if not scripts:
		if state == STACK_PROCESSING or state == STACK_YIELD:
			emit_signal("stack_empty")
			state = STACK_COMPLETE
		return new_state(state)
	if state == STACK_READY:
		# Any additional setup we might need could go here
		state = STACK_PROCESSING
	if state == STACK_YIELD:
		# Resume processing
		state = STACK_PROCESSING
	while scripts and state == STACK_PROCESSING:
		clean_scripts()
		if not scripts:
			return new_state(STACK_YIELD)
		if blocked(scripts[-1]) and blockers:
			yield(main.get_tree(), "idle_frame")
			continue
		var frame = scripts[-1].process_wrightscript()
		show_frame(frame)
		show_in_debugger()
		print("FRAME:", frame, ",", frame.line_num, ",<<", frame.line, ">>,", frame.sig)
		if REPEAT_MAX > 0:
			if (repeated["line"] == null or (repeated["line"] != frame.line or repeated["line_num"] != frame.line_num)):
				repeated["line"] = frame.line
				repeated["line_num"] = frame.line_num
				repeated["amount"] = 0
			else:
				repeated["amount"] += 1
				if repeated["amount"] > REPEAT_MAX:
					print("ERROR: tried to execute a line more than "+str(REPEAT_MAX)+" times.")
					print(frame.line)
					pass
		if frame.sig is int:
			# TODO might not need this yield
			if frame.sig == Commands.YIELD:
				#yield(main.get_tree(), "idle_frame")
				frame.scr.next_line()
				return new_state(STACK_YIELD)
			elif frame.sig == Commands.UNDEFINED:
				main.log_error("No command for "+frame.command)
				frame.scr.next_line()
				return new_state(STACK_YIELD)
			elif frame.sig == Commands.NOTIMPLEMENTED:
				print("not implemented command "+frame.command)
				frame.scr.next_line()
				return new_state(STACK_YIELD)
			elif frame.sig == Commands.DEBUG:
				show_in_debugger()
				yield(main.get_tree(), "idle_frame")
				print(" - debug - ")
				frame.scr.next_line()
				return new_state(STACK_YIELD)
			elif frame.sig == Commands.END:
				if frame.scr in scripts:
					scripts.erase(frame.scr)
				return new_state(STACK_YIELD)
			elif frame.sig == Commands.NEXTLINE:
				frame.scr.next_line()
				continue
			else:
				print("undefined return")
				frame.scr.next_line()
				return new_state(STACK_YIELD)
		elif frame.sig is SceneTreeTimer or (frame.sig and frame.sig.get("wait_signal") and frame.sig.get("wait") in [null, true]):
			blockers.append(frame.sig)
			blocked_scripts.append(frame.scr)
			var sig = "timeout"
			if frame.sig.get("wait_signal"):
				sig = frame.sig.get("wait_signal")
			frame.sig.connect(sig, self, "remove_blocker", [frame], CONNECT_ONESHOT)
			return new_state(STACK_YIELD)
		else:
			frame.scr.next_line()
			return new_state(STACK_YIELD)
