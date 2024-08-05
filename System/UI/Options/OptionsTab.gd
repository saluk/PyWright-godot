extends Control

var main

func _ready():
	main = get_tree().get_nodes_in_group("Main")[0]
	$vbox/MainMenu.connect("button_up", self, "_main_menu")
	$vbox/Quit.connect("button_up", self, "_quit")
	$vbox/Debugger.connect("button_up", self, "_debugger")
	$vbox/Framelog.connect("button_up", self, "_framelog")
	$"vbox/DirectoryCacheList Toggle".connect("button_up", self, "_dcl")
	
	$vbox/HBoxContainer/VolumeSlider.value = Configuration.user.global_volume * 100
	$vbox/HBoxContainer/VolumeSlider.connect("value_changed", self, "_volume_changed")
	
	main.connect("enable_saveload_buttons", self, "_enable_saveload_buttons")
	main.check_saving_enabled()
	$"vbox/SaveLoad/New Save".connect("button_up", self, "_create_new_save")
	$"vbox/SaveLoad/HBoxContainer/Load Selected Save".connect("button_up", self, "_load_save")
	$"vbox/SaveLoad/HBoxContainer/Delete Selected Save".connect("button_up", self, "_delete_save")

func _main_menu():
	main.reload()
	
func _quit():
	get_tree().quit()

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
		main.debugger_enabled = true
	else:
		$vbox/Debugger.text = "Enable Debugger"
		main.debugger_enabled = false
	
func _framelog():
	if toggle_tab("FrameLog") == "enabled":
		$vbox/Framelog.text = "Disable Framelog"
	else:
		$vbox/Framelog.text = "Enable Framelog"
		
func _dcl():
	if toggle_tab("DirectoryCacheList") == "enabled":
		$"vbox/DirectoryCacheList Toggle".text = "Disable DirectoryCacheList"
	else:
		$"vbox/DirectoryCacheList Toggle".text = "Enable DirectoryCacheList"

func _volume_changed(val):
	Configuration.user.global_volume = float(val/100.0)
	Configuration.save_config()
	MusicPlayer.alter_volume()
	
func _create_new_save():
	SaveState.save_new_file(main)
	$vbox/SaveLoad/AvailableSaves.clear()
	_populate_load_games()
	
func _load_save():
	for item_num in $vbox/SaveLoad/AvailableSaves.get_selected_items():
		var item = $vbox/SaveLoad/AvailableSaves.get_item_text(item_num)
		SaveState.load_selected_save_file(main, item)
		$vbox/SaveLoad/AvailableSaves.clear()
		_populate_load_games()
		return
	
func _delete_save():
	for item_num in $vbox/SaveLoad/AvailableSaves.get_selected_items():
		var item = $vbox/SaveLoad/AvailableSaves.get_item_text(item_num)
		SaveState.delete_selected_save_file(main, item)
		$vbox/SaveLoad/AvailableSaves.remove_item(item_num)
		$vbox/SaveLoad/AvailableSaves.select(item_num)
		return

func _populate_load_games():
	var save_files = SaveState.get_saved_games_for_current(main)
	for filename in save_files:
		$vbox/SaveLoad/AvailableSaves.add_item(filename)
	
func _enable_saveload_buttons(enabled=false):
	if enabled:
		$"vbox/SaveLoad/New Save".disabled = false
		$"vbox/SaveLoad/HBoxContainer/Load Selected Save".disabled = false
		$"vbox/SaveLoad/HBoxContainer/Delete Selected Save".disabled = false
		$vbox/SaveLoad/AvailableSaves.clear()
		_populate_load_games()
		$vbox/SaveLoad.visible = true
		# TODO find all saves
	else:
		$"vbox/SaveLoad/New Save".disabled = true
		$"vbox/SaveLoad/HBoxContainer/Load Selected Save".disabled = true
		$"vbox/SaveLoad/HBoxContainer/Delete Selected Save".disabled = true
		$vbox/SaveLoad/AvailableSaves.clear()
		$vbox/SaveLoad.visible = false
