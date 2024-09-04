
extends MeshInstance
class_name PWMesh

signal rotation_done
var mesh_path:String
var script_name = "mesh"
var node3d

var wait_signal = null
var scrollable = true

# TODO include save properties
var cannot_save := true

var textures = []

func _init(path):
	mesh_path = path
	load_mesh()
	add_to_node3d()
	
func get_screen():
	return node3d.get_screen()

func load_mesh():
	mesh = ObjParse.load_obj(mesh_path, "")
	scale = Vector3(1,1,1)
	for surf in range(mesh.get_surface_count()):
		var mat:Material = mesh.surface_get_material(surf)
		if mat.albedo_texture and not mat.albedo_texture in textures:
			textures.append(mat.albedo_texture)

func add_to_node3d(node3d=null):
	if not node3d:
		for screen in ScreenManager.get_screens():
			var surfs = Commands.get_objects("surf3d", null, Commands.SPRITE_GROUP, screen)
			if not surfs:
				continue
			node3d = surfs[0]
	if not node3d:
		GlobalErrors.log_error("No surface found for mesh to be put on")
		return
	node3d.add_mesh(self)

func do_rotate(axis="z", degrees=0, speed=1, nowait=false):
	if not nowait:
		wait_signal = "rotation_done"
	if axis == "x":
		rotation_degrees.x += degrees
	if axis == "y":
		rotation_degrees.y += degrees
	if axis == "z":
		rotation_degrees.z += degrees
	emit_signal("rotation_done")
