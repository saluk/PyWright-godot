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
	STACK_PROCESSING,
	STACK_COMPLETE,
	STACK_YIELD,
	STACK_DEBUG
}
var state = STACK_PROCESSING

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
	for script in scripts:
		script.end()
		scripts.erase(script)
		
func show_in_debugger():
	if not main or not main.get_tree():
		return
	var debugger = main.get_tree().get_nodes_in_group("ScriptDebugger")
	if debugger:
		debugger[0].update_current_stack(self)

# TODO rewrite core loop to happen here instead of in the script
# 1. execute next line from top script
# 2. if that line adds a new script to the stack, next time through the loop will hit the top script
# 3. update debuggers/logging etc
# 4. keep doing this until we yield to godot, which we do if there are:
#    - any blockers within the world
#    - any commands execute that require the screen to be updated
func process():
	if not scripts:
		if state == STACK_PROCESSING:
			emit_signal("stack_empty")
			#state = STACK_COMPLETE
		return
	while scripts and state == STACK_PROCESSING:
		var frame = scripts[-1].process_wrightscript()
		show_in_debugger()
		print(frame)
		if frame.sig is int:
			if frame.sig == Commands.YIELD:
				#yield(main.get_tree(), "idle_frame")
				frame.scr.next_line()
				return
			elif frame.sig == Commands.UNDEFINED:
				main.log_error("No command for "+frame.command)
				frame.scr.next_line()
				return
			elif frame.sig == Commands.NOTIMPLEMENTED:
				print("not implemented command "+frame.command)
				frame.scr.next_line()
				return
			elif frame.sig == Commands.DEBUG:
				show_in_debugger()
				yield(main.get_tree(), "idle_frame")
				print(" - debug - ")
				frame.scr.next_line()
				return
			elif frame.sig == Commands.END:
				if frame.scr in scripts:
					scripts.erase(frame.scr)
				return
			elif frame.sig == Commands.NEXTLINE:
				frame.scr.next_line()
				continue
			else:
				print("undefined return")
				frame.scr.next_line()
				return
		elif frame.sig is SceneTreeTimer:
			#yield(main.get_tree(), "idle_frame")
			yield(frame.sig, "timeout")
			print("timer:", frame.sig)
			frame.scr.next_line()
			return
			#continue
		elif frame.sig and frame.sig.get("wait_signal"):
			print("start wait")
			state = STACK_YIELD
			yield(frame.sig, frame.sig.get("wait_signal"))
			print("stop wait")
			state = STACK_PROCESSING
			frame.scr.next_line()
			return
