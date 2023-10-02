extends Control

var current_stack
var look_at   # Set to a script if we are looking at something other than the current script

var script_tab
var popup_menu

var scripts = []
export(NodePath) var reload_button
export(NodePath) var disable_button
export(NodePath) var step
export(NodePath) var allev
export(NodePath) var pause
export(NodePath) var node_scripts
export(NodePath) var current_script

var in_debugger = false
var debug_last_state = null

var goto_line_button_template:Button

# {"script": WrightScript, "editor": TextEdit, "highlighted_line":int, "bookmark_line": int}

func _ready():
	if step is NodePath:
		script_tab = get_node(current_script)
		step = get_node(step)
		allev = get_node(allev)
		pause = get_node(pause)
		node_scripts = get_node(node_scripts)
		reload_button = get_node(reload_button)
		disable_button = get_node(disable_button)
	
	node_scripts.remove_child(script_tab)
	# TODO conceal buttons if game is not playing to prevent error
	step.connect("button_up", self, "step")
	pause.connect("button_up", self, "start_debugger")
	allev.connect("button_up", self, "all_ev")
	reload_button.connect("button_up", self, "reload")
	disable_button.connect("button_up", self, "toggle_enabled")
	
	goto_line_button_template = get_node("GotoLineButton")
	goto_line_button_template.get_parent().remove_child(goto_line_button_template)

# TODO maybe this should be a "main" function
func reload():
	if current_stack:
		current_stack.clear_scripts()
		current_stack.blockers = []
	MusicPlayer.stop_music()
	SoundPlayer.stop_sounds()
	get_tree().change_scene("res://Main.tscn")
	
func toggle_enabled():
	var main = get_tree().get_nodes_in_group("Main")[0]
	main.debugger_enabled = not main.debugger_enabled
	disable_button.text = {true: "Disable", false: "Enable"}[main.debugger_enabled]
	
func start_debugger(force=false):
	if in_debugger:
		if force == false:
			in_debugger = false
			pause.text = "Pause"
			current_stack.disconnect("line_executed", self, "debug_line")
			current_stack.state = current_stack.STACK_READY
	else:
		in_debugger = true
		pause.text = "Resume"
		current_stack.connect("line_executed", self, "debug_line")
		current_stack.state = current_stack.STACK_DEBUG
		
func goto_line(row, scripti):
	if current_stack.scripts:
		current_stack.scripts[scripti].goto_line_number(row)
		current_stack.force_clear_blockers()
	scripts[scripti]["editor"].set_line_as_breakpoint(row, false)
	
func all_ev():
	for var_key in current_stack.variables.evidence_keys():
		Commands.call_command("addev", current_stack.scripts[-1], [var_key])
	
func debug_line(line):
	print("watching line", line)
	debug_last_state = current_stack.state
	current_stack.state = current_stack.STACK_DEBUG
	
func step():
	if in_debugger:
		current_stack.state = current_stack.STACK_READY
		
func rebuild():
	for child in node_scripts.get_children():
		node_scripts.remove_child(child)
		child.queue_free()
	scripts = []
	var i = 0
	for ii in range(len(current_stack.scripts)):
		var script = current_stack.scripts[current_stack.scripts.size()-1-ii]
		var d = {
			"script": script, 
			"editor": script_tab.duplicate(),
			"highlighted_line": null,
			"bookmark_line": null}
		d["editor"].name = "x"
		node_scripts.add_child(d["editor"])
		node_scripts.set_tab_title(i, script.filename)
		d["editor"].text = PoolStringArray(d["script"].lines).join("\n")
		d["editor"].connect("text_changed", self, "edit_script", [i])
		d["editor"].connect("breakpoint_toggled", self, "goto_line", [i])
		d["editor"].connect("info_clicked", self, "goto_line", [i])
		scripts.append(d)
		i += 1
	while scripts.size() > current_stack.scripts.size():
		var last = scripts.pop_back()
		node_scripts.remove_child(last["editor"])
		last["editor"].queue_free()
	if scripts:
		node_scripts.current_tab = 0
	
func edit_script(script_index):
	var d = scripts[script_index]
	d["script"].load_string(d["editor"].text)
	d["script"].stack.show_in_debugger()

func update_current_stack(stack):
	var main = get_tree().get_nodes_in_group("Main")[0]
	if not main.debugger_enabled:
		return
	if current_stack != stack:
		current_stack = stack
		current_stack.connect("enter_debugger", self, "start_debugger", [true])
	# Detect if scripts changed
	if len(scripts) != len(stack.scripts):
		rebuild()
	else:
		for i in range(len(scripts)):
			if scripts[i]["script"] != stack.scripts[stack.scripts.size()-1-i]:
				rebuild()
				break
	# Update each editor
	for i in range(len(scripts)):
		var to_line = scripts[i]["script"].line_num
		var at_line = scripts[i]["editor"].cursor_get_line()
		if to_line >= scripts[i]["editor"].get_line_count():
			to_line = at_line
		if scripts[i]["highlighted_line"] != to_line:
			scripts[i]["highlighted_line"] = to_line
			scripts[i]["editor"].cursor_set_line(to_line)
			scripts[i]["editor"].cursor_set_column(0)
			scripts[i]["editor"].center_viewport_to_cursor()
		if scripts[i]["bookmark_line"]!=null and scripts[i]["editor"].is_line_set_as_bookmark(scripts[i]["bookmark_line"]):
			scripts[i]["editor"].set_line_as_bookmark(scripts[i]["bookmark_line"], false)
		scripts[i]["editor"].set_line_as_bookmark(to_line, true)
		scripts[i]["bookmark_line"] = to_line


# TODO Whoops, I'm hooking up an event to control rather than to the script editor
var COPY = 0
func _input(evt:InputEvent):
	if evt is InputEventMouseButton:
		if evt.button_index == 2:
			var popup_menu = PopupMenu.new()
			popup_menu.add_item("Copy", COPY)
			popup_menu.connect("id_pressed", self, "menu_id_pressed")
			
func menu_id_pressed(id):
	if id == COPY:
		pass
