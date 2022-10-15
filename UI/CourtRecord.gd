# TODO - make it save your place, implement the ability to check
extends Node2D
var script_name = "evidence_menu"
var wait_signal = "tree_exited"

var main:Node
var root_path
var z

var page = "evidence"
var offset = 0

var sprites = {}
var sprites_high = {}
onready var IButtonS = load("res://UI/IButton.gd")

func reset():
	for child in get_children():
		child.queue_free()
	load_art(root_path)
	
func load_art(root_path):
	self.root_path = root_path
	var bg = PWSprite.new()
	var evbg_path = main.stack.variables.get_string("ev_mode_bg_evidence")
	evbg_path = Filesystem.lookup_file(
		"art/"+evbg_path+".png",
		root_path
	)
	bg.load_animation(evbg_path)
	add_child(bg)
	position = Vector2(0, 192)
	z = ZLayers.z_sort[script_name]
	load_page()
	load_back_button()
	
func add_button(normal, highlight, button_name):
	print(normal, highlight)
	var button = IButton.new(
		Filesystem.load_atlas_frames(
			Filesystem.lookup_file(normal, root_path)
		)[0],
		Filesystem.load_atlas_frames(
			Filesystem.lookup_file(highlight, root_path)
		)[0]
	)
	button.menu = self
	button.button_name = button_name
	add_child(button)
	return button
	
func load_back_button():
	var back_button = add_button(
		"art/general/back.png",
		"art/general/back_high.png",
		"_^BACK^_"
	)
	back_button.position = Vector2(
		back_button.width/2,
		192-back_button.height/2
	)
	
func load_page_button():
	var pages = main.stack.evidence_pages.keys()
	var cur_i = pages.find(page)
	if cur_i < pages.size()-1:
		cur_i += 1
	elif cur_i == pages.size()-1:
		cur_i = 0
	var next_page = pages[cur_i]
	var b = IButton.new(null, null, 
		Vector2(
			main.stack.variables.get_int("ev_modebutton_x"),
			main.stack.variables.get_int("ev_modebutton_y")
		),
		Vector2(60, 30)
	)
	b.menu = self
	b.button_name = "MODE_"+next_page
	var l = Label.new()
	l.text = next_page
	b.add_child(l)
	add_child(b)
	
func load_page():
	load_page_button()
	var x = main.stack.variables.get_int("ev_items_x")
	var y = main.stack.variables.get_int("ev_items_y")
	for evname in main.stack.evidence_pages.get(page, []):
		var key_name = main.stack.variables.get_string(evname+"_name", evname)
		var key_desc = main.stack.variables.get_string(evname+"_desc", "")
		var key_pic = main.stack.variables.get_string(evname+"_pic", evname)
		var pic = PWSprite.new()
		var ev_path = Filesystem.lookup_file(
			"art/ev/"+key_pic+".png",
			self.root_path
		)
		pic.load_animation(ev_path)
		pic.rescale(
			main.stack.variables.get_int("ev_small_width"),
			main.stack.variables.get_int("ev_small_height")
		)
		# IButton are positioned at center TODO we shouldn't do that
		pic.position = Vector2(-pic.width/2, -pic.height/2)
		
		var ev_button = IButton.new(
			pic, null, Vector2(x+pic.width/2, y+pic.height/2)
		)
		ev_button.menu = self
		ev_button.button_name = evname
		add_child(ev_button)
		
		# Move to next spot
		x += main.stack.variables.get_int("ev_spacing_x")
		if x > 256-pic.width:
			x = main.stack.variables.get_int("ev_items_x")
			y += main.stack.variables.get_int("ev_spacing_y")

func click_option(option):
	if option.begins_with("MODE_"):
		page = option.split("_")[1]
		reset()
		return
	if option == "_^BACK^_":
		queue_free()
		return
	Commands.call_goto(
		main.stack.scripts[-1],
		[option, "fail=none"]
	)
	queue_free()
