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
	
static func click_release_at(x, y):
	var event_lmb = InputEventMouseButton.new()
	event_lmb.position = Vector2(x, y)
	event_lmb.pressed = true
	Input.parse_input_event(event_lmb)
	Commands.main.get_tree().create_timer(0.5).connect("timeout", Commands.main.stack.testing, "release_at", [x, y])
	
static func release_at(x, y):
	var event_lmb = InputEventMouseButton.new()
	event_lmb.position = Vector2(x, y)
	event_lmb.pressed = false
	Input.parse_input_event(event_lmb)
	
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
