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
	var save_start_positions := []
	
	var controlled  # for saving
	func _init(x, y, z, speed, wait, filter):
		name = "scroll"
		total = Vector2(float(x), float(y))
		objects = getscrollable(Commands.get_objects(null, false))
		move = total.normalized() * (float(speed)/0.02)
		time_left = float(total.length())/(speed/0.02)
		total_time = time_left
		if wait:
			wait_signal = "tree_exited"
	func make_tweens(start_positions=[]):
		tween = Tween.new()
		add_child(tween)
		for o in objects:
			var next_pos
			if start_positions:
				next_pos = start_positions.pop_front()
			else:
				next_pos = o.position
			tween.interpolate_property(
				o, 
				"position", 
				next_pos, 
				next_pos+total, 
				total_time, 
				Tween.TRANS_LINEAR
			)
			print(o.name)
			print(next_pos)
			print(total)
			print(next_pos+total)
			save_start_positions.append(next_pos)
		tween.start()
	func getscrollable(objects):
		var return_list = []
		for o in objects:
			if "scrollable" in o and o.scrollable:
				return_list.append(o)
		return return_list
	func control(script_name):
		controlled = ["control", script_name]
		objects = getscrollable(Commands.get_objects(script_name))
		if objects:
			objects = [objects[-1]]
		pass
	func control_last():
		objects = getscrollable(Commands.get_objects(null, true))
		if objects:
			objects = [objects[0]]
			controlled = ["control_last", objects[0].get_path()]
	func control_filter(screen):
		var new_objects = []
		for o in objects:
			if screen == "top" and o.position.y >= 192:
				continue
			if screen == "bottom" and o.position.y < 192:
				continue
			new_objects.append(o)
		objects = new_objects
		controlled = ["control_filter", screen]
		pass	
	func _process(dt):
		#tween.seek(total_time-time_left)
		time_left -= dt
		if time_left <= 0:
			queue_free()
	# SAVE/LOAD
	var save_properties = [
		"wait_signal", "total", "move", "speed", "time_left", "total_time",
		"script_name", "z", "controlled"
	]
	func save_node(data):
		data["loader_class"] = "res://System/WrightScript/Commands/Scroll.gd"
		if tween:
			data["time_elapsed"] = tween.tell()
		data["save_start_positions"] = []
		for pos in save_start_positions:
			data["save_start_positions"].append([pos.x, pos.y])
		
	func load_node(tree, saved_data:Dictionary):
		# TODO we should be added to correct scene. save load doesn't handle screens yet
		ScreenManager.main_screen.add_child(self)
		for pos in saved_data["save_start_positions"]:
			save_start_positions.append(Vector2(pos[0], pos[1]))

	func after_load(tree, saved_data:Dictionary):
		var control_method = saved_data["controlled"][0]
		var control_arg = saved_data["controlled"][1]
		if control_method == "control":
			self.control(control_arg)
		elif control_method=="control_last":
			objects = [tree.root.get_node(control_arg)]
		elif control_method == "control_filter":
			self.control_filter(control_arg)
		make_tweens(save_start_positions)
		if "time_elapsed" in saved_data:
			tween.seek(saved_data["time_elapsed"])

static func create_node(saved_data:Dictionary):
	var ob = Scroller.new(20,0,0,1,0,"")
	return ob
	
static func ws_scroll(script, arguments):
	var kw = Commands.keywords(arguments)
	var x = int(kw.get("x", 0))
	var y = int(kw.get("y", 0))
	var z = int(kw.get("z", 0))
	var speed = float(kw.get("speed", 1))
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
	ScreenManager.top_screen().add_child(scroller)
	scroller.make_tweens()
	return scroller
