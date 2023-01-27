extends Reference
class_name Variables

var store := {}

var setters := ["_speaking"]

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
	return store.get(key, default)

func setter__speaking(val):
	store["_speaking"] = val
	store["_speaking_name"] = Commands.get_nametag()

# Functions to access a namespace as a list
