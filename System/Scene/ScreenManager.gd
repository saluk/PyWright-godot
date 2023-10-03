extends Node

var screens:Node
var main_screen:Control

func _ready():
	screens = get_tree().get_nodes_in_group("Screens")[0]
	main_screen = screens.get_children()[0]
	
func top_screen():
	return screens.get_children()[-1]

func add_screen(name="Screen"):
	var screen = Screen.new()
	screens.add_child(screen)
	return screen

func clear():
	for screen in screens.get_children():
		screen.clear()

# Only keep the main screen, and any screens tied to a current script
func clean(scripts):
	var active_screens = [main_screen]
	for script in scripts:
		if not script.screen in active_screens:
			active_screens.append(script.screen)
	for screen in screens.get_children():
		if not screen in active_screens:
			screen.queue_free()
