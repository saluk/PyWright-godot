# TODO - make it save your place, implement the ability to check
extends WrightObject

var PAGE_SIZE = 8
var page = "evidence"
func set_page(new_page):
	page = new_page
	stack.variables.set_val("_cr_current_item_set", new_page)

var offset = 0
func set_offset(new_offset):
	offset = new_offset
	stack.variables.set_val("_cr_current_page", str(int(offset / PAGE_SIZE)))

var zoom = false

var ev_db = {}

var in_presentation_context = false

var name_label:Label
var page_label:Label

var has_objects = false

func _init():
	._init()
	save_properties.append("in_presentation_context")

func _ready():
	._ready()
	Commands.call_macro("sound_court_record_display", wrightscript, [])
	script_name = "evidence_menu"
	wait_signal = "tree_exited"
	page = stack.variables.get_string("_cr_current_item_set", "evidence")
	offset = stack.variables.get_int("_cr_current_page", 0) * PAGE_SIZE
	verify_pages()

func can_present():
	var can_present_page_1 = stack.variables.get_truth("_%s_present" % page, true)
	var can_present_page_2 = stack.variables.get_truth("_allow_present_%s" % page, true)
	if can_present_page_1 and can_present_page_2:
		return in_presentation_context
	return false
	
func get_available_pages():
	var pages = main.stack.variables.get_string("_ev_pages").split(" ")
	var pages_return = []
	for p in pages:
		if main.stack.variables.get_truth("_%s_enabled" % p, true):
			pages_return.append(p)
	return pages_return
	
func evidence_name(evidence_tag):
	return evidence_tag.trim_suffix("$")

func verify_pages():
	var pages = get_available_pages()
	if not page in pages:
		set_page(pages[0])
		reset()
		
func reset():
	has_objects = false
	for child in get_children():
		child.queue_free()
	
func _process(dt):
	if has_objects:
		return
	has_objects = true
	var evbg_path = stack.variables.get_string("ev_mode_bg_"+page)
	if not evbg_path:
		evbg_path = stack.variables.get_string("ev_mode_bg_evidence")
	var bg = ObjectFactory.create_from_template(
		main.top_script(),
		"graphic",
		{},
		[evbg_path],
		script_name
	)
	bg.cannot_save = true
	
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
	Fonts.set_element_font(name_label, "itemname", stack)
	name_label.name = "Name Label"
	name_label.rect_position = Vector2(
		stack.variables.get_int("ev_currentname_x"),
		stack.variables.get_int("ev_currentname_y")
	)
	name_label.text = ""
	
	page_label = Label.new()
	Fonts.set_element_font(page_label, "itemset", stack)
	page_label.name = "Page Label"
	page_label.rect_position = Vector2(
		stack.variables.get_int("ev_mode_x"),
		stack.variables.get_int("ev_mode_y")
	)
	page_label.text = ""

	add_child(page_label)
	add_child(name_label)
	load_page()
	load_back_button()
	
# TODO this should load the same back button as wrightscript
func load_back_button():
	# Disable back button in zoomed out view
	if not zoom:
		if not stack.variables.get_truth("_cr_back_button", true):
			return
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
	back_button.variables.set_val("click_sound_macro", "sound_back_button_cancel")
	back_button.cannot_save = true
	back_button.position = Vector2(
		0,
		192-back_button.height
	)
	
func ws_click_back_from_court_record(script, arguments):
	if zoom:
		zoom = false
		set_offset(int(offset/8) * PAGE_SIZE)
		reset()
		return
	stack.variables.set_val("_selected", "")
	queue_free()
	
func load_page_button():
	var pages = get_available_pages()
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
	b.cannot_save = true
	b.position = Vector2(256-b.width, 0)
	var l = Label.new()
	Fonts.set_element_font(l, "itemset_big", stack)
	l.rect_position += Vector2(
		stack.variables.get_int("ev_modebutton_x", 0),
		stack.variables.get_int("ev_modebutton_y", 0)
	) - b.position
	l.text = next_page.capitalize()
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
					"default": {"path":"art/%s.png" % stack.variables.get_string("ev_arrow_button_img")}
				},
				"mirror": [{"L":-1, "R": 1}[direction], 1],
				"click_macro": "{record_click_direction}",
				"click_args": [direction]
		}, 
		[], 
		script_name
	)
	b.cannot_save = true
	b.position = pos
	
func ws_record_click_direction(script, arguments):
	var direction = {"L":-1, "R":1}[arguments[0]]
	set_offset(offset + direction*{true:1, false:PAGE_SIZE}[zoom])
	reset()
	return
	
