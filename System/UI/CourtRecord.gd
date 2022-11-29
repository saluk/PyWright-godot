# TODO - make it save your place, implement the ability to check
extends Node2D
var script_name = "evidence_menu"
var wait_signal = "tree_exited"

var main:Node
var root_path
var z

var page = "evidence"
var offset = 0
var zoom = false

var ev_db = {}
onready var IButtonS = load("res://System/UI/IButton.gd")

var in_presentation_context = false

var name_label:Label
var page_label:Label

func can_present():
	# TODO tie this to variables
	return in_presentation_context

func reset():
	for child in get_children():
		child.queue_free()
	load_art(root_path)
	
func load_art(root_path):
	name_label = Label.new()
	name_label.name = "Name Label"
	name_label.rect_position = Vector2(28,41)
	name_label.text = ""
	
	page_label = Label.new()
	page_label.name = "Page Label"
	page_label.rect_position = Vector2(1,14)
	page_label.text = ""
	
	self.root_path = root_path
	var bg = PWSprite.new()
	var evbg_path = main.stack.variables.get_string("ev_mode_bg_evidence")
	evbg_path = Filesystem.lookup_file(
		"art/"+evbg_path+".png",
		root_path
	)
	bg.load_animation(evbg_path)
	add_child(bg)
	
	# TODO - it's weird to have to make guis to block things off, should be
	# built into PWSprite
	var blocker = Control.new()
	blocker.rect_size = Vector2(bg.width, bg.height)
	add_child(blocker)
	
	position = Vector2(0, 192)
	z = ZLayers.z_sort[script_name]
	load_page()
	load_back_button()
	add_child(page_label)
	add_child(name_label)
	
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
	if pages.size() == 1:
		return
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
		Vector2(60, 30),
		false
	)
	b.menu = self
	b.button_name = "MODE_"+next_page
	b.name = b.button_name
	var l = Label.new()
	l.text = next_page
	b.add_child(l)
	add_child(b)
	
func load_arrow(direction):
	var pos = Vector2(5, 92)
	if direction == "R":
		pos.x = 241
	var b = IButton.new(null, null, pos, Vector2(30, 30), false)
	b.menu = self
	b.button_name = "ARROW_"+direction
	b.name = b.button_name
	var l = Label.new()
	l.text = direction
	b.add_child(l)
	add_child(b)
	
func load_page():
	page_label.text = page
	name_label.text = ""
	load_page_button()
	if not zoom:
		load_page_overview()
	else:
		load_page_zoom()

# TODO use variables for positioning and art assets
func load_page_zoom():
	var zoombg_path = Filesystem.lookup_file("art/general/evidence_zoom.png", root_path)
	var zoombg = PWSprite.new()
	zoombg.load_animation(zoombg_path)
	add_child(zoombg)
	var x = 27
	var y = 59
	var i = -1
	var count = 0
	var left_arrow = false
	var right_arrow = false
	for evname in main.stack.evidence_pages.get(page, []):
		i += 1
		if i < offset:
			# We're trying to draw before the offset, show left arrow
			left_arrow = true
			continue
		if count >= 1:
			# We're trying to draw past limit, show right arrow
			right_arrow = true
			break
		count += 1
		var key_name = main.stack.variables.get_string(evname+"_name", evname)
		var key_desc = main.stack.variables.get_string(evname+"_desc", "")
		var key_pic = main.stack.variables.get_string(evname+"_pic", evname)
		var key_check = main.stack.variables.get_string(evname+"_check", null)
		ev_db[evname] = {
			"name": key_name, "desc": key_desc, "pic": key_pic, "check": key_check
		}
		var pic = PWSprite.new()
		var ev_path = Filesystem.lookup_file(
			"art/ev/"+key_pic+".png",
			self.root_path
		)
		if not ev_path:
			ev_path = Filesystem.lookup_file(
				"art/ev/envelope.png",
				self.root_path
			)
		pic.name = "ZoomedEv"+key_pic
		pic.load_animation(ev_path)
		pic.rescale(
			main.stack.variables.get_int("ev_big_width")+1,
			main.stack.variables.get_int("ev_big_height")+1
		)
		pic.position = Vector2(x, y)
		add_child(pic)
		
		name_label.text = key_name
		
		var desc = Label.new()
		desc.rect_position = Vector2(106, 66)
		desc.text = key_desc
		desc.rect_size = Vector2(130, 128)
		desc.autowrap = true
		add_child(desc)
		
		if can_present():
			var present_button = IButton.new(
				PWSprite.new().load_animation(Filesystem.lookup_file("art/general/press/present2.png", root_path)),
				PWSprite.new().load_animation(Filesystem.lookup_file("art/general/press/present2_high.png", root_path)),
				Vector2(100,0), null, false
			)
			present_button.menu = self
			present_button.name = "Present button"
			present_button.button_name = "^PRESENT^_"+evname
			add_child(present_button)
	if left_arrow:
		load_arrow("L")
	if right_arrow:
		load_arrow("R")

		
