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
		objects = []
		if wait:
			wait_signal = "tree_exited"
		Pauseable.new(self)
	func get_screen():
		return get_parent()
	func control_all_named(script_name):
		objects = get_screen().get_objects(script_name)
	func control_last():
		objects = [get_screen().get_objects(null, true)]
		if objects:
			objects = [objects[-1]]
	func control_all(screen):
		objects = get_screen().get_objects(null, true)
	func set_fade():
		for object in objects:
			if is_instance_valid(object) and "modulate" in object:
				object.modulate = Color(1, 1, 1, start/100.0)
	func _process(dt):
		if start < end:
			start += dt*speed*60
			if start >= end:
				start = end
				queue_free()
		elif start > end:
			start -= dt*speed*60
			if start <= end:
				start = end
				queue_free()
		set_fade()

# TODO 2.0 make a version that deletes objects when you fade them out
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
	script.screen.add_child(fader)
	if script_name:
		fader.control_all_named(script_name)
	elif last:
		fader.control_last()
	else:
		fader.control_all()
	return fader
