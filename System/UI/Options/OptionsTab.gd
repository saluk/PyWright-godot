extends Control

var main
var initialized = false

onready var new_save_button:Button = get_node("%NewSave")
onready var save_name:LineEdit = get_node("%SaveName")
onready var available_saves:ItemList = get_node("%AvailableSaves")
onready var memory_leak:Button = get_node("%MemoryLeak")
onready var free_orphans:Button = get_node("%FreeOrphans")

var saves_enabled = false
var last_save_files = []

func _ready():
	main = get_tree().get_nodes_in_group("Main")[0]
	$vbox/MainMenu.connect("button_up", self, "_main_menu")
	$vbox/Quit.connect("button_up", self, "_quit")
	$vbox/Debugger.connect("button_up", self, "_debugger")
	$vbox/Framelog.connect("button_up", self, "_framelog")
	memory_leak.connect("button_up", self, "_memory_leak")
	free_orphans.connect("button_up", self, "_free_orphans")
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
	_populate_load_games()

func _load_save():
	for item_num in available_saves.get_selected_items():
		var item = available_saves.get_item_text(item_num)
		SaveState.load_selected_save_file(main, root_save_game, item+".save")
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

var root_save_game = null
func _populate_load_games(save_files=null):
	if save_files==null:
		root_save_game = main.top_script().root_path
		save_files = SaveState.get_saved_games_for_current(GamePath.new().from_main(main))
	if save_files == last_save_files:
		return
	available_saves.clear()
	last_save_files = save_files
	for i in range(save_files.size()):
		var file = save_files[save_files.size()-i-1]
		available_saves.add_item(file[1].rsplit(".save",true,1)[0])

func _enable_saveload_buttons(load_enabled=false, save_enabled=false, save_files=null):
	if load_enabled:
		$"vbox/SaveLoad/HBoxContainer/Load Selected Save".disabled = false
		$"vbox/SaveLoad/HBoxContainer/Delete Selected Save".disabled = false
		_populate_load_games(save_files)
		$vbox/SaveLoad.visible = true
		# TODO find all saves
	else:
		$"vbox/SaveLoad/HBoxContainer/Load Selected Save".disabled = true
		$"vbox/SaveLoad/HBoxContainer/Delete Selected Save".disabled = true
		#_populate_load_games([])
		$vbox/SaveLoad.visible = false
	if save_enabled:
		new_save_button.disabled = false
	else:
		new_save_button.disabled = true

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

func _memory_leak():
	print("stray nodes:")
	print_stray_nodes()
	print("tree:")
	main.print_tree_pretty()

func _free_orphans():
	main.free_orphans()
