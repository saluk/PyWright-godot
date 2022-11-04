extends Node2D
var script_name = "uglyarrow"

var z:int

var sprites = {}
var sprites_high = {}
onready var IButtonS = load("res://UI/IButton.gd")

var bg
var left
var right
	
func load_art(root_path):
	position = Vector2(0, 192)
	var path = Filesystem.lookup_file("art/bg/main2.png", root_path)
	var bg = PWSprite.new()
	bg.load_animation(path)
	add_child(bg)

	path = Filesystem.lookup_file("art/general/cross_exam_buttons.png", root_path)

	var width = 100
	var height = 111

	var buttons = Filesystem.load_atlas_specific(path, [
		Rect2(Vector2(0,0), Vector2(width, height)),
		Rect2(Vector2(123, 0), Vector2(width, height))
	])
	
	left = IButton.new(
		buttons[0], null,
		Vector2(256/2-width/2-(256/2-(width))/2, 192/2)
	)
	add_child(left)
	left.button_name = "left"
	left.menu = self
	
	right = IButton.new(
		buttons[1], null,
		Vector2(256/2+width/2+(256/2-(width))/2, 192/2)
	)
	add_child(right)
	right.button_name = "right"
	right.menu = self
	
	path = Filesystem.lookup_file("art/general/arrow_big.png", root_path)
	var arrowright = PWSprite.new()
	arrowright.load_animation(path)
	arrowright.position = Vector2(-arrowright.width/2, -arrowright.height/2)
	
	var arrowleft = arrowright.duplicate()
	#arrowleft.animated_sprite.scale = Vector2(-1,1)
	
	left.add_child(arrowleft)
	left.scale = Vector2(-1,1)
	right.add_child(arrowright)
	
	self.bg = bg

func click_option(option):
	for obj in Commands.get_objects(null, null, Commands.TEXTBOX_GROUP):
		if option == "left":
			obj.click_prev()
		elif option == "right":
			obj.click_next()
		return

func _process(dt):
	if not Commands.get_objects(null, null, Commands.TEXTBOX_GROUP):
		visible = false
	else:
		visible = true
