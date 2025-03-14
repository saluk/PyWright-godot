extends RefCounted
class_name SignalUtils


static func remove_all(object:Object):
	if not is_instance_valid(object):
		return
	for signal_dict in object.get_signal_list():
		var signal_name = signal_dict["name"]
		for connection in object.get_signal_connection_list(signal_name):
			if object.is_connected(connection["signal"], Callable(connection["target"], connection["method"])):
				print("disconnect:", connection)
				object.disconnect(connection["signal"], Callable(connection["target"], connection["method"]))
