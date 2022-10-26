extends Reference

class Scroller extends Node:
	var objects = []
	var wait_signal = ""
	var total = Vector3(0.0, 0.0, 0.0)
	var move = Vector3(0.0, 0.0, 0.0)
	var speed = 1   # Pixels to scroll per frame
	var time_left = 0.0
	var script_name = "scroll"
	var z = 0
	func _init(x, y, z, speed, wait, filter):
		name = "scroll"
		total = Vector2(x, y)
		objects = Commands.get_objects(null, false)
		move = total.normalized() * (speed/0.02)
		time_left = total.length()/(speed/0.02)
		if wait:
			wait_signal = "tree_exited"
	func control(script_name):
		objects = Commands.get_objects(script_name)
		if objects:
			objects = [objects[-1]]
		pass
	func control_last():
		objects = [Commands.get_objects(null, true)]
		if objects:
			objects = [objects[0]]
	func control_filter(screen):
		var new_objects = []
		for o in objects:
			if screen == "top" and o.position.y >= 192:
				continue
			if screen == "bottom" and o.position.y < 192:
				continue
			new_objects.append(o)
		objects = new_objects
		pass
	func _process(dt):
		for object in objects:
			if is_instance_valid(object):
				object.position += move * dt
		time_left -= dt
		if time_left <= 0:
			queue_free()
	
static func call_func(script, arguments):
	var kw = Commands.keywords(arguments)
	var x = int(kw.get("x", 0))
	var y = int(kw.get("y", 0))
	var z = int(kw.get("z", 0))
	var speed = int(kw.get("speed", 1))
	var last = "last" in arguments
	var wait = not "nowait" in arguments
	var script_name = kw.get("name", null)
	var filter = kw.get("filter", "top")   
	#filter is top or bottom - when no name, only scroll objects on this screen.
	#if its not top or bottom, it has no effect
	var scroller = Scroller.new(x, y, z, speed, wait, filter)
	if script_name:
		scroller.control(script_name)
	elif last:
		scroller.control_last()
	else:
		scroller.control_filter(filter)
	Commands.main_screen.add_child(scroller)
	return scroller
