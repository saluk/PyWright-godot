extends Reference

var main

func _init(commands):
	main = commands.main

func ws_pause(script, arguments):
	# Need to add priority
	if main.get_tree():
		return main.get_tree().create_timer(int(arguments[0])/60.0 * Commands.PAUSE_MULTIPLIER)

# TODO IMPLEMENT
func ws_timer(script, arguments):
	pass
