# A click area that can be attached to a WrightObject to enable it to be:
#  - highlighted
#  - clicked

extends Control
class_name ClickArea

var parent

var over := false
var clicked := false
var enabled := true

var click_macro:String  # Macro to call when button is pressed
var click_args:Array
var select_macro:String  #Macro to call when button is highlighted
var select_args:Array

var select_with_keys:bool = true   #Whether this clickarea can be selected with keys

var debuglabel:Label

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	if get_tree().debug_collisions_hint:
		debuglabel = Label.new()
		add_child(debuglabel)
	set_debug_text()

func _enter_tree():
	parent = get_parent()
	parent.connect("sprite_changed", self, "sync_area")
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")
	connect("gui_input", self, "on_gui_input")
	sync_area()

func set_debug_text():
	if debuglabel:
		debuglabel.text = "o:"+str(over)+" c:"+str(clicked)

func sync_area():
	var current_sprite:PWSprite = parent.current_sprite
	if current_sprite:
		rect_position = current_sprite.position# + Vector2(-current_sprite.width/2, -current_sprite.height/2)
		rect_size = Vector2(current_sprite.width, current_sprite.height)
		# TODO mirror property should be set by the sprite!
		if parent.mirror.x < 0:
			rect_position.x -= current_sprite.width
		if parent.mirror.y < 0:
			rect_position.y -= current_sprite.height
		update()
	# Force object to be in "over" state when it is newly created
	if not over and get_global_rect().has_point(get_global_mouse_position()):
		on_mouse_entered()

func _draw():
	if get_tree().debug_collisions_hint:
		draw_line(Vector2(0,0), Vector2(rect_size.x,0), Color.red, 2.0)
		draw_line(Vector2(rect_size.x,0), Vector2(rect_size.x,rect_size.y), Color.red, 2.0)
		draw_line(Vector2(rect_size.x,rect_size.y), Vector2(0,rect_size.y), Color.red, 2.0)
		draw_line(Vector2(0,rect_size.y), Vector2(0,0), Color.red, 2.0)

func on_mouse_entered():
	if not over:
		over = true
		if select_macro:
			Commands.call_command(select_macro, parent.wrightscript, select_args)
	set_highlight()
	set_debug_text()

func on_mouse_exited():
	over = false
	set_highlight()
	set_debug_text()

func on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			clicked = true
			set_highlight()
		else:
			clicked = false
			set_highlight()
			#if over:
			perform_action()
	set_debug_text()

func perform_action():
	if not enabled:
		return
	# If click_macro is surrounded by {}, call macro
	# Otherwise goto the label
	# In either case, delete any guiWaits
	Commands.emit_signal("button_clicked", self)  # This should signal to guiWaits
	if click_macro.begins_with("{") and click_macro.ends_with("}"):
		Commands.call_command(click_macro, parent.wrightscript, click_args)
	else:
		parent.wrightscript.goto_label(click_macro)


# TODO - allow customize click colors in wrightscript
# TODO - allow change clicked graphic for gui Button

func set_highlight():
	var final_sprite = "default"
	var final_color = Color(1,1,1,1)
	var final_amount = 0.0
	if clicked and enabled:
		if parent.has_sprite("clicked"):
			final_sprite = "clicked"
		else:
			final_color = Color(0,0,1,1)
			final_amount = 0.5
	if over and enabled:
		if parent.has_sprite("highlight"):
			final_sprite = "highlight"
		else:
			final_color = Color(1,1,1,1)
			final_amount = 0.5
	parent.set_sprite(final_sprite)
	if parent.current_sprite:
		parent.current_sprite.set_colorize(final_color, final_amount)

func _process(dt):
	set_highlight()
