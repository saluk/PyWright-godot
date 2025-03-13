extends RefCounted
class_name NodeUtil

static func assign_node_dictionary(object:Object, nodes:Dictionary[NodePath, Node]):
	for field in object.get_property_list():
		if field['type'] == TYPE_NODE_PATH:
			var path = object.get(field['name'])
			nodes[path] = object.get_node(path)

static func create_node_dictionary(object:Object) -> Dictionary[NodePath, Node]:
	var nodes:Dictionary[NodePath, Node] = {}
	assign_node_dictionary(object, nodes)
	return nodes
