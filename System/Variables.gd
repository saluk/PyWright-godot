extends Reference
class_name Variables

var DEFAULTS := {
	"ev_mode_bg_evidence": "general/evidence",
	"ev_items_x": "38",
	"ev_items_y": "63",
	"ev_spacing_x": "48",
	"ev_spacing_y": "46",
	"ev_small_width": "35",
	"ev_small_height": "35",
	"ev_big_width": "70",
	"ev_big_height": "70",
	"ev_modebutton_x": "196",
	"ev_modebutton_y": "7"
}
var store := {}

func _init():
	reset()
	
func reset():
	self.store = {}
	for k in DEFAULTS.keys():
		self.store[k] = DEFAULTS[k]

func keys():
	return store.keys()

func set_val(key, value):
	store[key] = str(value)
	
func del_val(key):
	store.erase(key)

func get_string(key, default=""):
	return store.get(key, default)

func get_int(key, default=0):
	return int(store.get(key, default))
	
func get_float(key, default=0.0):
	return float(store.get(key, default))
	
func to_num(v):
	if v is float:
		return v
	if v is String and "." in v:
		return float(v)
	return int(v)
	
func get_num(key, default=0.0):
	return to_num(store.get(key, default))

func get_truth(key, default="false"):
	return WSExpression.string_to_bool(get_string(key, default))

func get_truth_string(key, default="false"):
	if get_truth(key, default):
		return 'true'
	return 'false'

func evidence_keys():
	var ev_keys = {}
	for key in store.keys():
		if key.ends_with("_name") or key.ends_with("_pic") or key.ends_with("_desc"):
			ev_keys[key.split("_")[0]] = 1
	return ev_keys.keys()

func value_replace(value):
	# Replace from variables if starts with $
	if value.begins_with("$"):
		return self.get_string(value.substr(1))
	return value
