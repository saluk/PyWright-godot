extends Node

signal game_loaded

func add_pck_button(path):
	var txt = path.replace("_"," ").replace(".pck","")
	var b = Button.new()
	b.text = txt
	b.connect("pressed", self, "launch_game", [path])
	$Control/ScrollContainer/VBoxContainer.add_child(b)
	
func add_game_button(path):
	var hbox = HBoxContainer.new()
	var txt = path.replace("_"," ")
	var b = Button.new()
	b.text = "P"
	b.align = Button.ALIGN_LEFT
	b.connect("pressed", self, "launch_game", ["games/"+path])
	hbox.add_child(b)
	var l = Label.new()
	l.text = path
	hbox.add_child(l)
	$Control/ScrollContainer/VBoxContainer.add_child(hbox)
	
func add_test_button(path):
	var hbox = HBoxContainer.new()
	var b = Button.new()
	b.text = "P"
	b.align = Button.ALIGN_LEFT
	b.connect("pressed", self, "launch_game", [path, "play"])
	hbox.add_child(b)
	b = Button.new()
	b.text = "T"
	b.align = Button.ALIGN_LEFT
	b.connect("pressed", self, "launch_game", [path, "test"])
	hbox.add_child(b)
	var l = Label.new()
	l.text = path
	hbox.add_child(l)
	$Control/ScrollContainer2/VBoxContainer.add_child(hbox)
	
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
	if game_listing.open("res://games/") == OK:
		game_listing.list_dir_begin()
		next_file_name = game_listing.get_next()
		while next_file_name != "":
			if not next_file_name in [".", ".."]:
				add_game_button(next_file_name)
			next_file_name = game_listing.get_next()

	var test_listing = Directory.new()
	if test_listing.open("res://tests/") == OK:
		test_listing.list_dir_begin()
		next_file_name = test_listing.get_next()
		while next_file_name != "":
			if next_file_name.ends_with(".txt"):
				add_test_button(next_file_name)
			next_file_name = test_listing.get_next()

func launch_game(path, mode="play"):
	emit_signal("game_loaded", path, mode)
	queue_free()
