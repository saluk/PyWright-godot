extends Node

func log_error(msg, context={}):
	get_tree().call_group("ErrorLog", "log_error", msg, context)

func log_info(msg, context={}):
	get_tree().call_group("ErrorLog", "log_info", msg, context)
