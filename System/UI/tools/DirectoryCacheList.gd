extends Control

var MAX_LENGTH = 10102
var enabled = false




func _on_Button_button_up():
	var text = ""
	
	var main = get_tree().get_nodes_in_group("Main")[0]
	var stack = main.stack
	
	var dc = DirectoryCache
	
	for key in dc.indexes.keys():
		text += display_index(key, dc.indexes[key]) + "\n\n"
	
	$Text.text = text

func display_index(key, index):
	var text = ""
	text += "INDEX: %s\n-----------\n" % key
	for file_key in index.keys():
		text += "%s:      %s\n" % [file_key, (index[file_key])]
	return text
