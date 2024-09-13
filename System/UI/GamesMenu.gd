extends Node

signal game_loaded
var z := 0
var choose_game_dir_dialog:FileDialog

var focused = false

func add_pck_button(path):
	var txt = path.replace("_"," ").replace(".pck","")
	game_item_select_list.append(path)
	$Control/ItemList.add_item(txt)

var game_item_select_list := []
func add_game_button(path:String, game:String):
	print("game path:",path,game)
	$Control/ItemList.add_item(game)
	if not path.ends_with("/"):
		path += "/"
	game_item_select_list.append(path+game)

func add_test_button(path):
	var hbox = HBoxContainer.new()
	var b = Button.new()
	b.text = "play>"
	b.align = Button.ALIGN_LEFT
	b.connect("pressed", self, "launch_game", [path, "play"])
	hbox.add_child(b)
	b = Button.new()
	b.text = "{test}"
	b.align = Button.ALIGN_LEFT
	b.connect("pressed", self, "launch_game", [path, "test"])
	hbox.add_child(b)
	var l = Label.new()
	l.text = path
	hbox.add_child(l)
	$Control/ScrollContainer2/VBoxContainer.add_child(hbox)

func _clear_games():
	focused = false
	game_item_select_list.clear()
	$Control/ItemList.clear()
	$Control/PlayButton.visible = false

# types = "pack", "folder", "test"
func _populate_games(folder, types):
	assert(types in ["pack", "folder", "test"])
	var listing = Directory.new()
	if listing.open(folder) != OK:
		return null
	listing.list_dir_begin()
	var next_file_name = listing.get_next()
	while next_file_name != "":
		if types == "pack" and next_file_name.ends_with(".pck"):
			add_pck_button(next_file_name)
		if types == "folder" and not next_file_name.begins_with("."):
			add_game_button(folder, next_file_name)
		if types == "test" and next_file_name.ends_with(".txt"):
			add_test_button(next_file_name)
		next_file_name = listing.get_next()


func _ready():
	name = "GamesMenu"
	get_node("%MainLabel").text = "GodotWright version "+Configuration.builtin.version

	choose_game_dir_dialog = $Control/ChooseGameDirDialog
	choose_game_dir_dialog.connect("dir_selected", self, "_game_dir_selected")

	_clear_games()

	if Configuration.user.game_list == "internal":
		choose_builtin_games()
	else:
		_populate_games(Configuration.user.game_folder, "folder")

	_populate_games("res://tests/", "test")

	$Control/HBoxContainer/ChooseGameDir.connect("pressed", self, "choose_game_dir")
	$Control/HBoxContainer/BuiltinGames.connect("pressed", self, "choose_builtin_games")
	$Control/ItemList.connect("item_selected", self, "item_selected")
	$Control/ItemList.connect("item_activated", self, "item_activated")
	$Control/PlayButton.connect("pressed", self, "play_item_selected")

func item_selected(index):
	$Control/PlayButton.visible = true

func item_activated(index):
	play_item_selected()

func play_item_selected():
	var indexes = $Control/ItemList.get_selected_items()
	if indexes:
		self.launch_game(game_item_select_list[indexes[0]], "play")

func choose_game_dir():
	var d := choose_game_dir_dialog
	d.current_path = "/"
	if Configuration.user.game_folder:
		d.current_path = Configuration.user.game_folder+"/"
	d.show()
	d.invalidate()

func choose_builtin_games():
	_clear_games()
	_populate_games("user://", "pack")
	_populate_games("res://games/", "folder")
	Configuration.user.game_list = "internal"
	Configuration.save_config()

func _game_dir_selected(dir):
	_clear_games()
	Configuration.user.game_list = "external"
	Configuration.user.game_folder = dir
	Configuration.save_config()
	_populate_games(dir, "folder")

func launch_game(path, mode="play"):
	emit_signal("game_loaded", path, mode)
	queue_free()