func load_page_overview():
	var x = main.stack.variables.get_int("ev_items_x")
	var y = main.stack.variables.get_int("ev_items_y")
	var i = -1
	var count = 0
	var left_arrow = false
	var right_arrow = false
	for evname in main.stack.evidence_pages.get(page, []):
		i += 1
		if i < offset:
			# We're trying to draw before the offset, show left arrow
			left_arrow = true
			continue
		if count >= 8:
			# We're trying to draw past limit, show right arrow
			right_arrow = true
			break
		count += 1
		var key_name = main.stack.variables.get_string(evname+"_name", evname)
		var key_desc = main.stack.variables.get_string(evname+"_desc", "")
		var key_pic = main.stack.variables.get_string(evname+"_pic", evname)
		var key_check = main.stack.variables.get_string(evname+"_check", null)
		ev_db[evname] = {
			"name": key_name, "desc": key_desc, "pic": key_pic, "check": key_check
		}
		var pic = PWSprite.new()
		var ev_path = Filesystem.lookup_file(
			"art/ev/"+key_pic+".png",
			self.root_path
		)
		if not ev_path:
			ev_path = Filesystem.lookup_file(
				"art/ev/envelope.png",
				self.root_path
			)
		pic.load_animation(ev_path)
		pic.rescale(
			main.stack.variables.get_int("ev_small_width")+1,
			main.stack.variables.get_int("ev_small_height")+1
		)
		# IButton are positioned at center TODO we shouldn't do that
		pic.position = Vector2(-pic.width/2, -pic.height/2)
		
		var ev_button = IButton.new(
			pic, null, Vector2(x+pic.width/2, y+pic.height/2)
		)
		ev_button.menu = self
		ev_button.button_name = evname
		add_child(ev_button)
		ev_button.area.connect("mouse_entered", self, "highlight_evidence", [evname])
		
		# Move to next spot
		x += main.stack.variables.get_int("ev_spacing_x")
		if x > 256-pic.width:
			x = main.stack.variables.get_int("ev_items_x")
			y += main.stack.variables.get_int("ev_spacing_y")
	if left_arrow:
		load_arrow("L")
	if right_arrow:
		load_arrow("R")
		
func highlight_evidence(evname):
	if not zoom:
		name_label.text = ev_db[evname]["name"]

func click_option(option):
	if option.begins_with("MODE_"):
		page = option.split("_")[1]
		offset = 0
		reset()
		return
	if option.begins_with("ARROW_"):
		var direction = option.split("_")[1]
		direction = {"L":-1, "R":1}[direction]
		offset += direction*{true:1, false:8}[zoom]
		reset()
		return
	if option.begins_with("^PRESENT^_"):
		present(option.split("_")[1])
		return
	if option == "_^BACK^_":
		if zoom:
			zoom = false
			offset = int(offset/8)
			reset()
			return
		else:
			queue_free()
			return
	main.stack.variables.set_val("_selected", option)
	zoom = true
	offset = main.stack.evidence_pages.get(page, []).find(option)
	reset()
	
func present(option):
	Commands.call_command(
		"callpresent",
		main.stack.scripts[-1],
		[option]
	)
	queue_free()

# TODO implement check
