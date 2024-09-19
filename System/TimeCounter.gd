extends Node
class_name TimeCounter

var elapsed_time := 0.0

func _ready():
	reset()
	Pauseable.new(self)

func reset():
	elapsed_time = 0.0

func get_current_elapsed_time():
	return elapsed_time

func set_elapsed_time(seconds):
	elapsed_time = seconds

func get_string():
	var sec = elapsed_time
	var minutes = int(sec / 60)
	sec = sec - (minutes * 60)
	var hours = int(minutes / 60)
	minutes = minutes - (hours * 60)
	return "%02d:%02d:%02d" % [hours, minutes, sec]

func _process(dt):
	elapsed_time += dt
