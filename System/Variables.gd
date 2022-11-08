extends Reference
class_name Variables

var store = {
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

func keys():
	return store.keys()

func set_val(key, value):
	store[key] = str(value)

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
