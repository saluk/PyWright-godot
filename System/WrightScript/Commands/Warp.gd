extends Reference
class_name WarpLib

func _init(commands):
	pass

class WarpAnim extends Node:
	var objects:Array
	var wait_signal := ""
	var end_tweaks:Dictionary = {}
	var total_time:float = 60.0  # How many pywright units should we take
	var script_name := "warp"
	var z := 0
	var tweens:Array
	var ulx := 0.0
	var uly := 0.0
	var urx := 0.0
	var ury := 0.0
	var lrx := 0.0
	var lry := 0.0
	var llx := 0.0
	var lly := 0.0
	var keys = ["ulx","uly","urx","ury","lrx","lry","llx","lly"]
	func _init(objects:Array, time:float, end_tweaks:Dictionary, wait:bool):
		self.objects = objects
		self.total_time = time
		for k in keys:
			self.end_tweaks[k] = end_tweaks[k]
		for k in keys:
			var sk = "s"+k
			set(k, end_tweaks.get(sk, 0.0))
		name = "warp"
		if wait:
			wait_signal = "tree_exited"
		Pauseable.new(self)
	func get_screen():
		return get_parent()
	func make_tweens():
		for k in keys:
			var tween = Tween.new()
			tweens.append(tween)
			add_child(tween)
			tween.interpolate_property(
				self,
				k,
				get(k),
				end_tweaks[k],
				total_time/60.0,
				Tween.TRANS_LINEAR
			)
			tween.start()
			tween.connect("tween_completed", self, "end_tween", [tween])
	func _process(dt):
		for o in objects:
			for k in keys:
				print(k, get(k))
				o.set_sprite_material_param(k, get(k))
	func end_tween(object, nodepath, tween):
		if tween in get_children():
			tween.queue_free()
		if tween in tweens:
			tweens.erase(tween)
		if not tweens:
			queue_free()
	# SAVE/LOAD
	var save_properties = [
		"wait_signal", "total", "move", "speed", "time_left", "total_time",
		"script_name", "z", "controlled"
	]
	func save_node(data):
		data["loader_class"] = "res://System/WrightScript/Commands/Warp.gd"

	func load_node(tree, saved_data:Dictionary):
		# TODO we should be added to correct scene. save load doesn't handle screens yet
		ScreenManager.main_screen.add_child(self)

	func after_load(tree, saved_data:Dictionary):
		var control_method = saved_data["controlled"][0]
		var control_arg = saved_data["controlled"][1]
		make_tweens()

static func create_node(saved_data:Dictionary):
	var ob = WarpAnim.new([], 0.0, {}, false)
	return ob

func ws_warp(script, arguments):
	var d = Commands.keywords(arguments)
	var objects = script.screen.get_objects(d["name"])
	var wait = not "nowait" in arguments
	for k in ["ulx","uly","urx","ury","lrx","lry","llx","lly", "time"]:
		d[k] = float(d.get(k, 0))
		d["s"+k] = float(d.get("s"+k, 0))
	var warp_anim = WarpAnim.new(objects, d["time"], d, wait)
	script.screen.add_child(warp_anim)
	warp_anim.make_tweens()
	warp_anim._process(0)
	return warp_anim
