extends WrightObject

var scene_name:String

var bg_obs = []
var bg_obs_original = []

var back_button:Node
var examine_button:Node

var scroll_button:Node
var scroll_button_direction:int
var x_offset = 0
var scrolling = false

var crosshair

var cross_area:Area2D

var allow_back_button := true
var reveal_regions := true
var reloaded_scroll := false
var fail := "none"

var current_region:Area2D

# TODO figure out how we decide whther to show the back button or not
# TODO build in scrolling the top bg down (but default to off)

func _ready():
	wait_signal = "tree_exited"
	bg_obs_original = Commands.get_objects(null, null, Commands.BG_GROUP)
	var has_bottom_screen_bg = false
	for bg_ob in bg_obs_original:
		if bg_ob.position.y >= 192:
			has_bottom_screen_bg = true
	# TODO don't do this if someone has scrolled a screen down?
	# On the other hand, while it's excessive copying it shouldn't hurt anything
	for bg_ob in bg_obs_original:
		bg_ob = bg_ob.duplicate()
		bg_obs.append(bg_ob)
		add_child(bg_ob)
	setup_crosshair()
	
func setup_crosshair():
	crosshair = Crosshair.new()
	crosshair.parent = self
	add_child(crosshair)
	cross_area = Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.extents = Vector2(256, 192)/2
	cross_area.add_child(shape)
	cross_area.position = Vector2(256/2, 192/2)
	add_child(cross_area)
		
func set_crosshair_pos(x, y):
	#print("CROSS X Y ",x," ",y)
	crosshair.crosshair_position = Vector2(int(x), int(y))
	update()
			
class Region extends Area2D:
	var label
	var size
	func _init(x, y, width, height):
		size = Vector2(width, height)
		position = Vector2(x,y)
	func is_point_inside(point):
		#print(point, ',', position, ',', size)
		if (point.x >= position.x and point.x <= position.x+size.x and 
			point.y >= position.y and point.y <= position.y+size.y):
			return true
		return false
		
func _get_scroll_direction():
	# Enable scroll left if the RIGHT edge of any region or background is to the left
	# Enable scroll right if the LEFT edge of any region or background is to the right
	# Will have bad behavior if both of these conditions are true
	var scroll_left = false
	var scroll_right = false
	for region in get_children():
		if region is Region:
			if region.position.x + region.size.x < 0:
				scroll_left = true
				break
			if region.position.x > 256:
				scroll_right = true
				break
	if not (scroll_left or scroll_right):
		for bg in bg_obs_original:
			if bg.position.x + bg.width < 0:
				scroll_left = true
				break
			if bg.position.x > 256:
				scroll_right = true
				break
	if scroll_left:
		return -1
	elif scroll_right:
		return 1
	else:
		return 0
	
func add_region_args(arguments):
	var x = int(arguments[0])
	var y = int(arguments[1])
	var width = int(arguments[2])
	var height = int(arguments[3])
	var region = Region.new(x, y, width, height)
	region.label = arguments[4]
	add_child(region)
	
func ws_check_from_examine(script, arguments):
	queue_free()
	var label = fail
	if current_region:
		label = current_region.label
	stack.variables.set_val("_examine_clickx", str(crosshair.real_position().x))
	stack.variables.set_val("_examine_clicky", str(crosshair.real_position().y))
	return Commands.call_command(
		"goto",
		stack.scripts[-1],
		[
			label
		]
	)

func ws_back_from_examine(script, arguments):
	queue_free()
	
func ws_scroll_from_examine(script, arguments):
	scrolling = true
	if arguments:
		scroll_button_direction = arguments[0]
	if scroll_button:
		scroll_button.queue_free()
		scroll_button = null
	var scroll_amt = 256/32
	for i in range(32):
		for ob in get_children():
			if ob is Region:
				ob.position.x -= scroll_button_direction * scroll_amt
		for ob in get_parent().get_children():
			if "scrollable" in ob and ob.scrollable:
				ob.position.x -= scroll_button_direction * scroll_amt
		if not arguments:
			yield(get_tree(), "idle_frame")
	x_offset += scroll_button_direction
	scrolling = false
	if not arguments:
		main.stack.variables.set_val(
			"_xscroll_"+script_name,
			str(x_offset)
		)
		update()
	
