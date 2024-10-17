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
	STACK_READY,		# ready for action
	STACK_PROCESSING,	# currently exectuing the script
	STACK_COMPLETE,		# This stack (game, case) has finished
	STACK_YIELD,        # allow a frame to be endered
	STACK_DEBUG			# set up debugger
}
var state = STACK_READY

var mode = "play"  # play = play game normally, test = running unit tests

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
signal game_inited

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
	emit_signal("game_inited")


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

func force_clear_blockers():
	for script in scripts:
		for blocker in script.blockers:
			script.remove_blocker(null, blocker, null, false)

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
		if scripts[-1].check_blocked():
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
			frame.scr.add_blocker(frame.sig, true)
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

static func create_node(saved_data:Dictionary):
	pass

func load_node(tree, saved_data:Dictionary):
	SaveState._load_node(tree, variables, saved_data["variables"])

func after_load(tree, saved_data:Dictionary):
	scripts.clear()
	# Add a script and copy its state
	for script_data in saved_data["scripts"]:
		var script = WrightScript.new(main, self)
		SaveState._load_node(tree, script, script_data)
		scripts.append(script)
		script.after_load(tree, script_data)
	#show_in_debugger()
	old_save_blocker_fix(tree, saved_data)
	emit_signal("game_inited")

# We used to save blockers a different way
func old_save_blocker_fix(tree, saved_data:Dictionary):
	if "blocked_scripts" in saved_data and "blockers" in saved_data:
		var uid_script = {}
		for script in scripts:
			uid_script[script.u_id] = script
		for i in range(min(saved_data["blocked_scripts"].size(), saved_data["blockers"].size())):
			var script_uid = saved_data["blocked_scripts"][i]
			if not script_uid in uid_script:
				continue
			var script = uid_script[script_uid]
			var blocker_data = saved_data["blockers"][i]
			var blocker
			if blocker_data["type"] == "Node":
				blocker = main.get_node(blocker_data["node_path"])
			if blocker:
				script.add_blocker(blocker, true)
