
extends MeshInstance
class_name PWMesh

signal rotation_done
export var mesh_path:String
var node3d
var click_mesh
var regions = [
]
var region_colors = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
var region_labels = []

var script_name = "mesh"
var wait_signal = null
var scrollable = true

# TODO allow comnfigure these, also they seem weird
var maxz = 0
var minz = -75

# TODO include save properties
var cannot_save := true

func _init(path):
	mesh_path = path
	load_mesh()
	add_to_node3d()

func get_screen():
	return node3d.get_screen()

func load_mesh():
	mesh = ObjParse.load_obj(mesh_path, "")

func add_to_node3d(node3d=null):
	if not node3d:
		var surfs = ScreenManager.get_objects("surf3d", null, Commands.SPRITE_GROUP)
		if surfs:
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

func get_label_for_click(red_value):
	if not click_mesh:
		return null
	return click_mesh.get_clicked_region(red_value)

func add_region(label, plane):
	if regions.size() >= region_colors.size():
		GlobalErrors.log_error("Maximum number of region3ds added already")
		return
	regions.append(plane)
	region_labels.append(label)

func clear_regions():
	regions = []
	region_labels = []

func update_click_regions():
	if not click_mesh:
		return false
	click_mesh.make_click_mesh()
