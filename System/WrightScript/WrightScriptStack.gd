extends Reference
class_name WrightScriptStack

var main
var scripts := []

# Contains all namespaces except for scripts and objects
var variables:NameSpaces
var evidence_pages := {

}

var macros := {}

# TODO not actually used, as filesystem is all static
var filesystem

enum {
	STACK_READY,
	STACK_PROCESSING,
	STACK_COMPLETE,
	STACK_YIELD,
	STACK_DEBUG
}
var state = STACK_READY

var mode = "play"  # play = play game normally, test = running unit tests

var blockers = []
var blocked_scripts = []
var yields = []  # functions to resume

var REPEAT_MAX = 6  #If nonzero, and the same line is attempted to execute more than this value, drop to the debugger
var watched_commands = []  #Any commands that should enter the debugger

var repeated = {"line":null, "line_num": -1, "amount": 0}

var testing

func _init(main):
	assert(main)
	self.main = main
	variables = NameSpaces.new()
	variables.main = main
	filesystem = load("res://System/Files/Filesystem.gd").new()
	testing = Testing.new()

signal stack_empty
signal enter_debugger
signal line_executed   # emit when any script executes a line
signal script_added
signal script_removed
signal update_debugger

var macro_scripts_found = 0

var run_macros_on_game_start = [
	"init_defaults",
	"font_defaults",
	"load_defaults",
	"init_court_record_settings"
]

var run_macros_on_load_player_save = [
	"load_defaults",
	"init_court_record_settings"
]

var run_macros_on_scene_change = [
	"defaults"
]

func load_macros_from_path(path):
	var macro_scripts = []
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
				print("Info: Adding macros from %s" % file_name)
				var script = WrightScript.new(main, self)
				script.stack = self
				script.load_txt_file(Filesystem.path_join(path, file_name), false)
				macro_scripts.insert(0, script)
				macro_scripts_found += 1
	else:
		print("COULDN'T OPEN DIRECTORY")
	# We search from most child path to most parent,
	# we want to execute the parents before the children
	for script in macro_scripts:
		print("MACRO LOADED: ", script.root_path, ":", script.filename)
		script.preprocess_lines()

func run_macro_set(l):
	if scripts:
		for macro in l:
			Commands.call_macro(macro, scripts[-1], [])

func init_game(path, init_script="intro.txt"):
	DirectoryCache.init_game(path)
	# Used to load a game and then a case inside the game
	filesystem = load("res://System/Files/Filesystem.gd").new()
	print("load base macros")
	load_macros_from_path("res://macros")
	# TODO - if we are loading a subfolder of a game, we should load macros
	#		 from the parent folder as well
	#		 except... we already loaded the macros for the game when we ran the games intro.txt,
	#		 and those macros should stick around
	load_script(path+"/"+init_script)
	if not scripts[-1].lines.size():
		add_script("casemenu", path)
	run_macro_set(run_macros_on_game_start)
	if not macro_scripts_found:
		print("MACRO ERROR")

func add_script(script_text, root_path="res://"):
	var new_script = WrightScript.new(main, self)
	new_script.load_string(script_text)
	new_script.root_path = root_path
	scripts.append(new_script)
	emit_signal("script_added")
	return new_script

func load_script(script_path):
	var new_script = WrightScript.new(main, self)
	new_script.load_txt_file(script_path)
	scripts.append(new_script)
	emit_signal("script_added")
	return new_script

func remove_script(script):
	if script in scripts:
		scripts.erase(script)
		emit_signal("script_removed")
		script.end()

func clear_scripts():
	while scripts:
		scripts[0].end()
		scripts.erase(scripts[0])
		emit_signal("script_removed")

func show_in_debugger():
	if not main or not is_instance_valid(main) or not main.get_tree():
		return
	if not Configuration.user.debugger_enabled:
		return
	emit_signal("update_debugger")

func show_frame(frame, begin=false):
	if not variables.get_truth("render", true):
		return
	if not main or not is_instance_valid(main) or not main.get_tree():
		return
	var framelog = main.get_tree().get_nodes_in_group("FrameLog")
	if framelog:
		if begin:
			framelog[0].log_frame_begin()
		else:
			framelog[0].log_frame_end(frame)

func clean_scripts():
	"""Remove any scripts that should be ended"""
	var newscripts = []
	var removal = false
	for scr in scripts:
		if scr.line_num >= scr.lines.size():
			print("remove script ", scr.filename)
			removal = true
		else:
			newscripts.append(scr)
	scripts = newscripts
	if removal:
		emit_signal("script_removed")
		ScreenManager.clean(scripts)
	show_in_debugger()

func new_state(state):
	self.state = state

# TODO script blockers feel overengineered.

func blocked(scr):
	if scr in blocked_scripts:
		return true

func add_blocker(script, block_obj, next_line = true):
	if block_obj in blockers:
		return
	blockers.append(block_obj)
	if not script in blocked_scripts:
		blocked_scripts.append(script)
	var sig = "timeout"
	if block_obj.get("wait_signal"):
		sig = block_obj.get("wait_signal")
	var original_id
	if "name" in block_obj:
		original_id = block_obj.name
	else:
		original_id = block_obj
	block_obj.connect(sig, self, "remove_blocker", [sig, script, block_obj, original_id, next_line], CONNECT_ONESHOT)

