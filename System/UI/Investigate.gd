extends WrightObject

var scene_name:String
var fail_label:String

var order = ["examine", "move", "talk", "present"]
var relative_positions = {
	"examine": Vector2(0, 0),
	"move": Vector2(1, 0),
	"talk": Vector2(0, 1),
	"present": Vector2(1, 1)
}

func _ready():
	script_name = "invest_menu"
	wait_signal = "tree_exited"
	wait = true
	
func load_art(root_path):
	pass

func add_option(option):
	var rect_offset = relative_positions[option]
	var button = ObjectFactory.create_from_template(
		get_tree().root.get_node("Main").top_script(),
		"button",
		{"sprites":{
			"default": {"path": "art/general/talkbuttons.png"},
			"highlight": {"path": "art/general/talkbuttons_high.png"}
		},
		"click_macro": "{investigate_option}",
		"click_args": [option],
		"rect": Rect2(226/2*rect_offset.x, 59/2*rect_offset.y, 226/2, 59/2)},
		["name="+option],
		script_name
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
			stack.scripts[-1],
			[
				scene_name+"."+option
			]
		)
	elif fail_label:
		stack.scripts[-1].goto_label(option, fail_label)
	else:
		print("bad investigate menu")
		assert(0)
	queue_free()
	
func save_node(data):
	# Return that we can't save
	# TODO - enable saving of investigate menu
	return true
