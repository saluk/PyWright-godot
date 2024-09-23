extends Reference
class_name Variables

var store := {}

var setters := ["_speaking", "_music_fade"]
var getters := ["_version", "_engine"]

func _init():
	assert(string_to_array("", ",")==PoolStringArray([]))
	assert(string_to_array(",", ",")==PoolStringArray([""]))
	assert(string_to_array("ad,bwww,ceeeee,", ",")==PoolStringArray(["ad","bwww","ceeeee"]))
	assert(array_to_string([], ",")=="")
	assert(array_to_string([""], ",")==",")
	assert(array_to_string(["ad","bwww","ceeeee"], ",")=="ad,bwww,ceeeee,")
	reset()

func reset():
	self.store = {}

func set_val(key, value, split_on=null):
	# TODO this is implemented in variables and in namespaces?
	if split_on != null:
		value = array_to_string(value, split_on)
	if key in setters:
		call("setter_"+key, value)
	store[key] = str(value)

func del_val(key):
	store.erase(key)

func _get_val(key, default, split_on=null):
	if key in getters:
		return call("getter_"+key)
	var val = store.get(key, default)
	if split_on != null:
		val = string_to_array(val, split_on)
	return val

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

func getter__engine():
	return str(Configuration.builtin.engine)

# "" -> []
# "," -> [""]
# "a,b,c, -> ["a","b","c"]
static func string_to_array(string, split_on):
	assert(split_on.length()==1)
	if not split_on in string:
		return PoolStringArray([])
	var array = string.substr(0, string.length()-1).split(split_on, true)
	return array

static func array_to_string(array, split_on):
	assert(split_on.length()==1)
	if array.size() == 0:
		return ""
	if array.size() == 1:
		return str(array[0])+split_on
	return PoolStringArray(array).join(split_on)+split_on

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
