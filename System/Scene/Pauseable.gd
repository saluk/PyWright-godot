# pause/unpause parent object based on signals
# TODO - if there are multiple on/off signals, we need to ensure

extends Node
class_name Pauseable

# List of sets:
# [group, sig_enable, sig_disable]
# group - a group of objects to look for
# sig_enable - the signal on that group which will cause us to enable
# sig_disable - the signal on that group which will cause us to disable-
var signals = [
	["ScriptDebugger", "debug_state_off", "debug_state_on"]
]

# List of sets:
# [group, property]
# group - a group of objects to look for
# property - if this property equals the value, upon initialization the pauseable will be disabled
var properties = [
	["ScriptDebugger", "in_debugger", true]
]

func _init(node):
	name = "Pauseable"
	node.add_child(self)

func add_disable_signal(target, sig):
	target.connect(sig, self, "_disable")

func add_enable_signal(target, sig):
	target.connect(sig, self, "_enable")

func _disable():
	get_parent().set_process(false)

func _enable():
	get_parent().set_process(true)

# Try to connect to signals until they are all hooked up
func _process(dt):
	for i in range(signals.size()-1, -1, -1):
		var set = signals[i]
		var group = set[0]
		var sig_enable = set[1]
		var sig_disable = set[2]
		var obs = get_tree().get_nodes_in_group(group)
		if not obs:
			continue
		for ob in obs:
			add_enable_signal(ob, sig_enable)
			add_disable_signal(ob, sig_disable)
		signals.remove(i)
	for i in range(properties.size()-1, -1, -1):
		var set = properties[i]
		var group = set[0]
		var property = set[1]
		var value = set[2]
		var obs = get_tree().get_nodes_in_group(group)
		if not obs:
			continue
		for ob in obs:
			if ob.get(property) == value:
				_disable()
		properties.remove(i)
	if not signals and not properties:
		set_process(false)
