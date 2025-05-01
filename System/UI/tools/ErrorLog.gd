extends Control

@export var textlog_path: NodePath
@onready var nodes := NodeUtil.create_node_dictionary(self)

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
	var t = nodes[textlog_path].text + "\n\n" + start + msg + end
	nodes[textlog_path].text = t
	scroll()
	print(" error logged: " + msg)

func log_info(msg, _context={}):
	var start = " \n --- "
	var end = ""
	var t = nodes[textlog_path].text + "\n\n" + start + msg + end
	nodes[textlog_path].text = t
	scroll()
	print(" error logged: " + msg)

func scroll():
	nodes[textlog_path].set_caret_line(nodes[textlog_path].get_line_count())
	nodes[textlog_path].set_caret_column(0)
	nodes[textlog_path].center_viewport_to_caret()