func load_page():
	page_label.text = ""
	if stack.variables.get_truth("ev_show_mode_text", true):
		page_label.text = page.capitalize()
	name_label.text = ""
	load_page_button()
	if not zoom:
		load_page_overview()
	else:
		load_page_zoom()

# TODO use variables for positioning and art assets
func load_page_zoom():
	var zoombg_path = Filesystem.lookup_file("art/%s.png" % stack.variables.get_string("ev_z_bg"), root_path)
	var zoombg = PWSprite.new()
	zoombg.load_animation(zoombg_path)
	add_child(zoombg)
	zoombg.position = Vector2(
		stack.variables.get_int("ev_z_bg_x"),
		stack.variables.get_int("ev_z_bg_y")
	)
	var x = stack.variables.get_int("ev_z_icon_x")
	var y = stack.variables.get_int("ev_z_icon_y")
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
		
		name_label.text = evidence_name(key_name)
		
		# TODO make this a textblock after textblock is implemented
		var desc:Label = Label.new()
		Fonts.set_element_font(desc, "block", stack)
		desc.rect_position = Vector2(
			stack.variables.get_int("ev_z_textbox_x", 0),  # zero so we can ensure it loads the variable
			stack.variables.get_int("ev_z_textbox_y", 0)
		)
		desc.rect_size = Vector2(
			stack.variables.get_int("ev_z_textbox_w", 0),  # zero so we can ensure it loads the variable
			stack.variables.get_int("ev_z_textbox_h", 0)
		)
		desc.set("custom_constants/line_spacing", 
			stack.variables.get_int("textblock_line_height", 10)
		)
		desc.set("custom_colors/font_color", Colors.string_to_color(stack.variables.get_string("ev_z_text_col")))
		desc.text = key_desc.replace("{n}","\n")
		desc.clip_text = true
		desc.autowrap = true
		add_child(desc)
		
		if can_present() and stack.variables.get_truth(evname+"_presentable", true):
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
			present_button.cannot_save = true
			present_button.position = Vector2(100,0)
		
		load_check_button(evname)
	if left_arrow:
		load_arrow("L")
	if right_arrow:
		load_arrow("R")
	
func load_check_button(evname):
	var check_script = stack.variables.get_string(evname+"_check")
	if not check_script:
		return
	var check_img = stack.variables.get_string("ev_check_img")
	var check_button = ObjectFactory.create_from_template(
		main.top_script(),
		"button",
		{
			"sprites": {
				"default": {"path": "art/"+check_img+".png"},
				"highlight": {"path": "art/"+check_img+"_high.png"}
			},
			"click_macro": "{record_click_check}",
			"click_args": [evname, check_script]
		},
		[],
		script_name
	)
	check_button.cannot_save = true
	check_button.position = Vector2(256-check_button.width, 192-check_button.height)
	pass

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
		if count >= PAGE_SIZE:
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
		var lookup_path = "art/ev/"+key_pic+".png"
		var ev_path = Filesystem.lookup_file(
			"art/ev/"+key_pic+".png",
			self.root_path
		)
		if not ev_path:
			lookup_path = "art/ev/envelope.png"
		var ev_button = ObjectFactory.create_from_template(
			main.top_script(), 
			"button", 
			{
				"sprites": {
					"default": {"path":lookup_path}
				},
				"click_macro": "{record_zoom_evidence}",
				"click_args": [evname]
			}, 
			[], 
			script_name
		)
		ev_button.cannot_save = true
		ev_button.position = Vector2(x-2, y-2)
		if ev_button.current_sprite:
			ev_button.current_sprite.rescale(
				stack.variables.get_int("ev_small_width"),
				stack.variables.get_int("ev_small_height")
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
		name_label.text = evidence_name(ev_db[evname]["name"])
		
func ws_record_zoom_evidence(script, arguments):
	var evname = arguments[0]
	zoom = true
	set_offset(stack.evidence_pages.get(page, []).find(evname))
	reset()
	
func ws_record_click_present(script, arguments):
	present(arguments[0])
	
func ws_record_click_check(script, arguments):
	check(arguments[0], arguments[1])
	
func ws_click_page_from_court_record(script, arguments):
	set_page(arguments[0])
	set_offset(0)
	reset()
	
func present(option):
	Commands.call_command(
		"callpresent",
		stack.scripts[-1],
		[option]
	)
	queue_free()
	
func check(evname, check_script):
	select(evname)
	Commands.call_command(
		"script",
		stack.scripts[-1],
		[check_script, "stack", "noclear"]
	)
	#visible = false
	#queue_free()

# TODO implement check


#SAVE/LOAD
func load_node(tree:SceneTree, saved_data:Dictionary):
	reset()
	.load_node(tree, saved_data)
