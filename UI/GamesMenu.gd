extends Node

signal game_loaded

func add_pck_button(path):
	var txt = path.replace("_"," ").replace(".pck","")
	var b = Button.new()
	b.text = txt
	b.connect("pressed", self, "launch_game", [path])
	$Control/ScrollContainer/VBoxContainer.add_child(b)
	
func add_game_button(path):
	var txt = path.replace("_"," ")
	var b = Button.new()
	b.text = "games/"+txt
	b.connect("pressed", self, "launch_game", ["games/"+path])
	$Control/ScrollContainer/VBoxContainer.add_child(b)
	
func add_test_button(path):
	var b = Button.new()
	b.text = path
	b.connect("pressed", self, "launch_test", [path])
	$Control/ScrollContainer2/VBoxContainer.add_child(b)
	
func _ready():
	var listing = Directory.new()
	if listing.open("user://") != OK:
		return null
	listing.list_dir_begin()
	var next_file_name = listing.get_next()
	while next_file_name != "":
		if next_file_name.ends_with(".pck"):
			add_pck_button(next_file_name)
		next_file_name = listing.get_next()
		
	var game_listing = Directory.new()
	if game_listing.open("res://games/") != OK:
		return null
	game_listing.list_dir_begin()
	next_file_name = game_listing.get_next()
	while next_file_name != "":
		if not next_file_name in [".", ".."]:
			add_game_button(next_file_name)
		next_file_name = game_listing.get_next()

	var test_listing = Directory.new()
	if test_listing.open("res://tests/") != OK:
		return null
	test_listing.list_dir_begin()
	next_file_name = test_listing.get_next()
	while next_file_name != "":
		if next_file_name.ends_with(".txt"):
			add_test_button(next_file_name)
		next_file_name = test_listing.get_next()

func launch_game(path):
	print("launching game ", path)
	emit_signal("game_loaded", path)
	queue_free()

func launch_test(path):
	emit_signal("game_loaded", path)
	queue_free()
