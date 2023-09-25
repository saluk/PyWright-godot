extends Reference
class_name TimeCounter

var ticks_offset:int

func _ready():
	reset()
	
func reset():
	ticks_offset = Time.get_ticks_msec()

func get_string():
	var msec = Time.get_ticks_msec() - ticks_offset
	var sec = int(msec / 1000)
	msec = msec - (sec * 1000)
	var minutes = int(sec / 60)
	sec = sec - (minutes * 60)
	var hours = int(minutes / 60)
	minutes = minutes - (hours * 60)
	return str(hours) + ":" + str(minutes) + ":" + str(sec) + ":" + str(msec)
