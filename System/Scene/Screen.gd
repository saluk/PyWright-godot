extends Node2D
class_name Screen

func _ready():
	position = Vector2(0,0)

func _process(dt):
	sort_children()
	
# TODO using a manual, slow sorting algorithm here because godot's sort_custom uses heapsort which is not stable	
func sort_children():
	var children = get_children()
	for i in range(children.size()):
		if i == 0:
			continue
		var child = children[i]
		var nexti = i-1
		var seti = i
		while nexti >= 0:
			if child.z >= children[nexti].z:
				break
			seti = nexti
			nexti -= 1
		if seti != i:
			children.insert(seti, child)
			children.remove(i+1)
	for i in range(children.size()):
		move_child(children[i], i)
		
func clear(top=true, bottom=true):
	for child in get_children():
		if not bottom and child.global_position.y >= 192:
			continue
		if not top and child.global_position.y < 192:
			continue
		# TODO probably unnecesary to remove the child AND free it
		remove_child(child)
		# Forces custom queue_free to be called when we clear
		child.queue_free()

#func sort_children():
#	var children = get_children()
#	children.sort_custom(self, "compare")
#	for i in range(children.size()):
#		move_child(children[i], i)
#
#func compare(a, b):
#	if "z" in a and "z" in b:
#		if a.z < b.z:
#			return true
#	return false
