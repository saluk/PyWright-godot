extends ViewportContainer

onready var viewport:Viewport = get_node("Viewport")
onready var main_game_screen:Viewport = get_tree().get_nodes_in_group("MainGameScreen")[0]
export var render_offset:Vector2

func _ready():
	viewport.set_world_2d(main_game_screen.world_2d)
	viewport.canvas_transform.origin -= render_offset

func _gui_input(event):
	if "position" in event:
		event.position += render_offset
	main_game_screen.input(event)
