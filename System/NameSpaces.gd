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
	"ev_small_width": "40",
	"ev_small_height": "40",
	"ev_big_width": "70",
	"ev_big_height": "70",
	"ev_modebutton_x": "196",
	"ev_modebutton_y": "7",
	"ev_z_bg": "general/evidence_zoom",
	"ev_z_bg_x": "0",
	"ev_z_bg_y": "0",
	"ev_z_icon_x": "25",
	"ev_z_icon_y": "60",
	"ev_z_textbox_x": "100",
	"ev_z_textbox_y": "70",
	"ev_z_textbox_w": "130",
	"ev_z_textbox_h": "100",
	"ev_z_text_col": "999",
	"ev_check_img": "general/check",
	"ev_arrow_button_img": "general/evidence_arrow_right",
	"textblock_line_height": "-1",
	"_ev_pages": "evidence profiles",
	"_list_back_button": "true"
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

class NOT_FOUND:
	pass

class Accessor:
	var key:String
	var namespace:Variables
	var namespaces:NameSpaces
	var access_item = null
	func _init(key, namespace, namespaces):
		self.key = key
		self.namespace = namespace
		self.namespaces = namespaces

		var listpart = ""
		if ":" in key:
			var parts = Array(key.split(":"))
			self.key = parts[0]
			# further expansion
			if parts[1].begins_with("$"):
				parts[1] = namespaces.get_accessor(parts[1].substr(1)).get_val("string", "0")
			if parts[1].is_valid_integer():
				access_item = int(parts[1])
			elif parts[1] == "end":
				access_item = list().size()
			elif parts[1] == "length":
				access_item = parts[1]
			else:
				print("invalid access item")
				assert(false)
	# make the namespace able to act as a list
	func list():
		if not key in namespace.store:
			namespace.store[key] = []
		if not namespace.store[key] is Array:
			return []
		return namespace.store[key]
	func get_val(type="string", default=null):
		var val = namespace.get_val(key, NOT_FOUND.new())
		if access_item != null:
			if not val is Array:
				print("cant access from non-array")
				return ""
			if access_item is int:
				if access_item < 0:
					print("can't access <0")
					val = ""
				elif access_item >= val.size():
					print("can't access > size")
					val = ""
				else:
					val = val[access_item]
			elif access_item == "length":
				val = str(val.size())
			else:
				print("invalid access item")
				val = ""
		if val is NOT_FOUND:
			return default
		match type:
			"string":
				val = Values.to_str(val)
			"int":
				val = Values.to_int(val)
			"float":
				val = Values.to_float(val)
			"num":
				val = Values.to_num(val)
			"truth":
				val = Values.to_truth(val)
			"truth_string":
				val = Values.to_truth_string(val)
			_:
				GlobalErrors.log_error("Cannot convert variable of type "+type)
		if val==null:
			return default
		return val
	func set_val(value):
		if access_item is int:
			if access_item < 0:
				print("can't access <0")
				return
			elif access_item >= list().size():
				while access_item >= list().size():
					list().append("")
			list()[access_item] = value
		elif access_item!=null:
			print("invalid access item")
		else:
			if value is Variables:
				namespace.store[key] = value
			else:
				namespace.set_val(key, value)
	func del_val():
		if access_item is int:
			if access_item < 0:
				print("can't access <0")
				return
			elif access_item >= list().size():
				print("can't access > size")
				return
			list().remove(access_item)
		elif access_item == "length":
			pass
		else:
			namespace.del_val(key)
	func exists():
		return namespace.store.has(key)
	func is_namespace():
		return get_val() is Variables

# Lookup a variable
# [object_script_name].x <- lookup in object
# [object_script_name]-2.x <- lookup in second object with that name
# game.y <- lookup in game
# script.z <- lookup in current script or previous scripts
# x <- lookup in global
# [object_name].x.y <- create or access namespace in object_name called x, retrieve y
# something:2 <- make something an array, get item at index 2
# set something.end <- add item to the end of array
func get_accessor(variable:String, namespace:Variables=null, setting=false):
	var script = main.top_script()
	var next = variable

	if "." in variable:
		var parts = Array(variable.split("."))
		next = parts.pop_front()
		variable = ".".join(parts)
	else:
		variable = ""

	# Expand variables further
	if next.begins_with("$"):
		next = get_accessor(next.substr(1), null, setting).get_val("string", "")

	if not namespace and next and variable:
		if next == "script":
			if not script:
				return get_accessor(variable, Variables.new(), setting)
			return get_accessor(variable, script.variables, setting)
		if next == "game":
			return get_accessor(variable, game_namespace, setting)
		# See if next is an object
		for object in ScreenManager.get_objects(next):
			return get_accessor(variable, object.variables, setting)

	if not namespace:
		namespace = global_namespace

	var accessor = Accessor.new(next, namespace, self)

	# We are at the end of the line, let caller figure out what to do with the address
	if not variable:
		return accessor

	if accessor.exists():
		if accessor.is_namespace():
			return get_accessor(variable, accessor.get_val(), setting)
		# We are trying to access values in an accessor that's not a namespace
		print("Error, "+next+" has a value and is not a namespace")
		print(accessor.get_val())
	if setting:
		print("creating new namespace "+accessor.key)
		accessor.set_val(Variables.new())
	else:
		print("creating temp namespace "+accessor.key)
		accessor.namespace = Variables.new()
	return get_accessor(variable, accessor.get_val(), setting)


# Passthrough functions to namespace

func set_val(key, value, split_on=null):
	var a = get_accessor(key, null, true)
	if split_on != null:
		value = Variables.array_to_string(value, split_on)
	return a.set_val(value)

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

# Keep the default a string here
func get_array(key, default="", split_on=","):
	var val = get_accessor(key).get_val("string", default)
	return Variables.string_to_array(val, split_on)


# SAVE/LOAD
var save_properties = [
]
func save_node(data):
	data["global_namespace"] = SaveState._save_node(global_namespace)
	data["game_namespace"] = SaveState._save_node(game_namespace)

static func create_node(saved_data:Dictionary):
	pass # Not called

func load_node(tree, saved_data:Dictionary):
	SaveState._load_node(tree, global_namespace, saved_data["global_namespace"])
	SaveState._load_node(tree, game_namespace, saved_data["game_namespace"])

func after_load(tree:SceneTree, saved_data:Dictionary):
	pass # Not called
