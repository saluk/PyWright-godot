extends Node2D

var cases = []
var wrightscript

signal CASE_SELECTED
var wait_signal = "CASE_SELECTED"

var focused = false
var case_chosen = 0

var z = 2
var game_data = {}
		
func get_data():
	var path = wrightscript.root_path + "data.txt"
	var data = {}
	var f = File.new()
	var err = f.open(path, File.READ)
	if err == OK:
		while not f.eof_reached():
			var line = f.get_line()
			if not line.strip_edges():
				continue
			var key_value = line.split(" ", true, 1)
			if key_value.size() == 2:
				data[key_value[0]] = key_value[1]
		f.close()
	return data
	
func _ready():
	game_data = get_data()
	var game_name
	if "title" in game_data:
		game_name = game_data["title"]
	else:
		game_name = wrightscript.root_path
		game_name = game_name.rstrip("/")
		game_name = game_name.split("/")[-1]
	$Control/GameTitle.text = game_name
	build_scene()
	connect_arrows()
	
func current_case():
	return cases[case_chosen]
	
func set_user_defined_background():
	var case_screen = current_case() + "/case_screen"
	Commands.call_command(
		"script",
		wrightscript, [
		case_screen,
		"noclear",
		"return"
	])
	
func build_scene():
	set_user_defined_background()
	SignalUtils.remove_all($Control/ScrollContainer2/VBoxContainer/NewGameButton)
	SignalUtils.remove_all($Control/ArrowLeft)
	SignalUtils.remove_all($Control/ArrowRight)
	SignalUtils.remove_all($Control/ScrollContainer2/VBoxContainer/ResumeButton)
	$Control/ScrollContainer2/VBoxContainer/CaseBox/CaseTitle.bbcode_text = "[center][b]%s[/b][/center]"%current_case()
	$Control/ArrowLeft.visible = false
	$Control/ArrowRight.visible = false
	$Control/ScrollContainer2/VBoxContainer/NewGameButton.connect("pressed", self, "launch_game")
	$Control/ScrollContainer2/VBoxContainer/ResumeButton.visible = false
	connect_resume()
	
func connect_arrows():
	if case_chosen < cases.size()-1:
		$Control/ArrowRight.visible = true
		$Control/ArrowRight.connect("pressed", self, "next_case")
	if case_chosen > 0:
		$Control/ArrowLeft.visible = true
		$Control/ArrowLeft.connect("pressed", self, "prev_case")
		
func connect_resume():
	var main = get_tree().get_nodes_in_group("Main")[0]
	var saves = SaveState.get_saved_games_for_current(main, wrightscript.root_path+current_case())
	if saves:
		$Control/ScrollContainer2/VBoxContainer/ResumeButton.visible = true
		$Control/ScrollContainer2/VBoxContainer/ResumeButton.connect("pressed", self, "launch_game", [null, saves[-1]])
	
func _scroll(direction):
	SignalUtils.remove_all($Control/ArrowLeft)
	SignalUtils.remove_all($Control/ArrowRight)
	case_chosen += direction
	var tween = Tween.new()
	add_child(tween)
	var start_pos = $Control/ScrollContainer2.rect_position
	tween.interpolate_property($Control/ScrollContainer2, "rect_position",
			start_pos, 
			start_pos - Vector2(256,0) * direction, 0.2,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween,"tween_completed")
	Commands.call_command("sound_case_menu_select", wrightscript, [])
	build_scene()
	tween.interpolate_property($Control/ScrollContainer2, "rect_position",
			start_pos + Vector2(256, 0) * direction,
			start_pos, 0.2,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween,"tween_completed")
	remove_child(tween)
	connect_arrows()

func next_case():
	_scroll(1)
	
func prev_case():
	_scroll(-1)

func launch_game(path=null, save=null):
	var tree = get_tree()
	if not path:
		path = current_case()
	print("launching case ", path)
	Commands.call_command(
		"script",
		wrightscript, [
		path+"/intro"
	])
	if save:
		SaveState.load_selected_save_file(tree.get_nodes_in_group("Main")[0], save)
	queue_free()
	Commands.main.timecounter.reset()
	emit_signal("CASE_SELECTED")

