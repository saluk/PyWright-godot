extends Control

var main

func _ready():
	main = get_tree().get_nodes_in_group("Main")[0]
	$vbox/MainMenu.connect("button_up", self, "_main_menu")
	$vbox/Debugger.connect("button_up", self, "_debugger")
	$vbox/Framelog.connect("button_up", self, "_framelog")
	
func _main_menu():
	main.reload()

func toggle_tab(tab_node_name):
	var n = get_tree().get_nodes_in_group(tab_node_name)[0]
	if n.get_parent().name == "DisabledTabs":
		enable_tab(n)
		return "enabled"
	elif n.get_parent().name == "TabContainer":
		disable_tab(n)
		return "disabled"
		
func enable_tab(n):
	n.get_parent().remove_child(n)
	get_tree().get_nodes_in_group("TabContainer")[0].add_child(n)

func disable_tab(n):
	n.get_parent().remove_child(n)
	get_tree().get_nodes_in_group("DisabledTabs")[0].add_child(n)

func _debugger():
	if toggle_tab("ScriptDebugger") == "enabled":
		$vbox/Debugger.text = "Disable Debugger"
	else:
		$vbox/Debugger.text = "Enable Debugger"
	
func _framelog():
	if toggle_tab("FrameLog") == "enabled":
		$vbox/Framelog.text = "Disable Framelog"
	else:
		$vbox/Framelog.text = "Enable Framelog"
