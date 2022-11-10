extends Control

var MAX_LENGTH = 10102

func _ready():
	pass

# TODO maybe rethink this
func add_frame(frame):
	return
	var t = ""
	t += frame.scr.filename + ":" + str(frame.line_num) + "\n"
	t += ">" + frame.line + "\n"
	if frame.sig is int:
		t += "-" + str(frame.sig) + "\n"
	elif "name" in frame.sig:
		t += "o:" + frame.sig.name + "\n"
	elif frame.sig is SceneTreeTimer:
		t += "timer"
	t += "\n"
	t = t + $TextLog.text
	t = t.substr(0, MAX_LENGTH)
	$TextLog.text = t
