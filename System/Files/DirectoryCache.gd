extends Node

# Caches game folder indexes of known filenames

var indexes = {}

func _ready():
	if OS.has_feature("standalone") or OS.has_feature("HTML5"):
		if not load_game_file_index("res://"):
			print("WARNING: could not load file index res://")
			return
	else:
		create_game_cache("res://", ["res://art", "res://music", "res://sfx"])
		save_game_file_index("res://")
	
func init_game(game_path):
	if OS.has_feature("standalone") or OS.has_feature("HTML5"):
		if not load_game_file_index(game_path):
			print("WARNING: could not load file index ", game_path)
			return
	else:
		create_game_cache(game_path)
		save_game_file_index(game_path)

# When loading a game, we can cache load its file index from a file, or create the file index
func load_game_file_index(game_path):
	var game_file_index = File.new()
	var file_path = Filesystem.path_join(game_path, "files.index")
	if not game_file_index.file_exists(file_path):
		print("CANNOT FIND: ", file_path)
		return false
	game_file_index.open(file_path, File.READ)
	indexes[game_path] = parse_json(game_file_index.get_line())
	game_file_index.close()
	return true
	
func create_game_cache(game_path, paths=[]):
	var index = {}
	if not paths:
		paths = [game_path]
	while paths:
		var path = paths.pop_front()
		var dir = Directory.new()
		if dir.open(path) != OK:
			continue
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break
			if file_name == "." or file_name == "..":
				continue
			if file_name.begins_with("."):
				continue
			if file_name.ends_with(".import"):
				continue
			var next_path = Filesystem.path_join(path, file_name)
			if dir.current_is_dir():
				paths.append(next_path)
			else:
				# Exported games may not have the raw .png files anymore
				if next_path.ends_with(".import"):
					index[next_path.to_lower().replace(".import","")] = next_path
				else:
					index[next_path.to_lower()] = next_path

	indexes[game_path] = index
	
func save_game_file_index(game_path):
	var game_file_index = File.new()
	game_file_index.open(Filesystem.path_join(game_path,"files.index"), File.WRITE)
	game_file_index.store_line(to_json(indexes[game_path]))
	game_file_index.close()

func has_file(file:String):
	var game
	if "res://tests" in file:
		game = "res://tests"
	elif "res://games" in file:
		game = "res://games/"+file.split("res://games/")[1].split("/")[0]
	else:
		game = "res://"
	if not game in indexes:
		print("WARNING: no game ", game)
		return null
	var index = indexes[game]
	if not file.to_lower() in index:
		print("  file not in cache: ", file)
		return null
	return index[file.to_lower()]
