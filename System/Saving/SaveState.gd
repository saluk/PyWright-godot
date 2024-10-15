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
	GlobalErrors.log_info("Saving game: %s" % filename)
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
	if file.open(filename, File.WRITE) != OK:
		print("Couldn't open file for saving")
	file.store_string(
		to_json(objects)
	)
	file.close()

static func _save_node(node):
	if node.has_method("save_node"):
		var save = {}
		var cannot_save = node.get("cannot_save")
		if not cannot_save:
			cannot_save = node.save_node(save)
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
	if ob:
		ob.load_node(tree, ob_data)

static func save_properties(node, save):
	for prop in node.save_properties + ["name"]:
		if prop in node:
			var val = node.get(prop)
			if val is Vector3:
				val = {"Vector3":[val.x,val.y,val.z]}
			elif val is Vector2:
				val = {"Vector2":[val.x,val.y]}
			elif val is Color:
				val = {"Color":[val.r,val.g,val.b,val.a]}
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
	if not node:
		return
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
				elif "Color" in val:
					val = Color(val["Color"][0], val["Color"][1], val["Color"][2], val["Color"][3])
			node.set(prop, val)
	if "_groups_" in data:
		for group in data["_groups_"]:
			node.add_to_group(group)

static func load_game(main, tree:SceneTree, filename:String):
	GlobalErrors.log_info("Loading game: %s" % filename)
	DirectoryCache.clear()
	main.reset()

	var file = File.new()
	var err = file.open(filename, File.READ)
	if err != OK:
		return false
	var json = file.get_as_text()
	var data = parse_json(json)
	file.close()

	ScreenManager.clear()

	for ob_data in data:
		GlobalErrors.log_info("Load Object %s" % ob_data["original_node_path"])
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
		tree.connect("idle_frame", ob, "after_load", [tree, ob_data], tree.CONNECT_ONESHOT)
	#for ob_data_arr in after_load:
	#	ob_data_arr[0].after_load(tree, ob_data_arr[1])

static func to_node_path(ob:Object):
	if not ob:
		return null
	return (ob as Node).get_path()

static func from_node_path(tree:SceneTree, path:String):
	return tree.root.get_node(path)

# User facing save functions

static func load_selected_save_file(main, root_path, filename):
	var save_path_name = GamePath.new().from_path(root_path).get_save_path_name()
	var full_save_path = "user://game_saves/"+"/".join([save_path_name, filename])
	load_game(main, main.get_tree(), full_save_path)

static func delete_selected_save_file(main, filename):
	var save_path_name = GamePath.new().from_main(main).get_save_path_name()
	var full_save_path = "user://game_saves/"+"/".join([save_path_name, filename])
	var d = Directory.new()
	d.remove(full_save_path)

static func save_new_file(main, new_filename):
	var save_path_name = GamePath.new().from_main(main).get_save_path_name()
	var date = Time.get_datetime_dict_from_system()
	if not new_filename:
		new_filename = Time.get_datetime_string_from_datetime_dict(date, true)
	new_filename = new_filename.replace(":","-")
	var full_save_path = "user://game_saves/"+"/".join([save_path_name, new_filename+".save"])
	save_game(main.get_tree(), full_save_path)

static func get_saved_games_for_current(gp):
	var save_path_name = gp.get_save_path_name()
	var d
	var path = "user://game_saves"
	Filesystem.make_if_not_exists_dir(path)

	# Ensure save folder exists for this game
	path += "/" + save_path_name
	Filesystem.make_if_not_exists_dir(path)

	var save_files = []
	d = Directory.new()
	if d.open(path) == OK:
		d.list_dir_begin()
		var file_name = d.get_next()
		while file_name != "":
			if file_name.begins_with(".") or d.current_is_dir():
				pass
			else:
				save_files.append([path, file_name])
			file_name = d.get_next()
	else:
		print("An error occurred when trying to access the path %s." % path)
	save_files.sort_custom(Filesystem, "sort_files_by_time")
	return save_files