func remove_blocker(sig, script, block_obj, original_id, next_line):
	if block_obj in blockers:
		blockers.erase(block_obj)
		if script in blocked_scripts:
			if next_line:
				script.next_line()
			blocked_scripts.erase(script)

func force_clear_blockers():
	for obj in blockers:
		if is_instance_valid(obj) and obj is SceneTreeTimer:
			pass
		elif obj:
			obj.queue_free()
	blockers = []
	for scr in blocked_scripts:
		scr.next_line()
	blocked_scripts = []

# TODO simplify process, we have more states than we need now that we almost never yield or return from the while loop
func process():
	var frame
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
	while yields:
		if not variables.get_truth("render", true):
			break
		#show_in_debugger()
		var new_yields = []
		for f in yields:
			if f.sig is GDScriptFunctionState and f.sig.is_valid():
				f.sig.resume()
				new_yields.append(f)
			else:
				frame = f
				break
		yield(main.get_tree(), "idle_frame")
		continue
	while scripts:
		if state != STACK_PROCESSING:
			return
		clean_scripts()
		if not scripts:
			return new_state(STACK_YIELD)
		if blocked(scripts[-1]) and blockers:
			if variables.get_truth("render", true):
				yield(main.get_tree(), "idle_frame")
				continue
		# We may have a paused frame from before to keep processing
		show_frame(null, true)
		frame = scripts[-1].process_wrightscript()
		if not frame.line.begins_with("ut_"):
			show_frame(frame)
			#show_in_debugger()
			main.emit_signal("line_executed")
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
				#return new_state(STACK_YIELD)
			elif frame.sig == Commands.UNDEFINED:
				GlobalErrors.log_error("No command for '"+frame.command+"'", {"frame": frame})
				frame.scr.next_line()
				#return new_state(STACK_YIELD)
			elif frame.sig == Commands.NOTIMPLEMENTED:
				print("not implemented command "+frame.command)
				frame.scr.next_line()
				#return new_state(STACK_YIELD)
			elif frame.sig == Commands.DEBUG:
				#show_in_debugger()
				print(" - debug - ")
				frame.scr.next_line()
				emit_signal("enter_debugger")
				return new_state(STACK_DEBUG)
			elif frame.sig == Commands.END:
				if frame.scr in scripts:
					scripts.erase(frame.scr)
					emit_signal("script_removed")
				return new_state(STACK_YIELD)
			elif frame.sig == Commands.NEXTLINE:
				frame.scr.next_line()
				continue
			else:
				print("undefined return")
				frame.scr.next_line()
				#return new_state(STACK_YIELD)
		elif frame.sig is SceneTreeTimer or (frame.sig and frame.sig.get("wait_signal") and frame.sig.get("wait") in [null, true]):
			add_blocker(frame.scr, frame.sig, true)
		elif frame.sig is GDScriptFunctionState:
			#show_in_debugger()
			yields.append(frame)
			#return new_state(STACK_YIELD)
		else:
			frame.scr.next_line()
			# TODO Leaving the script running every line in a single frame is
			# leading to jerkiness. C#?
			#return new_state(STACK_YIELD)



# SAVE/LOAD
var save_properties = [
	"evidence_pages",
	# "macros",
	"state",
	"mode",
	# "blockers",
	# "blocked_scripts",
	#  "yields",
	# "macro_scripts_found"
]
func save_node(data):
	# Save script text and state for each script
	var saved_scripts = []
	for script in scripts:
		saved_scripts.append(SaveState._save_node(script))
	data["scripts"] = saved_scripts
	data["variables"] = SaveState._save_node(variables)
	# blocked scripts
	data["blockers"] = []
	for blocker in blockers:
		if not is_instance_valid(blocker):
			continue
		if blocker is SceneTreeTimer:
			data["blockers"].append({"type": "SceneTreeTimer", "time_left":blocker.time_left})
		else:
			if blocker.has_method("get_path"):
				data["blockers"].append({"type": "Node", "node_path": blocker.get_path()})
	data["blocked_scripts"] = []
	for script in blocked_scripts:
		data["blocked_scripts"].append(script.u_id)

static func create_node(saved_data:Dictionary):
	pass

func load_node(tree, saved_data:Dictionary):
	SaveState._load_node(tree, variables, saved_data["variables"])

func after_load(tree, saved_data:Dictionary):
	scripts.clear()
	blockers = []
	blocked_scripts = []
	# Add a script and copy its state
	for script_data in saved_data["scripts"]:
		var script = WrightScript.new(main, self)
		SaveState._load_node(tree, script, script_data)
		scripts.append(script)
	#show_in_debugger()
	if "blockers" in saved_data:
		for blocker in saved_data["blockers"]:
			if blocker["type"] == "SceneTreeTimer":
				pass # todo implement
			elif blocker["type"] == "Node":
				var n = main.get_tree().root.get_node(blocker["node_path"])
				if n:
					add_blocker(main.top_script(), n, true)
	if "blocked_scripts" in saved_data:
		for script in scripts:
			if script.u_id in saved_data["blocked_scripts"]:
				blocked_scripts.append(script)
	if blocked_scripts and not blockers:
		force_clear_blockers()
