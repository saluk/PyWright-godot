extends Node2D

func _process(dt):
	sort_children()
	
func sort_children():
	var children = get_children()
	children.sort_custom(self, "compare")
	for i in range(children.size()):
		move_child(children[i], i)
	
func compare(a, b):
	if "z" in a and "z" in b:
		if a.z < b.z:
			return true
	return false
