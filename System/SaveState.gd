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
	for node in tree.root.get_children():
		var saved = _save_node(node)
		if saved:
			objects.append(saved)
	var file = File.new()
	print("saving:", objects)
	file.open(filename, File.WRITE)
	file.store_string(
		to_json(objects)
	)
	file.close()
			
static func _save_node(node):
	print(node.get_path())
	if node.has_method("save_node"):
		var save = {
			"original_node_path": node.get_path()
		}
		if "save_properties" in node:
			save_properties(node, save)
		node.save_node(save)
		return save
	return null
	
static func save_properties(node, save):
	for prop in node.save_properties:
		save[prop] = node.get(prop)
		
static func load_properties(node, data):
	if not "save_properties" in node:
		return
	for prop in node.save_properties:
		node.set(prop, data[prop])
	
static func load_game(tree:SceneTree, filename:String):
	var file = File.new()
	var err = file.open(filename, File.READ)
	if err != OK:
		return false
	var json = file.get_as_text()
	var data = parse_json(json)
	file.close()
	
	Commands.clear_main_screen()

	for ob_data in data:
		print(ob_data)
		var existing = tree.root.get_node(ob_data["original_node_path"])
		if existing:
			existing.load_node(ob_data)
			load_properties(existing, ob_data)
		elif "loader_class" in ob_data:
			var c = load(ob_data["loader_class"])
			var ob = c.load_node(ob_data)
			
	for ob_data in data:
		var existing = tree.root.get_node(ob_data["original_node_path"])
		if existing and existing.has_method("after_load"):
			existing.after_load(ob_data)
			

static func to_node_path(ob:Object):
	if not ob:
		return null
	return (ob as Node).get_path()
	
static func from_node_path(tree:SceneTree, path:String):
	return tree.root.get_node(path)
