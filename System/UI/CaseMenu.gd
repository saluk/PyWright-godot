extends Node

var cases = []
var wrightscript

signal CASE_SELECTED
var wait_signal = "CASE_SELECTED"
	
func add_case_button(path):
	var txt = path.replace("_"," ")
	var b = Button.new()
	b.text = path.rsplit("/")[-1]
	b.connect("pressed", self, "launch_game", [path])
	$Control/ScrollContainer2/VBoxContainer.add_child(b)
	
func _ready():
	for path in cases:
		add_case_button(path)

func launch_game(path):
	print("launching case ", path)
	Commands.call_command(
		"script",
		wrightscript, [
		path+"/intro"
	])
	queue_free()
	emit_signal("CASE_SELECTED")
