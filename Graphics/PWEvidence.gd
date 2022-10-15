extends Node2D
class_name PWEvidence

var root_path
var ev_name
var script_name:String
var z:int

func load_art(root_path, ev_name):
	self.root_path = root_path
	self.ev_name = ev_name
	var ev_pic = Commands.main.stack.variables.get_string(ev_name+"_pic", ev_name)
	var pic = PWSprite.new()
	pic.load_animation(
		Filesystem.lookup_file("art/ev/"+ev_pic+".png", root_path)
	)
	add_child(pic)
