extends Node2D

var cases = []
var wrightscript

signal CASE_SELECTED
signal SCROLL_FINISHED
var wait_signal = "CASE_SELECTED"

var focused = false
var case_chosen = 0

var z = 2
var game_data = {}

onready var newgame = $Control/ScrollContainer2/VBoxContainer/NewGameButton/NewGame
onready var resume = $Control/ScrollContainer2/VBoxContainer/ResumeButton/Resume

func get_data():
	var path = wrightscript.root_path + "data.txt"
	var data = {
		"title": wrightscript.root_path.rsplit("/", 1)[-1]
	}
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
	Fonts.set_element_font($Control/GameTitle, "gametitle", wrightscript.main)
	build_scene()
	connect_arrows()
	load_last_case()

func get_last_case_file():
	if not "title" in game_data:
		return null
	var game_name = Filesystem.sanitize_text_for_path(game_data["title"])
	var last_case = "user://recent_cases/"
	Filesystem.make_if_not_exists_dir(last_case)
	last_case+=game_name
	return last_case

func load_last_case():
	var last_case = get_last_case_file()
	if not last_case:
		return
	var f:File = File.new()
	if f.file_exists(last_case):
		f.open(last_case, File.READ)
		var case_name = f.get_line()
		f.close()
		if case_name in cases:
			while cases[case_chosen] != case_name:
				_scroll(1)
				yield(self, "SCROLL_FINISHED")

func save_last_case():
	var last_case = get_last_case_file()
	if not last_case:
		return null
	var f:File = File.new()
	f.open(last_case, File.WRITE)
	f.store_line(cases[case_chosen])
	f.close()

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
	Fonts.set_element_font(get_node("%CaseTitle"), "gametitle", wrightscript.main)
	get_node("%CaseTitle").bbcode_text = "[center][b]%s[/b][/center]"%current_case().replace("_"," ")
	$Control/ArrowLeft.visible = false
	$Control/ArrowRight.visible = false
	$Control/ScrollContainer2/VBoxContainer/NewGameButton.connect("pressed", self, "launch_game")
	$Control/ScrollContainer2/VBoxContainer/ResumeButton.visible = false
	Fonts.set_element_font(newgame, "new_resume", wrightscript.main)
	Fonts.set_element_font(resume, "new_resume", wrightscript.main)
	newgame.bbcode_text = "[center][b]%s[/b][/center]"%"New Game"
	resume.bbcode_text = "[center][b]%s[/b][/center]"%"Resume"
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
	var saves = SaveState.get_saved_games_for_current(
		GamePath.new().from_path(
			wrightscript.root_path+"/"+current_case()
	))
	var optionsTab = get_tree().get_nodes_in_group("OptionsTab")[0]
	optionsTab._enable_saveload_buttons(true, false, saves)
	if saves:
		optionsTab.root_save_game = wrightscript.root_path+"/"+current_case()
		$Control/ScrollContainer2/VBoxContainer/ResumeButton.visible = true
		$Control/ScrollContainer2/VBoxContainer/ResumeButton.connect("pressed", self, "launch_game", [null, saves[-1][1]])

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
	tween.queue_free()
	connect_arrows()
	emit_signal("SCROLL_FINISHED")

func next_case():
	_scroll(1)

func prev_case():
	_scroll(-1)

func launch_game(path=null, save=null):
	save_last_case()
	var tree = get_tree()
	if not path:
		path = current_case()
	print("launching case ", path)
	Commands.call_command(
		"script",
		wrightscript, [
		path+"/intro"
	])
	var main = tree.get_nodes_in_group("Main")[0]
	if save:
		SaveState.load_selected_save_file(main, main.top_script().root_path, save)
	queue_free()
	Commands.main.timecounter.reset()
	emit_signal("CASE_SELECTED")
	main.stack.emit_signal("game_inited")
