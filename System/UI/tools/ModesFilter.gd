extends Node2D

onready var debugger = get_parent().get_node("%ScriptDebugger")
onready var debugging = get_node("Debugging")
onready var fastforward = get_node("FastForward")

func _ready():
	pass

func _process(dt):
	debugging.visible = false
	fastforward.visible = false
	if debugger.has_method("in_debugger") and debugger.in_debugger:
		debugging.visible = true
		var offset = 0
		for child in debugging.get_children():
			child.color = Color(0.1,
				0.1,
				sin(0.25*dt/Engine.time_scale*(Time.get_ticks_msec()+offset))*0.4+0.6)
			offset += 0.1
	if Engine.time_scale > 1.0:
		fastforward.visible = true
		var offset = 0.5
		for child in fastforward.get_children():
			child.color = Color(sin(0.25*dt/Engine.time_scale*(Time.get_ticks_msec()+offset))*0.4+0.6,
				sin(0.25*dt/Engine.time_scale*(Time.get_ticks_msec()+offset))*0.4+0.6, 0)
			offset += 0.1
