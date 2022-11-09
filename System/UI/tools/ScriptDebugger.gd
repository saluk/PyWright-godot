extends Control

var current_script
var current_stack
var look_at   # Set to a script if we are looking at something other than the current script

var script_tab
var popup_menu

var scripts = []

var in_debugger = false
var debug_last_state = null

# {"script": WrightScript, "editor": TextEdit, "highlighted_line":int, "bookmark_line": int}

func _ready():
	script_tab = get_node("Scripts/CurrentScript")
	$Scripts.remove_child(script_tab)
	$Step.connect("button_up", self, "step")
	$Pause.connect("button_up", self, "start_debugger")
	
func start_debugger():
	if in_debugger:
		in_debugger = false
		$Pause.text = "Pause"
		current_stack.disconnect("line_executed", self, "debug_line")
	else:
		in_debugger = true
		$Pause.text = "Resume"
		current_stack.connect("line_executed", self, "debug_line")
	
func debug_line(line):
	print("watching line", line)
	debug_last_state = current_stack.state
	current_stack.state = current_stack.STACK_DEBUG
	
func step():
	if in_debugger and debug_last_state:
		current_stack.state = debug_last_state
		debug_last_state = null
	
func change_script(script:WrightScript):
	if script != current_script:
		current_script = script
		$CurrentScript.text = PoolStringArray(script.lines).join("\n")
		
func rebuild():
	for child in $Scripts.get_children():
		$Scripts.remove_child(child)
	scripts = []
	var i = 0
	for script in current_stack.scripts:
		var d = {
			"script": script, 
			"editor": script_tab.duplicate(),
			"highlighted_line": null,
			"bookmark_line": null}
		d["editor"].name = "x"
		$Scripts.add_child(d["editor"])
		$Scripts.set_tab_title(i, script.filename)
		d["editor"].text = PoolStringArray(d["script"].lines).join("\n")
		scripts.append(d)
		i += 1

func update_current_stack(stack):
	current_stack = stack
	# Detect if scripts changed
	if len(scripts) != len(stack.scripts):
		rebuild()
	for i in range(len(scripts)):
		if scripts[i]["script"] != stack.scripts[i]:
			rebuild()
			$Scripts.current_tab = len(scripts)
			break
	# Update each editor
	for i in range(len(scripts)):
		var to_line = scripts[i]["script"].line_num
		var at_line = scripts[i]["editor"].cursor_get_line()
		if scripts[i]["highlighted_line"] != to_line:
			scripts[i]["highlighted_line"] = to_line
			scripts[i]["editor"].cursor_set_line(to_line)
		if scripts[i]["bookmark_line"]!=null and scripts[i]["editor"].is_line_set_as_bookmark(scripts[i]["bookmark_line"]):
			scripts[i]["editor"].set_line_as_bookmark(scripts[i]["bookmark_line"], false)
		scripts[i]["editor"].set_line_as_bookmark(to_line, true)
		scripts[i]["bookmark_line"] = to_line
