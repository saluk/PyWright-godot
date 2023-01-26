extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var t = Testing.new()
	print("running assertion")
	t.run_assert("""
	print("Hello")
	assert_int(1.5)""")
	print("ran assertion")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
