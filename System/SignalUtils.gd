extends Reference
class_name SignalUtils


static func remove_all(object:Object):
	for signal_name in object.get_signal_list():
		signal_name = signal_name["name"]
		for connection in object.get_signal_connection_list(signal_name):
			print("disconnect:", connection)
			object.disconnect(connection["signal"], connection["target"], connection["method"])
