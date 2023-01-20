# Replaces main.variables with main.namespaces
# Can ask for a variable like in Variables, will return out of the global namespace
# Can ask for a variable from a given namespace, will access the variable from that variable set
# Can pass a name the includes dots (.) and the namespace will handle the logic of finding
#    or creating the given namespace

extends Reference
class_name NameSpaces

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

var global_namespace:Variables
# The default namespace like PyWright used for everything
var game_namespace:Variables
# A special namespace which saves it's variables to a file and loads them
# again when the game loads

# Other namespaces:
# each WrightObject has a namespace
# each WrightScript has a namespace

var main

func _init():
	global_namespace = Variables.new()
	game_namespace = Variables.new()
	
func reset():
	global_namespace = Variables.new()
	game_namespace = Variables.new()
	for k in DEFAULTS.keys():
		global_namespace.store[k] = DEFAULTS[k]
	
func init_game_namespace(game_file):
	pass
	# TODO load game file and populate the game_namespace
	# Attach a signal to save the file when variables are written to
	
class Accessor:
	var key
	var namespace
	func _init(key, namespace):
		self.key = key
		self.namespace = namespace
	func get_val(type, default):
		match type:
			"string":
				return namespace.get_string(key, default)
			"int":
				return namespace.get_int(key, default)
			"float":
				return namespace.get_float(key, default)
			"num":
				return namespace.get_num(key, default)
			"truth":
				return namespace.get_truth(key, default)
			"truth_string":
				return namespace.get_truth_string(key, default)
	func set_val(value):
		return namespace.set_val(key, value)
	func del_val():
		namespace.del_val(key)

# Lookup a variable
# [object_script_name].x <- lookup in object
# [object_script_name]-2.x <- lookup in second object with that name
# game.y <- lookup in game
# script.z <- lookup in current script or previous scripts
# x <- lookup in global
# [object_name].x.y <- create or access namespace in object_name called x, retrieve y
func get_accessor(variable:String, namespace:Variables=null, setting=false):
	var script = main.top_script()
	if not "." in variable:
		if namespace:
			return Accessor.new(variable, namespace)
		return Accessor.new(variable, global_namespace)
	var parts = Array(variable.split("."))
	var next = parts.pop_front()
	variable = ".".join(parts)
	# First accessor can choose to access one of the special namespaces
	if not namespace:
		if next == "script":
			return get_accessor(variable, script.variables, setting)
		if next == "game":
			return get_accessor(variable, game_namespace, setting)
		# See if next is an object
		for object in Commands.get_objects(next):
			return get_accessor(variable, object, setting)
		namespace = global_namespace
	# Further accessors are trying to access a namespace before accessing the final variable
	if namespace.store.has(next):
		if namespace.store[next] is Variables:
			return get_accessor(variable, namespace.store[next], setting)
	var new_store = Variables.new()
	if setting:
		namespace.store[next] = new_store
	return get_accessor(variable, new_store, setting)


# Passthrough functions to namespace

func set_val(key, value):
	return get_accessor(key, null, true).set_val(value)
	
func del_val(key):
	return get_accessor(key, null, true).del_val()

func get_string(key, default=""):
	return get_accessor(key).get_val("string", default)

func get_int(key, default=0):
	return get_accessor(key).get_val("int", default)
	
func get_float(key, default=0.0):
	return get_accessor(key).get_val("float", default)
	
func get_num(key, default=0.0):
	return get_accessor(key).get_val("num", default)

func get_truth(key, default="false"):
	return get_accessor(key).get_val("truth", default)

func get_truth_string(key, default="false"):
	return get_accessor(key).get_val("truth_string", default)

func evidence_keys():
	var ev_keys = {}
	for key in global_namespace.keys():
		if key.ends_with("_name") or key.ends_with("_pic") or key.ends_with("_desc"):
			ev_keys[key.split("_")[0]] = 1
	return ev_keys.keys()
