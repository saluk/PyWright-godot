extends Node2D
var script_name = "invest_menu"
var wait_signal = "tree_exited"

var scene_name:String
var z:int

var order = ["examine", "move", "talk", "present"]
var relative_positions = {
	"examine": Vector2(0, 0),
	"move": Vector2(1, 0),
	"talk": Vector2(0, 1),
	"present": Vector2(1, 1)
}

var sprites = {}
var sprites_high = {}
onready var IButtonS = load("res://System/UI/IButton.gd")
	
func load_art(root_path):
	var path = Filesystem.lookup_file("art/general/talkbuttons.png", root_path)
	var frames = Filesystem.load_atlas_frames(
		path, 2, 2, 4
	)
	for i in range(order.size()):
		sprites[order[i]] = frames[i]
	path = Filesystem.lookup_file("art/general/talkbuttons_high.png", root_path)
	var frames2 = Filesystem.load_atlas_frames(
		path, 2, 2, 4
	)
	for i in range(order.size()):
		sprites_high[order[i]] = frames2[i]

func add_option(option):
	if not IButtonS:
		return
	var width = sprites[option].region.size.x
	var height = sprites[option].region.size.y
	var button = IButtonS.new(
		sprites[option], 
		sprites_high.get(option, null), 
		Vector2(
			(256-width)/2 + relative_positions[option].x*width,
			(192-height)/2 + relative_positions[option].y*height+192
		))
	button.menu = self
	button.button_name = option
	add_child(button)

func click_option(option):
	Commands.call_command(
		"script",
		Commands.main.stack.scripts[-1],
		[
			scene_name+"."+option
		]
	)
