extends Reference
class_name Testing

# Functions to be used to make a wrightscript file testable

# From a script, we should be able to have two methods:
# ut_next - run the command after the next line is executed
# ut_after time - run the command after this many seconds

# The command should be gdscript and pull from possible helper functions in this class
	
var template = """
extends Testing
	
static func command():
	return {command}
"""

static func objects(name=null):
	return Commands.get_objects(name)
	
static func textbox():
	var obs = Commands.get_objects(null, null, Commands.TEXTBOX_GROUP)
	if obs:
		return obs[0]
	
class line_query:
	var text
	func _init(text):
		self.text = text
	func has(chars):
		return chars in text
	
static func current_line():
	var scripts = Commands.main.stack.scripts
	if not scripts:
		return null
	return line_query.new(scripts[-1].get_next_line(0))
	
# TODO Having some issues with simulating mouseclicks in godot
#static func world_to_screen(v):
#	var view = Commands.main.get_viewport()
#	var screen_size = view.size
#	var world_size = view.get_visible_rect().size
#	return Vector2(
#		v.x/world_size.x * screen_size.x,
#		v.y/world_size.y * screen_size.y
#	)
#
#static func click_release_at(x, y):
#
#	var debug_click = load("res://System/Testing/DebugMouseClick.tscn").instance()
#	Commands.main.add_child(debug_click)
#	debug_click.position = Vector2(x, y)
#	debug_click.get_node("AnimationPlayer").play("ScaleFadeOut")
#	Commands.main.get_tree().create_timer(1).connect("timeout", debug_click, "queue_free")
#
#	var event_lmb = InputEventMouseButton.new()
#	event_lmb.button_index = BUTTON_LEFT
#	event_lmb.position = Vector2(x, y) * 2.1
#	print(event_lmb.position)
#	event_lmb.pressed = true
#	Input.parse_input_event(event_lmb)
#	Commands.main.get_tree().create_timer(0.1).connect("timeout", Commands.main.stack.testing, "release_at", [x, y])
#
#static func release_at(x, y):
#	print("release ", str(x), ", ", str(y))
#	var event_lmb = InputEventMouseButton.new()
#	event_lmb.button_index = BUTTON_LEFT
#	event_lmb.position = Vector2(x, y) * 2.1
#	event_lmb.pressed = false
#	Input.parse_input_event(event_lmb)
#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
static func click_button(name):
	for button in objects(name):
		button.click_area.perform_action()
	
static func exit():
	Commands.call_command("exit", Commands.main.top_script(), [])
	
func run(string, do_assert=false):
	var script = GDScript.new()
	script.set_source_code(template.format({
		"command": string
	}))
	script.reload()
	
	var obj = Reference.new()
	obj.set_script(script)
	
	var v = obj.command()
	if v is GDScriptFunctionState:
		v = yield(v, "completed")
	if do_assert:
		assert(v)
