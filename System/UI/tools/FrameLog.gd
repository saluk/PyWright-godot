extends Control

var MAX_LENGTH = 10102
var enabled = false

func _ready():
	$EnableButton.connect("button_down", self, "enable_disable")
	
func enable_disable():
	enabled = not enabled
	$EnableButton.text = {true: "disable", false: "enable"}[enabled]

# TODO maybe rethink this
func log_frame_end(frame):
	if not enabled:
		return
	var t = "End:\n"
	t += frame.scr.filename + ":" + str(frame.line_num) + "\n"
	t += ">" + frame.line + "\n"
	t += str(Time.get_ticks_msec()) + "\n"
	if frame.sig is int:
		t += "-" + str(frame.sig) + "\n"
	elif "name" in frame.sig:
		t += "o:" + frame.sig.name + "\n"
	elif frame.sig is SceneTreeTimer:
		t += "timer\n"
	t += ">>>\n"
	t = $TextLog.text + t
	t = t.substr(0, MAX_LENGTH)
	$TextLog.text = t

func log_frame_begin():
	if not enabled:
		return
	var t = $TextLog.text
	t += "Begin:<<<" + str(Time.get_ticks_msec()) + "\n"
	t = t.substr(0, MAX_LENGTH)
	$TextLog.text = t
