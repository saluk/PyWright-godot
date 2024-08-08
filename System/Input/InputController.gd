extends Control
class_name InputController

onready var main = get_parent()
onready var screens = main.screens

# TODO this is pretty hacky
func scan_objects(action, button_names=[]):
	var objects:Array = Commands.get_objects(null)
	var found_object = null
	for i in range(objects.size()-1, 0, -1):
		var ob = objects[i]
		if "blocks_action_"+action in ob:
			if ob.blocks_action_advance:
				found_object = ob
				break
		if ob.has_method("action_press_"+action):
			found_object = ob
			ob.action_press_advance()
			break
		if ob.name in button_names and ob.click_area:
			ob.click_area.perform_action()
			found_object = ob
			break
	return found_object

func _unhandled_input(event):
	if event.is_action_released("button_advance"):
		stop_hold("advance")
		
var held = {}
func start_hold(action):
	if not action in held:
		held[action] = 0.0
		return true
	return false
func stop_hold(action):
	if action in held:
		held.erase(action)
func add_delta(action, delta):
	var just_started = start_hold(action)
	held[action] += delta
	return just_started

func _process(delta):
	# TODO - if the enter key is blocked, we should require you to repress the key again
	if get_focus_owner() and get_focus_owner() != self:
		return
	if Input.is_action_pressed("button_advance"):
		var just_started = add_delta("advance", delta)
		if held["advance"] > 0.2 or just_started:
			scan_objects("advance", "_main_button_fg")
			if not just_started:
				stop_hold("advance")
		
