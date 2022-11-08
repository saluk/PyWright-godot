extends Reference

var main
var command

func _init(commands):
	main = commands.main
	command = commands

func ws_grey(script, arguments):
	var name = Commands.keywords(arguments).get("name", null)
	var value = Commands.keywords(arguments).get("value", 1)
	var obs
	if name:
		obs = Commands.get_objects(name, null)
	else:
		obs = Commands.get_objects(null, null)
	for o in obs:
		if o.has_method("set_grey"):
			o.set_grey(value)
