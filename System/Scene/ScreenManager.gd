extends Node

var screens:Node
var main_screen:Node2D setget , get_main_screen
var _main_screen:Node2D

func _init_screens():
	screens = get_tree().get_nodes_in_group("Screens")[0]
	_main_screen = screens.get_node("%MainScreen")

func _ready():
	_init_screens()
	get_tree().connect("tree_changed", self, "_on_tree_changed")

func top_screen():
	var children = screens.get_children()
	var child
	for i in range(children.size()):
		child = children[children.size()-i-1]
		if child is Screen:
			return child

func get_main_screen():
	# If main screen is gone, we should get our handles again
	if _main_screen and is_instance_valid(_main_screen):
		return _main_screen
	if not is_instance_valid(screens):
		return null
	if not screens.get_children():
		return null
	_main_screen = screens.get_node("%MainScreen")
	return _main_screen

func get_screens():
	var screen_array = []
	for screen in screens.get_children():
		if screen is Screen:
			screen_array.append(screen)
	return screen_array

func get_objects(script_name=null, last=null, group=null):
	var objects = []
	var screens = get_screens()
	for i in range(screens.size()):
		for object in screens[-i].get_objects(script_name, last, group):
			objects.append(object)
	return objects

func delete_objects(script_name=null, last=null, group=null):
	for screen in get_screens():
		screen.delete_objects(script_name, last, group)

func _on_tree_changed():
	if not is_instance_valid(_main_screen):
		_init_screens()

func add_screen(name="Screen"):
	var screen = Screen.new()
	screen.name = name
	screens.add_child(screen)
	return screen

func get_screen(name):
	for screen in get_screens():
		if screen.name == name:
			if name == "MainScreen":
				pass
			return screen
		# for save/load - when a node wasn't named correctly it gets @ added in its name
		# you can't add a node explicitly with @ in the nane. so do fuzzy matching here
		if screen.name.replace("@","") == name.replace("@",""):
			return screen
	return null

func has_screen(name):
	if get_screen(name) != null:
		return true
	return false

func get_or_create(screen_name):
	var screen = get_screen(screen_name)
	if not screen:
		screen = add_screen(screen_name)
	return screen

func clear():
	for screen in screens.get_children():
		if screen is Screen:
			screen.clear()

# Only keep the main screen, and any screens tied to a current script
func clean(scripts):
	var active_screens = [main_screen]
	for script in scripts:
		if not script.screen in active_screens:
			active_screens.append(script.screen)
	for screen in screens.get_children():
		if not screen is Screen:
			continue
		if screen == _main_screen:
			continue
		if not screen in active_screens:
			screen.queue_free()
