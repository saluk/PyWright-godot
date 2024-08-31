extends Reference
class_name Variables

var store := {}

var setters := ["_speaking", "_music_fade"]
var getters := ["_version"]

func _init():
	reset()
	
func reset():
	self.store = {}

func set_val(key, value):
	if key in setters:
		call("setter_"+key, value)
	store[key] = str(value)
	
func del_val(key):
	store.erase(key)
	
func _get_val(key, default):
	if key in getters:
		return call("getter_"+key)
	return store.get(key, default)

func get_val(key, default):
	return _get_val(key, default)

func setter__speaking(val):
	store["_speaking"] = val
	store["_speaking_name"] = Commands.get_nametag()
	
func setter__music_fade(val):
	store["_music_fade"] = val
	MusicPlayer.alter_volume()

func getter__version():
	return str(Configuration.builtin.version)

# Functions to access a namespace as a list


# SAVE/LOAD
var save_properties = [
	"store", "setters"
]
func save_node(data):
	pass

static func create_node(saved_data:Dictionary):
	pass # Not called
	
func load_node(tree, saved_data:Dictionary):
	pass

func after_load(tree:SceneTree, saved_data:Dictionary):
	pass # Not called
