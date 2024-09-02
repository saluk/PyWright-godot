extends WrightObject

func _init():
	script_name = "surf3d"

func add_mesh(mesh_ob):
	mesh_ob.node3d = self
	get_node("%Viewport").add_child(mesh_ob)

func get_meshes():
	var ar = []
	for mesh in get_node("%Viewport").get_children():
		if mesh is PWMesh:
			ar.append(mesh)
	return ar

func get_screen():
	return get_parent()
