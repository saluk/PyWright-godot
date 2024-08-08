extends Node
class_name InputController

onready var main = get_parent()
onready var screens = main.screens

# TODO this is pretty hacky
func scan_objects(action, button_names=[]):
	var objects:Array = Commands.get_objects(null)
	for i in range(objects.size()-1, 0, -1):
		var ob = objects[i]
		if "blocks_action_"+action in ob:
			if ob.blocks_action_advance:
				return
		if ob.has_method("action_press_"+action):
			ob.action_press_advance()
			return
		if ob.name in button_names and ob.click_area:
			ob.click_area.perform_action()
			return

func _input(event):
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
	start_hold(action)
	held[action] += delta
	print(held[action])

func _process(delta):
	if Input.is_action_pressed("button_advance"):
		var just_started = add_delta("advance", delta)
		if held["advance"] > 0.2 or just_started:
			scan_objects("advance", "_main_button_fg")
			if not just_started:
				stop_hold("advance")
		
