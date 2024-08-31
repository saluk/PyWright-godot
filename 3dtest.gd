extends Node2D


func _ready():
	var mesh = ObjParse.load_obj("res://not_imported_models/gem.obj", "res://not_imported_models/gem.mtl")
	$MeshInstance2D.mesh = mesh
	get_node("%MeshInstance").mesh = mesh
