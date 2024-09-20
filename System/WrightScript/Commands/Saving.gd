extends Reference

var main

func _init(commands):
	main = commands.main

func ws_savegame(script, arguments):
	return Commands.NOTIMPLEMENTED

func ws_loadgame(script, arguments):
	return Commands.NOTIMPLEMENTED

func ws_screenshot(script, arguments):
	return Commands.NOTIMPLEMENTED

# NEW
# Creates a "checkpoint" save, which can be loaded in PyWright
# TODO make the checkpoint work in godot as well
func ws_checkpoint(script, arguments):
	Checkpoint.save_pywright_checkpoint(main, main.top_script().root_path+"gdsave.ns")
