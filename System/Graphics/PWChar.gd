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

var root_path:String  # Save root path for art lookups in case we change emotion

onready var FilesystemS = load("res://System/Files/Filesystem.gd")

func free_members():
	for sprite in sprites.values():
		sprite.queue_free()
	sprites.clear()

func queue_free():
	print("queuing pwchar "+name)
	free_members()
	return .queue_free()
	
func free():
	print("freeing pwchar "+name)
	free_members()
	return .free()
	
func load_sprite(path):
	var sprite = load("res://System/Graphics/PWSprite.gd").new()
	sprite.load_animation(path)
	sprite.position = Vector2(256/2-sprite.width/2, 192-sprite.height)
	return sprite
	
func set_grey(value):
	for sprite in sprites.values():
		sprite.set_grey(value)

func load_character(character_name, emotion, root_path):
	self.root_path = root_path
	char_name = character_name
	script_name = character_name
	char_path = "art/port/"+character_name.to_lower()+"/"+emotion
	# No blinking or talking
	var defaultpath = FilesystemS.lookup_file(
		char_path+".png", root_path
	)
	var blinkpath = FilesystemS.lookup_file(
		char_path+"(blink).png", root_path
	)
	var talkpath = FilesystemS.lookup_file(
		char_path+"(talk).png", root_path
	)
	
	var combinedpath = FilesystemS.lookup_file(
		char_path+"(combined).png", root_path
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
	if combinedpath:
		sprites["talk"] = load_sprite(combinedpath)
		sprites["blink"] = load_sprite(combinedpath)
		var count = sprites["talk"].animated_sprite.frames.get_frame_count("default")
		while sprites["talk"].animated_sprite.frames.get_frame_count("default") > count/2:
			sprites["talk"].animated_sprite.frames.remove_frame("default", count/2)
		while sprites["blink"].animated_sprite.frames.get_frame_count("default") > count/2:
			sprites["blink"].animated_sprite.frames.remove_frame("default", 0)
			
	# TODO if we dont have a talking sprite but we have a blinking one, make the talking sprite the blinking one? maybe?
		
	play_state("blink")
	
func load_emotion(emotion):
	free_members()
	state = ""
	sprites = {}
	print("loading emotion:" + emotion)
	load_character(char_name, emotion, root_path)
	
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
