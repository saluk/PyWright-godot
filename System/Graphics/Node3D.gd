extends WrightObject

var view_container:ViewportContainer
var view_viewport:Viewport
var click_container:ViewportContainer
var click_viewport:Viewport

var screen_w
var screen_h
var render_w
var render_h

var meshes = []

var ready = false

func _init():
	script_name = "surf3d"
	
	
func _ready():
	view_container = get_node("%view_container")
	view_viewport = get_node("%view_viewport")
	click_container = get_node("%click_container")
	click_viewport = get_node("%click_viewport")
	click_container.connect("gui_input", self, "_gui_input")
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
		view_container.rect_size = Vector2(screen_w, screen_h)
		click_container.rect_size = Vector2(screen_w, screen_h)
		view_viewport.size = Vector2(render_w, render_h)
		click_viewport.size = Vector2(render_w, render_h)
	
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed == true and event.button_index == BUTTON_LEFT:
		var click_image = click_viewport.get_texture().get_data()
		click_image.flip_y()
		click_image.save_png("user://image_texture.png")
		var mouse_position = click_container.get_local_mouse_position()
		mouse_position.x /= click_container.rect_size.x/click_viewport.size.x
		mouse_position.y /= click_container.rect_size.y/click_viewport.size.y
		if mouse_position.x < 0 or mouse_position.x > click_viewport.size.x:
			return false
		if mouse_position.y < 0 or mouse_position.y > click_viewport.size.y:
			return false
		click_image.lock()
		var clicked_color = click_image.get_pixelv(mouse_position)
		click_image.unlock()
		var u = clicked_color.r
		var v = clicked_color.g
		print("clicked pos:", mouse_position.x,", ",mouse_position.y)
		print("clicked uv:", u,", ",v)
		# We need a texture... just use first one we found
		# TODO better support for multiple meshes and textures
		for m in meshes:
			for t in m.textures:
				var x = u * t.get_size().x
				var y = v * t.get_size().y
				print("clicked xy:", x, ", ", y)
		return true
	return false


# Copy over all meshes from viewport 1, set their override material


class ClickMesh extends MeshInstance:
	var original_mesh
	var click_uv = preload("res://System/Graphics/click_uv.shader")
	func _init(original_mesh):
		self.original_mesh = original_mesh
		self.mesh = original_mesh.mesh
		self.material_override = ShaderMaterial.new()
		self.material_override.shader = click_uv
		._init()
	func _process(dt):
		transform = original_mesh.transform
	
func _process(dt):
	var copied_meshes = []
	var click_meshes = []
	for child in get_node("%ClickMeshes").get_children():
		if not child.original_mesh in get_node("%Meshes").get_children():
			child.queue_free()
		else:
			copied_meshes.append(child.original_mesh)
			click_meshes.append(child)
	for child in get_node("%Meshes").get_children():
		if not child in copied_meshes:
			copied_meshes = child
			var cm = ClickMesh.new(child)
			click_meshes.append(cm)
			get_node("%ClickMeshes").add_child(cm)
