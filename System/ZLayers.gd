extends Node

var z_sort = {}
var pri_sort = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var mode = null
	var file = File.new()
	file.open("res://System/sorting.txt", File.READ)
	for line in file.get_as_text().split("\n"):
		line = line.strip_edges()
		if line.begins_with("#") or not line:
			continue
		if line == "[z]":
			mode = z_sort
		elif line == "[pri]":
			mode = pri_sort
		if not mode == null:
			var layer = null
			for obj in line.split(" "):
				if layer==null:
					layer = int(obj)
				elif obj:
					mode[obj] = layer
	file.close()
