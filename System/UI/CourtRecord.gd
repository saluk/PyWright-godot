# TODO - make it save your place, implement the ability to check
extends WrightObject

var page = "evidence"
var offset = 0
var zoom = false

var ev_db = {}

var in_presentation_context = false

var name_label:Label
var page_label:Label

var has_objects = false

func _ready():
	script_name = "evidence_menu"
	wait_signal = "tree_exited"

func can_present():
	# TODO tie this to variables
	return in_presentation_context

func reset():
	has_objects = false
	for child in get_children():
		child.queue_free()
	
func _process(dt):
	if has_objects:
		return
	has_objects = true
	var evbg_path = stack.variables.get_string("ev_mode_bg_evidence")
	var bg = ObjectFactory.create_from_template(
		main.top_script(),
		"graphic",
		{},
		[evbg_path],
		script_name
	)
	
	# Ensure interface doesn't allow clicks below it
	# TODO - it's weird to have to make guis to block things off, should be
	# built into ObjectFactory template maybe?
	var blocker = Control.new()
	blocker.name = "BLOCKER"
	blocker.rect_size = Vector2(bg.width, bg.height)
	bg.add_child(blocker)
	
	position = Vector2(0, 192)
	z = ZLayers.z_sort[script_name]
	
	name_label = Label.new()
	name_label.name = "Name Label"
	name_label.rect_position = Vector2(28,41)
	name_label.text = ""
	
	page_label = Label.new()
	page_label.name = "Page Label"
	page_label.rect_position = Vector2(1,14)
	page_label.text = ""

	add_child(page_label)
	add_child(name_label)
	load_page()
	load_back_button()
	
func load_back_button():
	# TODO only load this if we are allowed
	var back_button = ObjectFactory.create_from_template(
		main.top_script(), 
		"button",
		{
			"sprites": {
				"default": {"path":"art/general/back.png"},
				"highlight": {"path":"art/general/back_high.png"}
			},
			"click_macro": "{click_back_from_court_record}",
		},
		[],
		script_name
	)
	back_button.position = Vector2(
		0,
		192-back_button.height
	)
	
func ws_click_back_from_court_record(script, arguments):
	if zoom:
		zoom = false
		offset = int(offset/8)
		reset()
		return
	queue_free()
	
func load_page_button():
	var pages = stack.evidence_pages.keys()
	if pages.size() == 1:
		return
	var cur_i = pages.find(page)
	if cur_i < pages.size()-1:
		cur_i += 1
	elif cur_i == pages.size()-1:
		cur_i = 0
	if not pages:
		return
	var next_page = pages[cur_i]
	var b = ObjectFactory.create_from_template(
		main.top_script(), 
		"button", 
		{
			"sprites": {
				"default": {"path":"art/general/evidence_mode_button.png"},
				"highlight": {"path":"art/general/evidence_mode_button_high.png"}
			},
			"click_macro": "{click_page_from_court_record}",
			"click_args": [next_page]
		}, 
		[], 
		script_name
	)
	b.position = Vector2(256-b.width, 0)
	var l = Label.new()
	l.rect_position += Vector2(18,8)
	l.text = next_page
	b.add_child(l)
	
func load_arrow(direction):
	var pos = Vector2(3, 58)
	if direction == "R":
		pos.x = 241
	var b = ObjectFactory.create_from_template(
		main.top_script(), 
		"button", 
		{
				"sprites": {
					"default": {"path":"art/general/evidence_arrow_right.png"}
				},
				"mirror": [{"L":-1, "R": 1}[direction], 1],
				"click_macro": "{record_click_direction}",
				"click_args": [direction]
		}, 
		[], 
		script_name
	)
	b.position = pos
	
