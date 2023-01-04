# A click area that can be attached to a WrightObject to enable it to be:
#  - highlighted
#  - clicked

extends Control
class_name ClickArea

var parent

var over := false
var clicked := false

var macroname:String  # Macro to call when button is pressed

func _enter_tree():
	parent = get_parent()
	parent.connect("sprite_changed", self, "sync_area")
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")
	connect("gui_input", self, "on_gui_input")
	sync_area()
	
func sync_area():
	var current_sprite:PWSprite = parent.current_sprite
	if current_sprite:
		rect_position = current_sprite.position# + Vector2(-current_sprite.width/2, -current_sprite.height/2)
		rect_size = Vector2(current_sprite.width, current_sprite.height)
		update()

func _draw():
	if get_tree().debug_collisions_hint:
		draw_line(Vector2(0,0), Vector2(rect_size.x,0), Color.red, 2.0)
		draw_line(Vector2(rect_size.x,0), Vector2(rect_size.x,rect_size.y), Color.red, 2.0)
		draw_line(Vector2(rect_size.x,rect_size.y), Vector2(0,rect_size.y), Color.red, 2.0)
		draw_line(Vector2(0,rect_size.y), Vector2(0,0), Color.red, 2.0)

func on_mouse_entered():
	over = true
	set_highlight()
	
func on_mouse_exited():
	over = false
	set_highlight()
	
func on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			clicked = true
			set_highlight()
		else:
			clicked = false
			set_highlight()
			Commands.call_macro(macroname, parent.wrightscript, [])

# TODO - allow customize click colors in wrightscript
# TODO - allow change clicked graphic for gui Button

func set_highlight():
	var final_sprite = "default"
	var final_color = Vector3(1,1,1)
	var final_amount = 0.0
	if clicked:
		if parent.has_sprite("clicked"):
			final_sprite = "clicked"
		else:
			final_color = Vector3(0,0,1)
			final_amount = 0.5
	if over:
		if parent.has_sprite("highlight"):
			final_sprite = "highlight"
		else:
			final_color = Vector3(1,1,1)
			final_amount = 0.5
	parent.set_sprite(final_sprite)
	parent.current_sprite.set_colorize(final_color, final_amount)
