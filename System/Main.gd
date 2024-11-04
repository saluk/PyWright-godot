extends Node2D
class_name MainScene

var stack: WrightScriptStack
var timecounter: TimeCounter
var current_game: String

var screens
onready var options_tab:Control = get_tree().get_nodes_in_group("SidePanel")[0]
onready var tab_container:TabContainer = get_tree().get_nodes_in_group("TabContainer")[0]
onready var tab_button:Button = get_tree().get_nodes_in_group("TabButton")[0]

# A weird quirk of PyWright means that even if you clear a surface, the mesh sticks around
# This ensures there is only one 3d examine mesh loaded
# Whenever we create a Node3D, reload the last mesh here into the scene
var examine_meshes = []
var examine_state = []

var authored_size = Vector2(256, 384)

var init_script = """
mus 02 - courtroom lounge ~ beginning prelude.ogg
set _textbox_lines 2
set _debug true
char Titus
"This is a test{n}Should be 2 lines shown{n}This is a third line... NO!"
set _textbox_lines 3
char phoenix
"This is the next line{n}How many lines are shown{n}should be 3"
"""

signal stack_initialized
signal before_frame_drawn
signal frame_drawn
signal line_executed
signal text_finished
signal enable_saveload_buttons

var font_cache := LeastUsedCache.new(10)

func reset():
	MusicPlayer.stop_music()
	SoundPlayer.stop_sounds()
	stack.clear_scripts()
	ScreenManager.clear()
	font_cache.clear()
	timecounter.reset()

func load_game_from_pack(path):
	reset()
	ProjectSettings.load_resource_pack("user://"+path)

	# Find the game in the directory
	var game
	var d = Directory.new()
	if d.open("res://games") == OK:
		d.list_dir_begin()
		game = d.get_next()

	if game:
		set_current_game("res://games/"+game)
	else:
		assert(false)

func set_current_game(path):
	current_game = path
	stack.init_game(path)
	emit_signal("stack_initialized")

func load_script_from_path(path):
	reset()
	#stack.load_script("res://tests/"+path)
	#stack.load_macros_from_path("macros")
	current_game = "res://tests"
	stack.init_game(current_game, path)
	emit_signal("stack_initialized")

func _ready():
	ScreenManager._init_screens()
	screens = get_tree().get_nodes_in_group("Screens")[0]
	timecounter = TimeCounter.new()
	add_child(timecounter)

	tab_button.connect("toggled", self, "_toggle_button")
	if not Configuration.user.options_open:
		hide_tabs()
	else:
		tab_button.pressed = true

	stack = WrightScriptStack.new(self)
	stack.connect("stack_empty", self, "reload")
	Commands.load_command_engine()

	# TODO move tests for this elsewhere
	test_eval()
	stack.variables.reset()

	var loader = load("res://System/UI/GamesMenu.tscn").instance()
	ScreenManager.main_screen.add_child(loader)
	var array = yield(loader, "game_loaded")
	var path = array[0]
	var mode = array[1]
	if path.ends_with(".pck"):
		load_game_from_pack(path)
	elif path.ends_with(".txt"):
		load_script_from_path(path)
	else:
		set_current_game(path)

	if mode == "test":
		screens.rect_global_position = Vector2(0,0)
	stack.mode = mode

	stack.connect("game_inited", self, "check_saving_enabled")
func test_eval():
	stack.variables.set_val("is_true", "true")
	stack.variables.set_val("is_false", "false")
	stack.variables.set_val("is_int", "1010")
	stack.variables.set_val("is_float", "10.15")
	assert(WSExpression.EVAL("is_true"))
	assert(not WSExpression.EVAL("is_false"))
	assert(WSExpression.GV("'string'") == "string")
	assert(WSExpression.GV("0") == 0)
	assert(WSExpression.GV("0.0") == 0.0)
	assert(WSExpression.GV("is_true") == "true")
	assert(WSExpression.GV("is_int") == 1010)
	assert(WSExpression.GV("is_float") == 10.15)
	assert(WSExpression.EQ(["1","1"]) == "true")
	assert(WSExpression.EQ(["1","0"]) == "false")
	assert(WSExpression.OR(["is_true", "is_false"]) == true)
	assert(WSExpression.OR2(["false", "true"]) == "true")
	assert(WSExpression.OR2(["true", "false"]) == "true")
	var x = WSExpression.EVAL_STR("is_int == 1010")
	assert(x == "true")
	assert(WSExpression.EVAL_STR("is_int 1010") == "true")
	assert(WSExpression.EVAL_STR("(5 == 4 OR 5 == 5)") == "true")
	x = WSExpression.EVAL_STR("(5 == 4 OR 5 == 5) AND (1 + 3 == 4) OR ('funny' == 'not funny')")
	assert(WSExpression.EVAL_STR("(5 == 4 OR 5 == 5) AND (1 + 3 == 4) OR ('funny' == 'not funny')") == "true")
	assert(WSExpression.EVAL_STR("2 * (5 + 1) == (5 + 1) * 2") == "true")
	assert(WSExpression.EVAL_STR("2 * (5 + 1)") == "12")
	assert(WSExpression.EVAL_STR("5 + 1 + 3 * 10") == "36")
	assert(WSExpression.EVAL_STR("'funny ' + 'business'") == "funny business")
	stack.variables.set_val("something", "1")
	assert(WSExpression.EVAL_STR("5 + something + 3 * 10") == "36")
	assert(WSExpression.EVAL_STR("(5 == 4 OR 5 == 5) AND (1 + 3 == 4) AND ('funny' = 'not funny')") == "false")
	assert(WSExpression.EVAL_STR("5 > 3") == "true")
	assert(WSExpression.EVAL_STR("5 > 6") == "false")
	assert(WSExpression.EVAL_STR("5 < 3") == "false")
	stack.variables.set_val("door", "5")
	assert(WSExpression.EVAL_STR("door >= 4") == "true")
	assert(WSExpression.EVAL_STR("door >= 6") == "false")
	assert(WSExpression.EVAL_STR("unset_variable == 6") == "false")
	assert(WSExpression.EVAL_STR(
		WSExpression.SIMPLE_TO_EXPR("$is_int == 1010")) == "true")
	assert(WSExpression.EVAL_STR(
		WSExpression.SIMPLE_TO_EXPR("$is_int >= 1010")) == "true")
	assert(WSExpression.EVAL_STR(
		WSExpression.SIMPLE_TO_EXPR("$is_int < 1011")) == "true")
	assert(WSExpression.EVAL_STR(
		WSExpression.SIMPLE_TO_EXPR("$is_int > 500")) == "true")
	assert(WSExpression.SIMPLE_TO_EXPR("$is_true == true") == "is_true == 'true'")
	assert(WSExpression.EVAL_STR(
		WSExpression.SIMPLE_TO_EXPR("$is_true == true")) == "true")
	assert(WSExpression.EVAL_STR(
		WSExpression.SIMPLE_TO_EXPR("$is_true == false")) == "false")
	stack.variables.set_val("_diamond_count_internal", "0")
	assert(WSExpression.EVAL_STR(
		WSExpression.SIMPLE_TO_EXPR("$_diamond_count_internal < 1")) == "true")
	stack.variables.set_val("_cr_button", "true")
	x = WSExpression.EVAL_SIMPLE("_cr_button")
	assert(x == true)

