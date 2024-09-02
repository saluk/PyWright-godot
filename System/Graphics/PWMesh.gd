extends WrightObject
class_name PWMesh

signal rotation_done
var mesh_path:String
var mesh_instance:MeshInstance
var node3d

func _init(path):
	mesh_path = path
	load_mesh()
	add_to_node3d()
	
func get_screen():
	return node3d.get_screen()

func load_mesh():
	if mesh_instance:
		mesh_instance.free()
	mesh_instance = MeshInstance.new()
	mesh_instance.mesh = ObjParse.load_obj(mesh_path, "")
	mesh_instance.scale = Vector3(1,1,1)
	add_child(mesh_instance)

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
		mesh_instance.rotation_degrees.x += degrees
	if axis == "y":
		mesh_instance.rotation_degrees.y += degrees
	if axis == "z":
		mesh_instance.rotation_degrees.z += degrees
	emit_signal("rotation_done")
