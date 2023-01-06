# TODO - eventually we want this to be managed by a wrightscript macro
#  we need a few things to make that workable:
# 		- need a way to define multiple regions
#		- how to draw the crosshair and move it on mouse click/drag
#		- how to determine when crosshair is over something
#		(a lot of these hows can still be implenented in gdscript,
#		 but the objects should derive from WrightObject and be templatable
#		 and save/loadable)
#  For now we have this as a stopgap 

extends Node2D
var script_name = "examine_menu"
var wait_signal = "tree_exited"
var z:int

var scene_name:String
var root_path

var bg_obs = []

var back_button
var examine_button
var crosshair

var click_area:Area2D

var allow_back_button = true
var reveal_regions = true
var fail = "none"

var current_region

# TODO figure out how we decide whther to show the back button or not
	
func load_art(root_path):
	for bg_ob in Commands.get_objects(null, null, Commands.BG_GROUP):
		bg_ob = bg_ob.duplicate()
		bg_obs.append(bg_ob)
		add_child(bg_ob)
	self.root_path = root_path
	setup_crosshair()

	examine_button = Commands.add_button_to_interface(
		self,
		"art/general/check.png",
		"",
		"check_from_examine"
	)
	examine_button.position = Vector2(
		256-examine_button.width,
		192-examine_button.height
	)
	examine_button.visible = false
	position = Vector2(0, 192)
	
func setup_crosshair():
	crosshair = Crosshair.new()
	add_child(crosshair)
	click_area = Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.extents = Vector2(256, 192)/2
	click_area.add_child(shape)
	click_area.position = Vector2(256/2, 192/2)
	add_child(click_area)
	click_area.connect("input_event", self, "_on_click_area_input_event")
	
func _on_click_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if Input.get_mouse_button_mask() & BUTTON_LEFT:
			var pos = event.position-position
			crosshair.crosshair_position = Vector2(int(pos.x), int(pos.y))
			update()
		#if event is InputEventMouseButton and event.pressed == false:
		#	click_option("region")
			
class Region extends Area2D:
	var label
	var size
	func _init(x, y, width, height):
		size = Vector2(width, height)
		position = Vector2(x,y)
	func is_point_inside(point):
		print(point, ',', position, ',', size)
		if (point.x >= position.x and point.x <= position.x+size.x and 
			point.y >= position.y and point.y <= position.y+size.y):
			return true
		return false
	
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
	return Commands.call_command(
		"goto",
		Commands.main.stack.scripts[-1],
		[
			label
		]
	)

func ws_back_from_examine(script, arguments):
	queue_free()
		
func update():
	if allow_back_button and not back_button:
		back_button = Commands.add_button_to_interface(
			self,
			"art/general/back.png",
			"art/general/back_high.png",
			"back_from_examine"
		)
		back_button.position = Vector2(
			0,
			192-back_button.height
		)

	examine_button.visible = false
	current_region = null
	print("CLEAR CURRENT REGION")
	if not reveal_regions:
		examine_button.visible = true
	for child in get_children():
		var region = child as Region
		if region and region.is_point_inside(crosshair.crosshair_position):
			if reveal_regions:
				examine_button.visible = true
			current_region = region
			print("SET CURRENT REGION")
	.update()
	crosshair.update()

class Crosshair extends Node2D:
	var crosshair_position = Vector2(int(256/2), int(192/2))
	func _draw():
		draw_line(
			Vector2(0, crosshair_position.y),
			Vector2(256, crosshair_position.y),
			Color.whitesmoke
		)
		draw_line(
			Vector2(crosshair_position.x, 0),
			Vector2(crosshair_position.x, 192),
			Color.whitesmoke
		)
