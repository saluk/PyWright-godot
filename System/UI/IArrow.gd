extends Node2D
var script_name = "uglyarrow"

var z:int

var sprites = {}
var sprites_high = {}
onready var IButtonS = load("res://System/UI/IButton.gd")

var bg
var button
	
func load_art(root_path):
	position = Vector2(0, 192)
	var path = Filesystem.lookup_file("art/bg/main2.png", root_path)
	var bg = PWSprite.new()
	bg.load_animation(path)
	add_child(bg)

	path = Filesystem.lookup_file("art/general/buttonpress.png", root_path)
	var arrowbg = PWSprite.new()
	arrowbg.load_animation(path)
	
	path = Filesystem.lookup_file("art/general/buttonpress_high.png", root_path)
	var arrowbg_high = PWSprite.new()
	arrowbg_high.load_animation(path)
	
	var button = IButton.new(
		arrowbg, arrowbg_high,
		Vector2(256/2-arrowbg.width/2, 192/2-arrowbg.height/2)
	)
	button.area.rect_position = Vector2(0, 0)
	add_child(button)
	button.menu = self
	
	path = Filesystem.lookup_file("art/general/arrow_big.png", root_path)
	var arrowfg = PWSprite.new()
	arrowfg.load_animation(path)
	arrowfg.position = Vector2(arrowbg.width/2-arrowfg.width/2, arrowbg.height/2-arrowfg.height/2)
	button.add_child(arrowfg)
	
	self.bg = bg
	self.button = button

func click_option(option):
	for obj in Commands.get_objects(null, null, Commands.TEXTBOX_GROUP):
		obj.click_continue()
		return

func _process(dt):
	if not Commands.get_objects(null, null, Commands.TEXTBOX_GROUP):
		self.button.visible = false
	else:
		self.button.visible = true