func ws_record_click_direction(script, arguments):
	var direction = {"L":-1, "R":1}[arguments[0]]
	offset += direction*{true:1, false:8}[zoom]
	reset()
	return
	
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
	for evname in stack.evidence_pages.get(page, []):
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
		var key_name = stack.variables.get_string(evname+"_name", evname)
		var key_desc = stack.variables.get_string(evname+"_desc", "")
		var key_pic = stack.variables.get_string(evname+"_pic", evname)
		var key_check = stack.variables.get_string(evname+"_check", null)
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
			stack.variables.get_int("ev_big_width")+1,
			stack.variables.get_int("ev_big_height")+1
		)
		pic.position = Vector2(x, y)
		add_child(pic)
		
		name_label.text = key_name
		
		var desc = Label.new()
		Fonts.set_element_font(desc, "block", stack.variables)
		desc.rect_position = Vector2(
			stack.variables.get_int("ev_z_textbox_x", 0),  # zero so we can ensure it loads the variable
			stack.variables.get_int("ev_z_textbox_y", 0)
		)
		desc.text = key_desc.replace("{n}","\n")
		desc.clip_text = true
		desc.autowrap = true
		desc.rect_size = Vector2(120, 150)
		add_child(desc)
		
		if can_present():
			select(evname)
			var present_button = ObjectFactory.create_from_template(
				main.top_script(), 
				"button", 
				{
					"sprites": {
						"default": {"path":"art/general/press/present2.png"},
						"highlight": {"path":"art/general/press/present2_high.png"}
					},
					"click_macro": "{record_click_present}",
					"click_args": [evname]
				}, 
				[], 
				script_name
			)
			present_button.position = Vector2(100,0)
	if left_arrow:
		load_arrow("L")
	if right_arrow:
		load_arrow("R")

func select(evname):
	stack.variables.set_val("_selected", evname)
		
func load_page_overview():
	var x = stack.variables.get_int("ev_items_x")
	var y = stack.variables.get_int("ev_items_y")
	var i = -1
	var count = 0
	var left_arrow = false
	var right_arrow = false
	for evname in stack.evidence_pages.get(page, []):
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
		var key_name = stack.variables.get_string(evname+"_name", evname)
		var key_desc = stack.variables.get_string(evname+"_desc", "")
		var key_pic = stack.variables.get_string(evname+"_pic", evname)
		var key_check = stack.variables.get_string(evname+"_check", null)
		ev_db[evname] = {
			"name": key_name, "desc": key_desc, "pic": key_pic, "check": key_check
		}
		var ev_path = Filesystem.lookup_file(
			"art/ev/"+key_pic+".png",
			self.root_path
		)
		if not ev_path:
			ev_path = Filesystem.lookup_file(
				"art/ev/envelope.png",
				self.root_path
			)
		var ev_button = ObjectFactory.create_from_template(
			main.top_script(), 
			"button", 
			{
				"sprites": {
					"default": {"path":ev_path.replace("res://", "")}
				},
				"click_macro": "{record_zoom_evidence}",
				"click_args": [evname]
			}, 
			[], 
			script_name
		)
		ev_button.position = Vector2(x, y)
		if ev_button.current_sprite:
			ev_button.current_sprite.rescale(
				stack.variables.get_int("ev_small_width")+1,
				stack.variables.get_int("ev_small_height")+1
			)
		ev_button.click_area.connect("mouse_entered", self, "highlight_evidence", [evname])
		
		# Move to next spot
		x += stack.variables.get_int("ev_spacing_x")
		if x > 256-ev_button.width:
			x = stack.variables.get_int("ev_items_x")
			y += stack.variables.get_int("ev_spacing_y")
	if left_arrow:
		load_arrow("L")
	if right_arrow:
		load_arrow("R")
		
func highlight_evidence(evname):
	if not zoom:
		name_label.text = ev_db[evname]["name"]
		
func ws_record_zoom_evidence(script, arguments):
	var evname = arguments[0]
	zoom = true
	offset = stack.evidence_pages.get(page, []).find(evname)
	reset()
	
func ws_record_click_present(script, arguments):
	present(arguments[0])
	
func ws_click_page_from_court_record(script, arguments):
	page = arguments[0]
	offset = 0
	reset()
	
func present(option):
	Commands.call_command(
		"callpresent",
		stack.scripts[-1],
		[option]
	)
	queue_free()

# TODO implement check
