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
var directory_index

func queue_free():
	print("queuing "+name)
	return .queue_free()
	
func load_sprite(path):
	var sprite = load("res://Graphics/PWSprite.gd").new()
	sprite.load_animation(path)
	return sprite
	
func set_grey(value):
	for sprite in sprites.values():
		sprite.set_grey(value)

func load_character(character_name, emotion, di:DirectoryIndexStack):
	char_name = character_name
	script_name = character_name
	directory_index = di
	char_path = "art/port/"+character_name.to_lower()+"/"+emotion
	# No blinking or talking
	var defaultpath = di.lookup_path(
		char_path+".png"
	)
	var blinkpath = di.lookup_path(
		char_path+"(blink).png"
	)
	var talkpath = di.lookup_path(
		char_path+"(talk).png"
	)
		
	# Load normal poses for modes we missed
	# TODO - probably not wanted
	#if emotion != "normal":
	#	if not defaultpath:
	#		defaultpath = di.lookup_path(
	#			char_path+"normal.png"
	#		)
	#	if not blinkpath:
	#		blinkpath = di.lookup_path(
	#			char_path+"normal(blink).png"
	#		)
	#	if not talkpath:
	#		talkpath = di.lookup_path(
	#			char_path+"normal(talk).png"
	#		)
	if defaultpath:
		sprites["default"] = load_sprite(defaultpath)
	if blinkpath:
		sprites["blink"] = load_sprite(blinkpath)
	if talkpath:
		sprites["talk"] = load_sprite(talkpath)
	play_state("blink")
	
func load_emotion(emotion):
	state = ""
	sprites = {}
	print("loading emotion:" + emotion)
	load_character(char_name, emotion, directory_index)
	
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

func _process(dt):
	pass
# TODO make blink speed more natural
