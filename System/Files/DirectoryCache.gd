extends Node

# Caches game folder indexes of known filenames

var indexes := {}

func _ready():
	if 0:#OS.has_feature("standalone") or OS.has_feature("HTML5"):
		if not load_game_file_index("res://"):
			print("WARNING: could not load file index res://")
			return
	else:
		clear()
		
func clear():
	indexes.clear()
	create_game_cache("res://", ["res://art", "res://music", "res://sfx", "res://fonts"])
	save_game_file_index("res://")
	
func init_game(game_path):
	if 0:#OS.has_feature("standalone") or OS.has_feature("HTML5"):
		if not load_game_file_index(game_path):
			print("WARNING: could not load file index ", game_path)
			return
	else:
		create_game_cache(game_path)
		save_game_file_index(game_path)

# When loading a game, we can cache load its file index from a file, or create the file index
func load_game_file_index(game_path):
	var file_path = Filesystem.path_join(game_path, "files.index")
	var game_file_index = FileAccess.open(file_path, FileAccess.READ)
	if not game_file_index:
		print("CANNOT LOAD INDEX: ", file_path)
		return false
	var test_json_conv = JSON.new()
	test_json_conv.parse(game_file_index.get_line())
	indexes[game_path] = test_json_conv.get_data()
	game_file_index.close()
	return true
	
func create_game_cache(game_path, paths=[]):
	var index = {}
	if not paths:
		paths = [game_path]
	while paths:
		var path = paths.pop_front()
		var dir = DirAccess.open(path)
		if not dir:
			print("ERROR OPENING ",path)
			continue
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break
			if file_name == "." or file_name == "..":
				continue
			if file_name.begins_with("."):
				continue
			if file_name == ".import":
				continue
			var next_path = Filesystem.path_join(path, file_name)
			if dir.current_is_dir():
				paths.append(next_path)
			else:
				# Exported games may not have the raw .png files anymore
				if next_path.ends_with(".import"):
					next_path = next_path.substr(0,next_path.length()-".import".length())
				index[next_path.to_lower()] = next_path

	indexes[game_path] = index
	
func save_game_file_index(game_path):
	var game_file_index = FileAccess.open(Filesystem.path_join(game_path,"files.index"), FileAccess.WRITE)
	if game_file_index != OK:
		return "no index can be saved"
	game_file_index.store_line(JSON.stringify(indexes[game_path]))
	game_file_index.close()

func has_file(file:String):
	var game = ""
	# Determine best game by greedy index match
	for game_key in indexes:
		if file.begins_with(game_key) and game_key.length() > game.length():
			game = game_key
	if game == null or game == "":
		GlobalErrors.log_error("NO GAME FOUND! game:%s file:%s" % [game, file])
	if not game in indexes:
		print("WARNING: no game %s, file:%s" % [game, file])
		print(file)
		return null
	var index = indexes[game]
	if not file.to_lower() in index:
		print("  file not in cache: '%s', looked in game '%s'" % [file, game])
		return null
	return index[file.to_lower()]
