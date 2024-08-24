extends Node

func variables():
	return get_parent().main.stack.variables


func _ready():
	var bg = variables().get_string("_textbox_bg", null)
	if not bg:
		return
	if bg != "general/textbox_2":
		var PWSpriteC = load("res://System/Graphics/PWSprite.gd")
		var sprite = PWSpriteC.new()
		sprite.name = "PWSprite:"+bg
		sprite.pivot_center = false
		sprite.load_animation("art/"+bg+".png", get_parent().main.stack.scripts[-1].root_path)
		add_child(sprite)
		move_child(sprite, 0)
		get_node("Textbox2").queue_free()
