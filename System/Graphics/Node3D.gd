extends WrightObject

var view_container:SubViewportContainer
var view_viewport:SubViewport
var click_container:SubViewportContainer
var click_viewport:SubViewport

var screen_w
var screen_h
var render_w
var render_h

var meshes = []

var ready = false

func _init():
	script_name = "surf3d"
	z = ZLayers.z_sort["surf3d"]


func _ready():
	view_container = get_node("%view_container")
	view_viewport = get_node("%view_viewport")
	click_container = get_node("%click_container")
	click_viewport = get_node("%click_viewport")
	click_container.connect("gui_input", Callable(self, "_gui_input"))
	ready = true
	set_size()

func add_mesh(mesh_ob):
	mesh_ob.node3d = self
	meshes.append(mesh_ob)
	get_node("%Meshes").add_child(mesh_ob)

func get_meshes():
	var ar = []
	for mesh in get_node("%Meshes").get_children():
		if mesh is PWMesh:
			ar.append(mesh)
	return ar

func get_screen():
	return get_parent()

func set_size(size_args=[]):
	if size_args:
		screen_w = size_args[0]
		screen_h = size_args[1]
		render_w = size_args[2]
		render_h = size_args[3]
	if not ready:
		return
	if screen_w:
		view_container.size = Vector2(screen_w, screen_h)
		click_container.size = Vector2(screen_w, screen_h)
		view_viewport.size = Vector2(render_w, render_h)
		click_viewport.size = Vector2(render_w, render_h)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_pressed == true and event.button_index == MOUSE_BUTTON_LEFT:
		var click_image = click_viewport.get_texture().get_data()
		click_image.flip_y()
		click_image.save_png("user://image_texture.png")
		var mouse_position = click_container.get_local_mouse_position()
		mouse_position.x /= click_container.size.x/click_viewport.size.x
		mouse_position.y /= click_container.size.y/click_viewport.size.y
		if mouse_position.x < 0 or mouse_position.x > click_viewport.size.x:
			return false
		if mouse_position.y < 0 or mouse_position.y > click_viewport.size.y:
			return false
		false # click_image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
		var clicked_color = click_image.get_pixelv(mouse_position)
		false # click_image.unlock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
		print("clicked color:", clicked_color)
		var u = clicked_color.r
		var v = clicked_color.g
		for mesh in get_node("%Meshes").get_children():
			var jump_label = mesh.get_label_for_click(u)
			if jump_label:
				Commands.call_command("goto", wrightscript, [jump_label])
				return true
	return false


# Copy over all meshes from viewport 1, set their override material

func _process(dt):
	var copied_meshes = []
	var click_meshes = []
	for child in get_node("%ClickMeshes").get_children():
		if not child.original_mesh in get_node("%Meshes").get_children():
			child.queue_free()
		else:
			copied_meshes.append(child.original_mesh)
			click_meshes.append(child)
			child.position = child.original_mesh.position
			child.rotation_degrees = child.original_mesh.rotation_degrees
	for child in get_node("%Meshes").get_children():
		if not child in copied_meshes:
			copied_meshes = child
			var cm = ClickMesh.new(child)
			cm.make_click_mesh()
			click_meshes.append(cm)
			get_node("%ClickMeshes").add_child(cm)
