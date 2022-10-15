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

func index_dir(path):
	pass

func start_index_at(root_path:String):
	self.root_path = root_path
	var current_dir = root_path
	while current_dir != "res://":
		index_dir(current_dir)
		current_dir = "res://"
