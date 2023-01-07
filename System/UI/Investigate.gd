extends Node2D
var script_name = "invest_menu"
var wait_signal = "tree_exited"

var scene_name:String
var fail_label:String
var z:int

var order = ["examine", "move", "talk", "present"]
var relative_positions = {
	"examine": Vector2(0, 0),
	"move": Vector2(1, 0),
	"talk": Vector2(0, 1),
	"present": Vector2(1, 1)
}
	
func load_art(root_path):
	pass

func add_option(option):
	var rect_offset = relative_positions[option]
	var button = Commands.add_button_to_interface(
		self,
		"art/general/talkbuttons.png",
		"art/general/talkbuttons_high.png",
		"investigate_option",
		[option],
		Rect2(226/2*rect_offset.x, 59/2*rect_offset.y, 226/2, 59/2)
	)
	button.position = Vector2(
		(256/2-button.width) + rect_offset.x*button.width,
		(192/2-button.height) + rect_offset.y*button.height+192
	)

func ws_investigate_option(script, args):
	var option = args[0]
	if scene_name:
		Commands.call_command(
			"script",
			Commands.main.stack.scripts[-1],
			[
				scene_name+"."+option
			]
		)
	elif fail_label:
		Commands.main.stack.scripts[-1].goto_label(option, fail_label)
	else:
		print("bad investigate menu")
		assert(0)
	queue_free()
