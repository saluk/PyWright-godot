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

func get_string(key, default=""):
	var val = store.get(key, default)
	if val is String:
		return val
	return ""

func get_int(key, default=0):
	return int(store.get(key, default))
	
func get_float(key, default=0.0):
	return float(store.get(key, default))
	
func get_num(key, default=0.0):
	return Values.to_num(store.get(key, default))

func get_truth(key, default="false"):
	return WSExpression.string_to_bool(get_string(key, default))

func get_truth_string(key, default="false"):
	if get_truth(key, default):
		return 'true'
	return 'false'

func setter__speaking(val):
	store["_speaking"] = val
	store["_speaking_name"] = Commands.get_nametag()
