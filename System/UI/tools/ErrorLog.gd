extends Control

export var textlog_path: NodePath
onready var textlog:TextEdit = get_node(textlog_path)

# Context: {
#   script_path, script_line: the path and line number of a script
#	script: a script object
#   frame: a command frame
#}

func log_error(msg, context={}):
	var start = " \nvvvvvvvvvvvvvvvvvvvvvv\n    "
	var end = ""
	if "script_path" in context:
		start = " > " + context["script"] + start
	if "script_path" in context and "script_line" in context:
		start = " > " + context["script"] + ":" + str(context["script_line"]) + start
	if "script" in context:
		context["frame"] = context["script"].get_frame(null)
	if "frame" in context:
		var frame = context["frame"]
		start = " > " + frame.scr.fullpath() + ":" + str(frame.line_num) + start
	var t = textlog.text + "\n\n" + start + msg + end
	textlog.text = t
	scroll()
	print(" error logged: " + msg)

func log_info(msg, context={}):
	var start = " \n --- "
	var end = ""
	var t = textlog.text + "\n\n" + start + msg + end
	textlog.text = t
	scroll()
	print(" error logged: " + msg)
	
func scroll():
	textlog.cursor_set_line(textlog.get_line_count())
	textlog.cursor_set_column(0)
	textlog.center_viewport_to_cursor()


