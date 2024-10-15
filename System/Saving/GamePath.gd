extends Reference
class_name GamePath

var script_root_path:String
var game_root_path:String
func _pop(path:String):
	# Split path into a root and the folder
	if path.ends_with("/"):
		path = path.substr(0, path.length()-1)
	if not "/" in path:
		return ["", path]
	return path.rsplit("/", true, 1)
func from_main(main):
	script_root_path = main.current_game
	game_root_path = main.top_script().root_path
	from_path(game_root_path)
	return self
func from_path(path):
	# We have a full path the folder running the current script
	# This may include a game and a case
	# This may include just a folder (for tests)
	var arr = _pop(path)
	script_root_path = arr[1]
	if not arr[0]:
		game_root_path = "res://"
	else:
		game_root_path = _pop(arr[0])[1]
	return self
func _sanitize(p:String):
	return p.replace(":","").replace("/","")
func get_save_path_name():
	var save_path_name = ".".join([_sanitize(game_root_path), script_root_path])
	if save_path_name.ends_with("."):
		save_path_name = save_path_name.substr(0, save_path_name.length()-1)
	return save_path_name
