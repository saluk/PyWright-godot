extends RefCounted
class_name SignalUtils

# weird things can happen if we remove these builtin signals
# TODO maybe there's a way we can ensure the "builtin" signals are kept
#    - if the signal name is defined in the user script
#	 - if the signal connection is a callable that points to a user script
const safe_signals = [
	"child_order_changed",
	"item_rect_changed",
	"size_flags_changed",
	"minimum_size_changed",
	"visibility_changed"]

static func remove_all(object:Object):
	if not is_instance_valid(object):
		return
	for signal_dict in object.get_signal_list():
		var signal_name = signal_dict["name"]
		if signal_name in safe_signals:
			continue
		for connection in object.get_signal_connection_list(signal_name):
			if object.is_connected((connection["signal"] as Signal).get_name(), connection["callable"]):
				object.disconnect(connection["signal"].get_name(), connection["callable"])
