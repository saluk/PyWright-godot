extends Reference
class_name SaveState

####### Save format #####
# Commands
#   .last_object -> NodePath, after_load
# ZLayers (skip)
# MusicPlayer
#	.loop -> bool
#	.playing -> bool
#	.playing_path -> string
#	.MUSIC_VOLUME (skip)
#	.audio_player -> instance
#		playing position -> float
# SoundPlayer
# 	.loop -> bool
#	.playing -> bool
#	.playing_path -> string
#	.SOUND_VOLUME (skip)
#	.players -> array, instances
#		playing position -> float


static func save_game(tree:SceneTree, filename:String):
	var objects = []
	var nodes = [tree.root]
	while nodes:
		var node = nodes.pop_front()
		var saved = _save_node(node)
		if saved:
			objects.append(saved)
		for child in node.get_children():
			nodes.append(child)
	var file = File.new()
	print("saving:", objects)
	file.open(filename, File.WRITE)
	file.store_string(
		to_json(objects)
	)
	file.close()
			
static func _save_node(node):
	if node.has_method("save_node"):
		var save = {}
		var cannot_save = node.save_node(save)
		if not cannot_save:
			# Non nodes will have to be restored to the tree outisde this script
			if node.has_method("get_path"):
				save["original_node_path"] = node.get_path()
			if "save_properties" in node:
				save_properties(node, save)
			return save
	return null
	
static func _load_node(tree, ob, ob_data):
	load_properties(ob, ob_data)
	ob.load_node(tree, ob_data)
	
static func save_properties(node, save):
	for prop in node.save_properties + ["name"]:
		if prop in node:
			var val = node.get(prop)
			if val is Vector3:
				val = {"Vector3":[val.x,val.y,val.z]}
			elif val is Vector2:
				val = {"Vector2":[val.x,val.y]}
			elif val is Node:
				val = 0
			elif val is bool:
				pass
			elif val is String:
				pass
			elif val==null:
				continue
			elif val is Dictionary:
				pass
			elif val is int:
				pass
			elif val is float:
				pass
			elif val is Array:
				pass
			else:
				print("error")
			save[prop] = val
	if node.has_method("get_groups"):
		save["_groups_"] = node.get_groups()
		
static func load_properties(node, data):
	if not "save_properties" in node:
		return
	for prop in node.save_properties + ["name"]:
		if prop in data:
			var val = data[prop]
			if val is Dictionary:
				if "Vector3" in val:
					val = Vector3(val["Vector3"][0],val["Vector3"][1],val["Vector3"][2])
				elif "Vector2" in val:
					val = Vector2(val["Vector2"][0],val["Vector2"][1])
			node.set(prop, val)
	if "_groups_" in data:
		for group in data["_groups_"]:
			node.add_to_group(group)
	
static func load_game(tree:SceneTree, filename:String):
	var file = File.new()
	var err = file.open(filename, File.READ)
	if err != OK:
		return false
	var json = file.get_as_text()
	var data = parse_json(json)
	file.close()
	
	ScreenManager.clear()
	
	var after_load = []

	for ob_data in data:
		print(ob_data)
		var ob
		if tree.root.has_node(ob_data["original_node_path"]):
			ob = tree.root.get_node(ob_data["original_node_path"])
		elif "loader_class" in ob_data:  # Overrides entire load process
			var c = load(ob_data["loader_class"])
			ob = c.create_node(ob_data)
		else:
			continue
		_load_node(tree, ob, ob_data)
		after_load.append(ob)
		tree.connect("idle_frame", ob, "after_load", [tree, ob_data], tree.CONNECT_ONESHOT)

static func to_node_path(ob:Object):
	if not ob:
		return null
	return (ob as Node).get_path()
	
static func from_node_path(tree:SceneTree, path:String):
	return tree.root.get_node(path)
