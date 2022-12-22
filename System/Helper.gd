extends Node
func keywords(arguments, variables, remove=false):
	# TODO determine if we actually ALWAYS want to replace $ variables here
	var newargs = []
	var d = {}
	for arg in arguments:
		if "=" in arg:
			var split = arg.split("=", true, 1)
			d[split[0]] = variables.value_replace(split[1])
		else:
			newargs.append(arg)
	if remove:
		return [d, newargs]
	return d