func reload_scroll_regions():
	if reloaded_scroll:
		return
	reloaded_scroll = true
	var saved_scroll = main.stack.variables.get_int(
		"_xscroll_"+script_name,
		0
	)
	while saved_scroll:
		ws_scroll_from_examine(null, [saved_scroll/abs(saved_scroll)])
		saved_scroll -= saved_scroll/abs(saved_scroll)
	
func _unhandled_input(event):
	if scrolling: return
	if Input.get_mouse_button_mask() & BUTTON_LEFT:
		var pos = get_viewport().get_mouse_position()-position
		set_crosshair_pos(pos.x, pos.y)
		update()
		
func _select():
	for child in get_children():
		var region = child as Region
		var cp = crosshair.real_position()
		if region and region.is_point_inside(cp):
			if reveal_regions:
				examine_button.visible = true
			current_region = region
			#print("SET CURRENT REGION")
			return
		
func update():
	if scrolling: return
	script_name = "examine_menu"
	if bg_obs_original:
		script_name += "+"+bg_obs_original[0].script_name
	reload_scroll_regions()
	name = script_name
	if allow_back_button and not back_button:
		back_button = ObjectFactory.create_from_template(
			get_tree().root.get_node("Main").top_script(),
			"button",
			{
				"sprites": {
					"default": {"path": "art/general/back.png"},
					"highlight": {"path": "art/general/back_high.png"}
				},
				"click_macro": "{back_from_examine}"
			},
			[],
			script_name
		)
		back_button.position = Vector2(
			0,
			192-back_button.height
		)
	if not examine_button:
		examine_button = ObjectFactory.create_from_template(
			get_tree().root.get_node("Main").top_script(),
			"button",
			{
				"sprites": {
					"default": {"path": "art/general/check.png"}
				},
				"click_macro": "{check_from_examine}"
			},
			[],
			script_name
		)
		examine_button.position = Vector2(
			256-examine_button.width,
			192-examine_button.height
		)
	var scroll_direction = _get_scroll_direction()
	if scroll_direction!=0 and scroll_button_direction != scroll_direction:
		scroll_button_direction = scroll_direction
		if scroll_button:
			scroll_button.queue_free()
		scroll_button = ObjectFactory.create_from_template(
			get_tree().root.get_node("Main").top_script(),
			"button",
			{
				"sprites": {
					"default": {"path": "art/general/examine_scroll.png"}
				},
				"mirror": [-scroll_direction, 1],
				"click_macro": "{scroll_from_examine}"
			},
			[],
			script_name
		)
		scroll_button.position = Vector2(
			256/2-scroll_button.width/2,
			192-scroll_button.height
		)

	examine_button.visible = false
	current_region = null
	#print("CLEAR CURRENT REGION")
	if not reveal_regions:
		examine_button.visible = true
	_select()
	.update()
	crosshair.update()

class Crosshair extends Node2D:
	var crosshair_position := Vector2(int(256/2), int(192/2))
	var parent:Node2D
	func real_position():
		return crosshair_position - parent.global_position + Vector2(0,192)
	func _draw():
		var cp = real_position()
		draw_line(
			Vector2(0, cp.y),
			Vector2(256, cp.y),
			Color.whitesmoke
		)
		draw_line(
			Vector2(cp.x, 0),
			Vector2(cp.x, 192),
			Color.whitesmoke
		)
		draw_line(
			Vector2(cp.x-5, cp.y-5),
			Vector2(cp.x+5, cp.y+5),
			Color.greenyellow
		)
		draw_line(
			Vector2(cp.x+5, cp.y-5),
			Vector2(cp.x-5, cp.y+5),
			Color.greenyellow
		)