func _process(_delta):
	emit_signal("before_frame_drawn")
	if stack:
		# IF stack.state == stack.STATE_PROCESSING we are already running the process() function
		if stack.state in [stack.STACK_READY, stack.STACK_YIELD]:
			stack.process()
	if stack:
		stack.show_in_debugger()
	emit_signal("frame_drawn")

func top_script(screen=null):
	if screen:
		for i in range(stack.scripts.size()):
			if stack.scripts[-i].screen == screen:
				return stack.scripts[-i]
	if stack and stack.scripts and stack.scripts.size() > 0:
		return stack.scripts[-1]
	return null

func bottom_script():
	if stack.scripts.size() > 0:
		return stack.scripts[0]
	return null

# Return topmost script that is in a cross examination
func cross_exam_script():
	if stack.scripts.size() > 0:
		for i in range(stack.scripts.size()):
			if stack.scripts[-i-1].is_inside_cross():
				return stack.scripts[-i-1]
	return null

func reload():
	reset()
	get_tree().reload_current_scene()

func pause(paused=true, toggle=false):
	if toggle:
		paused = not is_processing()
	else:
		paused = paused
	var nodes = [self]
	var node:Node
	while nodes:
		node = nodes.pop_front()
		node.set_process(paused)
		for child in node.get_children():
			nodes.append(child)

# Determine whether we are in a savable case
func is_saving_enabled():
	if not stack:
		return false
	# The bottom most script should be running the intro.txt for our game or case
	var script:WrightScript = bottom_script()
	if not script:
		return false
	for line in script.lines:
		if "casemenu" in line.strip_edges():
			return false
	return true

func check_saving_enabled():
	if is_saving_enabled():
		emit_signal("enable_saveload_buttons", true, true)
	else:
		emit_signal("enable_saveload_buttons", false, false)

# OPTIONS

func _toggle_button(state):
	if state:
		show_tabs()
	else:
		hide_tabs()

func show_tabs():
	tab_button.pressed = true
	tab_container.show()
	#options_tab.rect_position.x = get_viewport().size.x-256*options_tab.rect_scale.x
	options_tab.rect_min_size = Vector2(256*2,384*2)
	Configuration.set_and_save("options_open", true)

func hide_tabs():
	tab_button.pressed = false
	tab_container.hide()
	#options_tab.rect_position.x = get_viewport().size.x
	options_tab.rect_min_size = Vector2(0,0)
	Configuration.set_and_save("options_open", false)

# TODO hacky way to handle orphans
signal freeing_orphans
func free_orphans():
	emit_signal("freeing_orphans")
func connect_potential_orphan(obj):
	connect("freeing_orphans", obj, "_free_orphan")

# Input

func _on_Screens_gui_input(event):
	var owner = get_node("InputController").get_focus_owner()
	if owner:
		owner.release_focus()

# SAVE/LOAD
var save_properties = [
	"current_game"
]
func save_node(data):
	data["timecounter.elapsed"] = timecounter.get_current_elapsed_time()
	data["stack"] = SaveState._save_node(stack)

static func create_node(saved_data:Dictionary):
	pass

func load_node(tree, saved_data:Dictionary):
	set_current_game(current_game)
	timecounter.set_elapsed_time(saved_data["timecounter.elapsed"])
	SaveState._load_node(tree, stack, saved_data["stack"])

func after_load(tree, saved_data:Dictionary):
	stack.state = stack.STACK_READY
	stack.after_load(tree, saved_data["stack"])
