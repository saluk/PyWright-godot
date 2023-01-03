extends Node2D
class_name WrightObject

# Definitions
var root_path:String
var base_path:String  # The base path ("edgeworth") before variants and sprites
var variant_path:String  # The variant path ("normal") before sprites are loaded
var script_name:String # How to identify the character
var char_name:String   # What this character is called for nametag purposes

# Animation state
var sprite_key:String
var current_sprite:Node
var centered := false   # At x=0, y=0, the sprite should be in the center of the screen
var template:Dictionary

# Positioning
var z:int

# Waiting
var wait := false
var wait_signal := "finished_playing"
signal started_playing
signal finished_playing

## Internal use ##
var sprites:Dictionary = {
	
}

var main

# Classes
onready var FilesystemS = load("res://System/Files/Filesystem.gd")
onready var PWSpriteC = load("res://System/Graphics/PWSprite.gd")

func free_members():
	sprite_key = ""
	for sprite in sprites.values():
		sprite.queue_free()
	sprites.clear()
	current_sprite = null

func queue_free():
	print("queuing pwchar "+name)
	free_members()
	return .queue_free()
	
func free():
	print("freeing pwchar "+name)
	free_members()
	return .free()

#Sprite template:
#  path: path of sprite to load
#  animation_mode: loop, once, blink, talk, ...
func add_sprite(sprite_key, sprite_template):
	var filename = Filesystem.lookup_file(
		sprite_template["path"].format({
			"base": base_path,
			"variant": variant_path
		}),
		root_path
	)
	if not filename:
		return
	var sprite = PWSpriteC.new()
	sprite.load_animation(filename)
	sprites[sprite_key] = sprite
	return sprite
	
func load_sprites(template, sprite_key=null):
	self.template = template
	free_members()
	for sprite_key in template["sprites"]:
		var sprite_options = template["sprites"][sprite_key]
		add_sprite(sprite_key, sprite_options)
	if template["process_combined"]:
		process_combined()
	if not sprite_key:
		sprite_key = template["start_sprite"]
	set_sprite(sprite_key)
	
# If we have a combined talk/blink sprite, separate the
# Frames into a separate talk sprite and blink sprite
func process_combined():
	if "combined" in sprites:
		var count = sprites["combined"].animated_sprite.frames.get_frame_count("default")
		if not "talk" in sprites:
			add_sprite("talk", template["sprites"]["combined"])
			while sprites["talk"].animated_sprite.frames.get_frame_count("default") > count/2:
				sprites["talk"].animated_sprite.frames.remove_frame("default", count/2)
		if not "blink" in sprites:
			add_sprite("blink", template["sprites"]["combined"])
			while sprites["blink"].animated_sprite.frames.get_frame_count("default") > count/2:
				sprites["blink"].animated_sprite.frames.remove_frame("default", 0)

	
func set_sprite(new_sprite_key):
	if not new_sprite_key in sprites:
		return
	if sprite_key != new_sprite_key:
		if current_sprite:
			if current_sprite.is_connected("finished_playing", self, "sprite_finished_playing"):
				current_sprite.disconnect("finished_playing", self, "sprite_finished_playing")
			remove_child(current_sprite)
		sprite_key = new_sprite_key
		current_sprite = sprites[sprite_key]
		add_child(current_sprite)
		set_wait(wait)
		emit_signal("started_playing")
		current_sprite.connect("finished_playing", self, "sprite_finished_playing")
		if centered:
			current_sprite.position = Vector2(256/2-current_sprite.width/2, 192/2-current_sprite.height/2)

# Change the variant and reload the sprites
func change_variant(new_variant):
	if new_variant != variant_path:
		variant_path = new_variant
		load_sprites(template, sprite_key)

# Should only be called when creating the object from a script. Will try to set the wait
# to the value, unless the current sprite animation has no frames or loops
func set_wait(value):
	if current_sprite:
		if current_sprite.can_wait():
			wait = value
	wait = false

func sprite_finished_playing():
	emit_signal("finished_playing")

# Effects 
func set_grey(value):
	for sprite in sprites.values():
		sprite.set_grey(value)
