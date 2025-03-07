extends Control
var scale_factor = 2.0

export var prop := "moving"

func transform_rect():
	var pixel_size = get_transform().xform(get_rect()).size * scale_factor
	var gr = get_global_rect()
	return Rect2(gr.position, pixel_size)

func _input(ev):
	if ev is InputEventMouseButton:
		if transform_rect().has_point(ev.position):
			if ev.pressed:
				get_parent().set(prop, true)
