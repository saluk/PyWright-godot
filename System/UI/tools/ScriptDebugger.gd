extends Control

var current_stack
var look_at   # Set to a script if we are looking at something other than the current script

var script_tab
var popup_menu

var scripts:Array = []
export(NodePath) var step
export(NodePath) var allev
export(NodePath) var pause
export(NodePath) var speed
export(NodePath) var node_scripts
export(NodePath) var current_script

export(NodePath) var show_watched_panel
export(NodePath) var watched_panel
export(NodePath) var watched_textedit

var stepping_over = -1

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
		speed = get_node(speed)
		show_watched_panel = get_node(show_watched_panel)
		watched_panel = get_node(watched_panel)
		watched_textedit = get_node(watched_textedit)
		node_scripts = get_node(node_scripts)
	
	node_scripts.remove_child(script_tab)
	# TODO conceal buttons if game is not playing to prevent error
	step.connect("button_up", self, "step_over")
	pause.connect("button_up", self, "start_debugger")
	allev.connect("button_up", self, "all_ev")
	speed.connect("button_up", self, "set_speed")
	show_watched_panel.connect("button_up", self, "_show_watched_panel")
	
	goto_line_button_template = get_node("GotoLineButton")
	goto_line_button_template.get_parent().remove_child(goto_line_button_template)

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


func get_script_data(script):
	for script_data in scripts:
		if script_data["script"] == script:
			return script_data
		
func edit_script(script):
	var d = get_script_data(script)
	script.load_string(d["editor"].text)
	script.stack.show_in_debugger()

func goto_line(row, script):
	if current_stack.scripts:
		script.goto_line_number(row)
		current_stack.force_clear_blockers()
	get_script_data(script)["editor"].set_line_as_breakpoint(row, false)
	
func all_ev():
	var found = false
	for var_key in current_stack.variables.evidence_keys():
		Commands.call_command("addev", current_stack.scripts[-1], [var_key])
		found = true
	var p = PopupPanel.new()
	p.rect_scale = Vector2(4,4)
	p.connect("popup_hide", p, "queue_free")
	var l = Label.new()
	if found:
		l.text = "All known evidence added to court record"
	else:
		l.text = "No known evidence found in current game/case"
	p.add_child(l)
	get_parent().add_child(p)
	p.popup_centered()
	
func debug_line(line):
	print("watching line", line)
	if stepping_over >= 0:
		if scripts.size() > stepping_over:
			if current_stack.state == current_stack.STACK_DEBUG:
				current_stack.state = current_stack.STACK_READY
			return
		stepping_over = -1
	debug_last_state = current_stack.state
	current_stack.state = current_stack.STACK_DEBUG
	
func step_over():
	if in_debugger:
		if stepping_over == -1:
			stepping_over = node_scripts.current_tab+1
			current_stack.state = current_stack.STACK_READY
			while scripts.size() > 1:
				yield(get_tree(), "idle_frame")
		
func set_speed():
	if speed.text == ">>>":
		Engine.time_scale = 100.0
		speed.text = ">"
	else:
		Engine.time_scale = 1.0
		speed.text = ">>>"
		
func add_new_script(script):
	var editor_container = script_tab.duplicate()
	var d = {
		"script": script, 
		"editor_container": editor_container,
		"editor": editor_container.get_node("CurrentScriptEditor"),
		"highlighted_line": null,
		"bookmark_line": null}
	d["editor_container"].name = "x"
	d["editor_container"].get_node("HBoxContainer/ScreenLabel").text = script.screen.name
	d["editor_container"].get_node("HBoxContainer/FilenameLabel").text = script.filename
	node_scripts.add_child(d["editor_container"])
	d["editor"].text = PoolStringArray(d["script"].lines).join("\n")
	d["editor"].connect("text_changed", self, "edit_script", [script])
	d["editor"].connect("breakpoint_toggled", self, "goto_line", [script])
	d["editor"].connect("info_clicked", self, "goto_line", [script])
	scripts.append(d)

# TODO: don't rebuild just because a line has advanced
# Actually go through each script and compare if the object needs to be updated
func rebuild():
	# Top script is actually the last item in the script list
	# STEP 1 - delete existing scripts that aren't in the current stack
	var change = false
	for i in range(scripts.size()-1, 0, -1):
		if not scripts[i]["script"] in current_stack.scripts:
			scripts.remove(i)
			node_scripts.remove_child(node_scripts.get_child(i))
			change = true
	# STEP 2 - add scripts in the current stack that aren't in our scripts
	var has_scripts = []
	for d in scripts:
		has_scripts.append(d["script"])
	for script in current_stack.scripts:
		if not script in has_scripts:
			add_new_script(script)
			change = true
	# STEP 3 - make the order between the two lists consistent, including fixing the tab titles
	for i in range(current_stack.scripts.size()):
		if current_stack.scripts[i] == scripts[i]["script"]:
			continue
		change = true
		var script = current_stack.scripts[i]
		var d = get_script_data(script)
		for other_script in scripts:
			if other_script["script"] == script:
				scripts.erase(other_script)
				scripts.insert(i, other_script)
				node_scripts.move_child(other_script["editor_container"], i)
				break
	if scripts and change:
		node_scripts.current_tab = scripts.size()-1
	return

func update_current_stack(stack):
	var main = get_tree().get_nodes_in_group("Main")[0]
	if not Configuration.user.debugger_enabled:
		return
	if current_stack != stack:
		current_stack = stack
		current_stack.connect("enter_debugger", self, "start_debugger", [true])
	rebuild()
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
		scripts[i]["editor_container"].name = str(i)

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


func _show_watched_panel():
	watched_panel.visible = true
func _hide_watched_pane():
	watched_panel.visible = false
func _on_TextEdit_text_changed():
	var main = get_tree().get_nodes_in_group("Main")[0]
	main.stack.watched_commands = []
	for line in watched_textedit.text.split("\n", false):
		main.stack.watched_commands.append(line)
