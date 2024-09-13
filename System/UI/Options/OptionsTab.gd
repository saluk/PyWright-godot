extends Control

var main
var initialized = false

onready var new_save_button:Button = get_node("%NewSave")
onready var save_name:LineEdit = get_node("%SaveName")
onready var available_saves:ItemList = get_node("%AvailableSaves")

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
	new_save_button.connect("button_up", self, "_create_save")
	$"vbox/SaveLoad/HBoxContainer/Load Selected Save".connect("button_up", self, "_load_save")
	$"vbox/SaveLoad/HBoxContainer/Delete Selected Save".connect("button_up", self, "_delete_save")
	available_saves.connect("item_selected", self, "_select_available_save")
	save_name.connect("text_changed", self, "_change_save_name")
	
func _process(delta):
	if not initialized:
		initialized = true
		if Configuration.user.debugger_enabled:
			_debugger()

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
	var parent = n.get_parent()
	var tabcontainer = get_tree().get_nodes_in_group("TabContainer")[0]
	n.set_owner(tabcontainer)
	parent.remove_child(n)
	tabcontainer.add_child(n)

func disable_tab(n):
	n.get_parent().remove_child(n)
	get_tree().get_nodes_in_group("DisabledTabs")[0].add_child(n)

func _debugger():
	if toggle_tab("ScriptDebugger") == "enabled":
		$vbox/Debugger.text = "Disable Debugger"
		Configuration.set_and_save("debugger_enabled", true)
	else:
		$vbox/Debugger.text = "Enable Debugger"
		Configuration.set_and_save("debugger_enabled", false)
	
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
	
func _create_save():
	SaveState.save_new_file(main, save_name.text)
	available_saves.clear()
	_populate_load_games()
	
func _load_save():
	for item_num in available_saves.get_selected_items():
		var item = available_saves.get_item_text(item_num)
		SaveState.load_selected_save_file(main, item+".save")
		available_saves.clear()
		_populate_load_games()
		return
	
func _delete_save():
	for item_num in available_saves.get_selected_items():
		var item = available_saves.get_item_text(item_num)
		SaveState.delete_selected_save_file(main, item+".save")
		available_saves.remove_item(item_num)
		available_saves.select(item_num)
		return

func _populate_load_games():
	var save_files = SaveState.get_saved_games_for_current(main)
	for file in save_files:
		available_saves.add_item(file[1].rsplit(".save",true,1)[0])
	
func _enable_saveload_buttons(enabled=false):
	if enabled:
		new_save_button.disabled = false
		$"vbox/SaveLoad/HBoxContainer/Load Selected Save".disabled = false
		$"vbox/SaveLoad/HBoxContainer/Delete Selected Save".disabled = false
		available_saves.clear()
		_populate_load_games()
		$vbox/SaveLoad.visible = true
		# TODO find all saves
	else:
		new_save_button.disabled = true
		$"vbox/SaveLoad/HBoxContainer/Load Selected Save".disabled = true
		$"vbox/SaveLoad/HBoxContainer/Delete Selected Save".disabled = true
		available_saves.clear()
		$vbox/SaveLoad.visible = false

func _select_available_save(item_index):
	var selected_name = available_saves.get_item_text(item_index)
	if selected_name:
		save_name.text = selected_name
		save_name.emit_signal("text_changed", selected_name)
		
func _is_save_new(name) -> bool:
	for i in available_saves.get_item_count():
		if available_saves.get_item_text(i) == name:
			return false
	return true

func _change_save_name(name:String):
	if _is_save_new(name):
		new_save_button.text = "Save New Game"
	else:
		new_save_button.text = "OVERWRITE SAVE"
