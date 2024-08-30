extends Node

class VariableDef extends Reference:
	var name:String
	var default_value
	var default_type:String
	func _init(name, default_type="string", default_value=null):
		self.name = name
		self.default_value = default_value
		self.default_type = default_type
	func retrieve(source=null):
		if not source:
			source = ObjectFactory.get_main().stack.variables
		return source.call("get_"+default_type, name, default_value)
	func store(value, source=null):
		if not source:
			source = ObjectFactory.get_main().stack.variables
		return source.set_val(name, value)
	func delete(source=null):
		if not source:
			source = ObjectFactory.get_main().stack.variables
		return source.del_val(name)

var COURT_FAIL_LABEL := VariableDef.new("_court_fail_label", "string", "none")
