extends Node
class_name DirectoryIndexStack

var write_cache = true
var read_cache = false

var stack
func _init():
	self.stack = []
func lookup_path(path, prefer_extension=[]):
	var found
	var i = 0
	while i < self.stack.size():
		found = self.stack[i].lookup(path, prefer_extension)
		if found:
			return found
		i += 1
	return found

func build_stack(root_path:String, ignore_paths = [".git", ".import"]):
	print("build directory at root_path "+root_path)
	if not root_path.begins_with("res://"):
		root_path = "res://"+root_path
		
	var cache_filename = Filesystem.path_join(root_path, "dir.index")

	if read_cache:
		var file = File.new()
		if not file.file_exists(cache_filename):
			pass
		else:
			file.open(cache_filename, File.READ)
			var data = parse_json(file.get_as_text())
			for dir_index_data in data:
				var dirindex = DirectoryIndex.new()
				dirindex.root_path = dir_index_data[0]
				dirindex.files = dir_index_data[1]
				self.stack.append(dirindex)
			return

	self.stack = []
	while root_path:
		if root_path != "res://" and root_path.ends_with("/"):
			root_path = root_path.substr(0, root_path.length()-1)

		print("INDEXING "+root_path)
		var dirindex = DirectoryIndex.new()
		dirindex.start_index_at(root_path, ignore_paths)
		print("finish index")
		print(dirindex.files.keys().size())
		self.stack.append(dirindex)
		
		if root_path == "res://":
			break

		var paths = root_path.rsplit("/", true, 1)
		paths.remove(paths.size()-1)
		root_path = paths.join("/")+"/"
	
	if write_cache:
		var file = File.new()
		var save_stack = []
		for dirindex in self.stack:
			save_stack.append(
				[dirindex.root_path,
				dirindex.files]
			)
		file.open(cache_filename, File.WRITE)
		file.store_line(to_json(save_stack))
		file.close()

