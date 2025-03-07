extends ViewportContainer

var main_viewport

# global scale factor
var scale_factor = 2.0

var moving = false
var scaling = false

func transform_rect():
	var pixel_size = get_transform().xform(get_rect()).size * scale_factor
	var gr = get_global_rect()
	return Rect2(gr.position, pixel_size)

func get_cam_offset():
	var vp = get_child(0)
	for child in vp.get_children():
		if child is Camera2D:
			return Vector2(child.position[0]-256/2, child.position[1]-192/2)

func translate_pos(p):
	var r = transform_rect()
	var view_screen_scale = Vector2(r.size.x/256.0, r.size.y/192.0)
	p = ((p - r.position)/view_screen_scale) + get_cam_offset()
	return p

func new_event(ev):
	var ev2
	if ev is InputEventMouseButton:
		ev2 = InputEventMouseButton.new()
		ev2.position = ev.position
		ev2.button_index = ev.button_index
		ev2.button_mask = ev.button_mask
		ev2.factor = ev.factor
		ev2.canceled = ev.canceled
		ev2.pressed = ev.pressed
		ev2.doubleclick = ev.doubleclick
	elif ev is InputEventMouseMotion:
		ev2 = InputEventMouseMotion.new()
		ev2.position = ev.position
		ev2.button_mask = ev.button_mask
		ev2.tilt = ev.tilt
		ev2.pressure = ev.pressure
		ev2.pen_inverted = ev.pen_inverted
		ev2.relative = ev.relative
		ev2.speed = ev.speed
	return ev2

func event_is_mouseup(ev:InputEventMouseButton):
	if not ev:
		return false
	if ev and not ev.pressed:
		return true

func cancel_move(ev=null):
	if not ev or event_is_mouseup(ev):
		moving = false
		scaling = false

func _process(dt):
	if Input.is_action_just_released("pointer_main_button"):
		cancel_move()

func _input(ev):
	cancel_move(ev)
	if moving and ev is InputEventMouseMotion:
		rect_position += ev.relative
		get_tree().set_input_as_handled()
		return
	if scaling and ev is InputEventMouseMotion:
		rect_scale += ev.relative * 0.01
		rect_scale = Vector2(clamp(rect_scale.x, 0.1, 10), clamp(rect_scale.y, 0.1, 10))
		get_tree().set_input_as_handled()
		return
	if ev is InputEventMouseButton or ev is InputEventMouseMotion:
		if event_is_mouseup(ev) or transform_rect().has_point(ev.position):
			cancel_move(ev)
			var ev2 = new_event(ev)
			ev2.position = translate_pos(ev.position)
			main_viewport.input(ev2)



