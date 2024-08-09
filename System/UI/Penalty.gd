# TODO implement damage amount, threat, flash, and timing
extends WrightObject
class_name Penalty

var variable
var threat_amount
var delay

var start_value
var end_value

var left
var right
var good
var bad
var threat_section
var threat_timer = 0.0

signal animation_done

func _ready():
	wait_signal = "animation_done"
	script_name = "penalty"
	var atlas = Filesystem.load_atlas_specific(
		"art/general/healthbar.png",
		[["0","0","3","14"],["82","0","2","14"],
		["3","0","1","14"],["68","0","1","14"]]
	)
	if not atlas:
		queue_free()
		return
	left = PWSprite.new()
	left.from_frame(atlas[0])
	right = PWSprite.new()
	right.from_frame(atlas[1])
	good = PWSprite.new()
	good.from_frame(atlas[2])
	bad = PWSprite.new()
	bad.from_frame(atlas[3])
	add_child(left)
	add_child(right)
	add_child(good)
	add_child(bad)
	
	threat_section = PWSprite.new()
	threat_section.from_frame(atlas[2])
	add_child(threat_section)
	
func begin():
	start_value = clamp(start_value, 0, 100)
	end_value = clamp(end_value, 0, 100)
	if not threat_amount:
		threat_section.visible = false
	
func get_value():
	return stack.variables.get_float(variable, 100)
	
func set_value(value):
	stack.variables.set_val(variable, value)

# TODO get sizes pixel perfect
func _process(dt):
	var value = get_value()
	var ivalue = int(value)
	position = Vector2(256-110+left.width/2, 2+left.height/2)
	right.position = Vector2(101, 0)
	good.position = Vector2(ivalue/2, 0)
	good.scale = Vector2(ivalue+0.1, 1)
	bad.position = Vector2(100-float((100-ivalue))/2.0, 0)
	bad.scale = Vector2((100-ivalue), 1)
	if threat_amount:
		threat_section.position = Vector2(100-threat_amount/2, 0)
		threat_section.scale = Vector2(threat_amount, 1)
		threat_timer += dt*8
		threat_section.material.set_shader_param("to_color_amount", (1.0+(sin(threat_timer)*0.5))/2.0)
	if value != end_value:
		if value < end_value:
			value += min(30*dt, end_value-value)   # TODO - conver to pywright speed
		elif value > end_value:
			value -= min(30*dt, value-end_value)
		else:
			emit_signal("animation_done")
		set_value(value)
		print("set value:", value)
	elif delay>0:
		delay -= WrightScript.one_frame(dt)
		if delay <= 0:
			emit_signal("animation_done")
			queue_free()

# TODO enable saving of penalty
func save_node(data):
	return "nosave"
func load_node(tree, data):
	queue_free()
	return
