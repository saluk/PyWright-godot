extends Node
class_name DirectoryIndex

# Files indexed according to a path from a starting directory
# Files not located on the starting directory are looked up in a previous path

var root_path:String
var check_directories =[
	"art", "music", "sfx", "movies"
]

var files = {
	
}

func make_key(path:String):
	var erase_path = root_path
	if not erase_path.ends_with("/") and not erase_path == "res://":
		erase_path += "/"
	return path.replace(erase_path, "").to_lower()

func index_file(path:String, file_name:String):
	var full_path = Filesystem.path_join(path, file_name)
	files[make_key(full_path)] = full_path

func index_dir(path, ignore_paths = [], check_directories=[]):
	print("INDEX_DIR "+path+" "+str(ignore_paths)+", "+str(check_directories))
	if path.ends_with("/") and path != "res://":
		path = path.substr(0, path.length()-1)
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			#print("check file name "+path+">"+file_name)
			if file_name == "":
				break
			if file_name == "." or file_name == "..":
				pass
			elif dir.current_is_dir():
				if file_name in ignore_paths:
					continue
				#if check_directories.size() > 0 and not file_name in check_directories:
				#	continue
				index_dir(Filesystem.path_join(path, file_name), ignore_paths)
			else:
				print("indexing file "+file_name)
				index_file(path, file_name)
	else:
		print("error opening directory "+path)

func start_index_at(root_path:String, ignore_paths = []):
	self.root_path = root_path
	var current_dir = root_path
	index_dir(current_dir, ignore_paths, self.check_directories)
	pass

func _lookup(path):
	var key = make_key(path)
	if key in files:
		return files[key]
	return null

func lookup(path:String, prefer_extension=[]):
	# TODO probably move to filesystem
	if prefer_extension:
		var ext = ""
		var root = path
		if path.find_last(".") > path.find_last("/") and path.find_last("."):
			var split = path.rsplit(".")
			root = split[0]
			ext = split[1]
		for next in prefer_extension:
			var found = _lookup(root+"."+next)
			if found:
				return found
	else:
		return _lookup(path)
	return null
