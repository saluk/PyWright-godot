extends Reference

var main
var command

func _init(commands):
	main = commands.main
	command = commands

func ws_pause(script, arguments):
	# Need to add priority
	if main.get_tree():
		return main.get_tree().create_timer(int(arguments[0])/60.0 * Commands.PAUSE_MULTIPLIER)

func ws_timer(script, arguments):
	pass
