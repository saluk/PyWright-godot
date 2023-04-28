extends Node2D
class_name MainScene

var stack: WrightScriptStack

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
signal frame_drawn
signal line_executed
signal text_finished

func main_screen():
	return get_tree().get_nodes_in_group("MainScreen")[0]

func load_game_from_pack(path):
	ProjectSettings.load_resource_pack("user://"+path)
	
	# Find the game in the directory
	var game
	var d = Directory.new()
	if d.open("res://games") == OK:
		d.list_dir_begin()
		game = d.get_next()
	
	if game:
		load_game("res://games/"+game)
	else:
		assert(false)
		
func load_game(path):
	stack.init_game(path)
	stack.connect("stack_empty", self, "reload")
	emit_signal("stack_initialized")
		
func load_script_from_path(path):
	stack.load_script("res://tests/"+path)
	stack.load_macros_from_path("macros")
	stack.connect("stack_empty", self, "reload")
	emit_signal("stack_initialized")
	
func set_resolution(res:Vector2, scale:float, show_debugger:bool=false):
	var w = res.x
	if show_debugger:
		w *= 2
	var h = res.y
	OS.set_window_size(Vector2(w*scale, h*scale))
	var screen_size:Vector2 = OS.get_screen_size()
	OS.window_position = Vector2(screen_size.x/2-w*scale/2, screen_size.y/2-h*scale/2)
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(w, h), 1)

func _ready():
	if OS.has_feature("standalone") or OS.has_feature("HTML5"):
		set_resolution(Vector2(256,384), 2.0, false)
	else:
		set_resolution(Vector2(256,384), 2.0, true)
	
	stack = WrightScriptStack.new(self)
	Commands.load_command_engine()
	
	# TODO move tests for this elsewhere
	test_eval()
	stack.variables.reset()
	
	var loader = load("res://System/UI/GamesMenu.tscn").instance()
	main_screen().add_child(loader)
	var array = yield(loader, "game_loaded")
	var path = array[0]
	var mode = array[1]
	if path.ends_with(".pck"):
		load_game_from_pack(path)
	elif path.ends_with(".txt"):
		load_script_from_path(path)
	else:
		load_game(path)
	stack.mode = mode
		
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
	if stack:
		if stack.state in [stack.STACK_READY, stack.STACK_YIELD]:
			stack.process()
	emit_signal("frame_drawn")

func log_error(msg):
	stack.show_in_debugger()
	print("ERROR:", msg)
	#var txt = load("res://System/UI/Textbox.tscn").instance()
	#txt.text_to_print = msg
	#txt.main = self
	#add_child(txt)

func top_script():
	if stack.scripts.size() > 0:
		return stack.scripts[-1]
	return null

# Return topmost script that is in a cross examination
func cross_exam_script():
	if stack.scripts.size() > 0:
		for i in range(stack.scripts.size()):
			if stack.scripts[-i-1].is_inside_cross():
				return stack.scripts[-i-1]
	return null

func reload():
	MusicPlayer.stop_music()
	# TODO stop running sounds
	get_tree().reload_current_scene()

func pause(paused=true, toggle=false):
	if toggle:
		paused = not is_processing()
	var nodes = [self]
	var node:Node
	while nodes:
		node = nodes.pop_front()
		node.set_process(paused)
		for child in node.get_children():
			nodes.append(child)
