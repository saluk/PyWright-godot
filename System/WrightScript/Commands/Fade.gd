extends Reference
class_name FadeLib

func _init(commands):
	pass

class Fader extends Node:
	var objects = []
	var wait_signal = ""
	var start = 0.0
	var end = 100.0
	var speed = 1.0   # Percent to fade in 1 frame
	var script_name = "fade"
	var z = 0
	func _init(start, end, speed, wait):
		self.start = float(start)
		self.end = float(end)
		self.speed = float(speed)
		name = "fade"
		objects = Commands.get_objects(null, false)
		if wait:
			wait_signal = "tree_exited"
	func control(script_name):
		objects = Commands.get_objects(script_name)
		if objects:
			objects = [objects[-1]]
	func control_last():
		objects = [Commands.get_objects(null, true)]
		if objects:
			objects = [objects[0]]
	func control_all(screen):
		objects = Commands.get_objects(null, true)
	func set_fade():
		for object in objects:
			if is_instance_valid(object):
				object.modulate = Color(1, 1, 1, start/100.0)
	func _process(dt):
		set_fade()
		if start < end:
			start += dt*speed*60
			if start >= end:
				start = end
				set_fade()
				queue_free()
		elif start > end:
			start -= dt*speed*60
			if start <= end:
				start = end
				set_fade()
				queue_free()
	
static func ws_fade(script, arguments):
	var kw = Commands.keywords(arguments)
	var fade_in = "in" in arguments
	var fade_out = "out" in arguments
	var start = kw.get("start", 0)
	var end = kw.get("end", 100)
	if fade_in:
		start = 0
		end = 100
	elif fade_out:
		start = 100
		end = 0
	var x = int(kw.get("x", 0))
	var y = int(kw.get("y", 0))
	var z = int(kw.get("z", 0))
	var speed = float(kw.get("speed", 1))
	var last = "last" in arguments
	var wait = not "nowait" in arguments
	var script_name = kw.get("name", null)
	var fader = Fader.new(start, end, speed, wait)
	if script_name:
		fader.control(script_name)
	elif last:
		fader.control_last()
	else:
		fader.control_all()
	script.screen.add_child(fader)
	return fader
