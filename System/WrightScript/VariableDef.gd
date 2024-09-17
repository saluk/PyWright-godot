extends Reference
class_name VariableDef

var name:String
var default_value
var default_type:String
var split_on
func _init(name, default_type="string", default_value=null, split_on=null):
	self.name = name
	self.default_value = default_value
	self.default_type = default_type
	self.split_on = split_on
func retrieve(source=null):
	if not source:
		source = ObjectFactory.get_main().stack.variables
	if self.split_on != null:
		return source.call("get_"+default_type, name, default_value, self.split_on)
	else:
		return source.call("get_"+default_type, name, default_value)
func store(value, source=null):
	if not source:
		source = ObjectFactory.get_main().stack.variables
	return source.set_val(name, value, self.split_on)
func delete(source=null):
	if not source:
		source = ObjectFactory.get_main().stack.variables
	return source.del_val(name)
