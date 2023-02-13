extends Reference

func _init(commands):
	pass

class Scroller extends Node:
	var objects = []
	var tween:Tween
	var wait_signal = ""
	var total = Vector3(0.0, 0.0, 0.0)
	var move = Vector3(0.0, 0.0, 0.0)
	var speed = 1   # Pixels to scroll per frame
	var time_left = 0.0
	var total_time = 0.0
	var script_name = "scroll"
	var z = 0
	func _init(x, y, z, speed, wait, filter):
		name = "scroll"
		total = Vector2(x, y)
		objects = getscrollable(Commands.get_objects(null, false))
		move = total.normalized() * (speed/0.02)
		time_left = total.length()/(speed/0.02)
		total_time = time_left
		if wait:
			wait_signal = "tree_exited"
	func make_tweens():
		tween = Tween.new()
		add_child(tween)
		for o in objects:
			tween.interpolate_property(
				o, 
				"global_position", 
				o.global_position, 
				o.global_position+total, 
				total_time, 
				Tween.TRANS_LINEAR
			)
			print(o.name)
			print(o.global_position)
			print(total)
			print(o.global_position+total)
		tween.start()
	func getscrollable(objects):
		var return_list = []
		for o in objects:
			if "scrollable" in o and o.scrollable:
				return_list.append(o)
		return return_list
	func control(script_name):
		objects = getscrollable(Commands.get_objects(script_name))
		if objects:
			objects = [objects[-1]]
		pass
	func control_last():
		objects = getscrollable(Commands.get_objects(null, true))
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
		#tween.seek(total_time-time_left)
		time_left -= dt
		if time_left <= 0:
			queue_free()
	
static func ws_scroll(script, arguments):
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
	scroller.make_tweens()
	return scroller
