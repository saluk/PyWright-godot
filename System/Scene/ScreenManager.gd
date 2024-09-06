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
	
func _on_tree_changed():
	if not is_instance_valid(_main_screen):
		_init_screens()

func add_screen(name="Screen"):
	var screen = Screen.new()
	screens.add_child(screen)
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
