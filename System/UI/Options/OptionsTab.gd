extends Control

var main

func _ready():
	main = get_tree().get_nodes_in_group("Main")[0]
	$vbox/Main.connect("button_up", self, "_main_menu")
	
func _main_menu():
	main.reload()
