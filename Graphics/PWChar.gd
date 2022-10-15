extends Node2D
class_name PWChar

var sprites:Dictionary = {
	
}
var state:String
var char_path:String   # The path without (blink) or (talk)
var current_sprite
var char_name:String   # What this character is called for nametag purposes
var script_name:String # How to identify the character
var z:int
	
func load_sprite(path):
	var sprite = load("res://Graphics/PWSprite.gd").new()
	sprite.load_animation(path)
	return sprite
	
func set_grey(value):
	for sprite in sprites.values():
		sprite.set_grey(value)

func load_character(character_name, emotion, root):
	char_name = character_name
	script_name = character_name
	char_path = "art/port/"+character_name.to_lower()+"/"
	# No blinking or talking
	print(char_path+emotion+"(talk).png")
	var defaultpath = Filesystem.lookup_file(
		char_path+emotion+".png", 
		root)
	var blinkpath = Filesystem.lookup_file(
		char_path+emotion+"(blink).png",
		root)
	var talkpath = Filesystem.lookup_file(
		char_path+emotion+"(talk).png",
		root)
		
	# Load normal poses for modes we missed
	if emotion != "normal":
		if not defaultpath:
			defaultpath = Filesystem.lookup_file(
				char_path+"normal.png", 
				root)
		if not blinkpath:
			blinkpath = Filesystem.lookup_file(
				char_path+"normal(blink).png",
				root)
		if not talkpath:
			talkpath = Filesystem.lookup_file(
				char_path+"normal(talk).png",
				root)
	if defaultpath:
		sprites["default"] = load_sprite(defaultpath)
	if blinkpath:
		sprites["blink"] = load_sprite(blinkpath)
	if talkpath:
		sprites["talk"] = load_sprite(talkpath)
	play_state("blink")
	
func play_state(new_state):
	if state != new_state:
		if current_sprite:
			remove_child(current_sprite)
		state = new_state
		for new_state in [state, "default", "talk"]:
			if new_state in sprites:
				current_sprite = sprites[new_state]
				add_child(current_sprite)
				break
