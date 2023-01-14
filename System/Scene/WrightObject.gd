extends Node2D
class_name WrightObject

# Definitions
export var root_path:String = "res://"
export var base_path:String    # The base path ("edgeworth") before variants and sprites
export var variant_path:String # The variant path ("normal") before sprites are loaded
export var script_name:String  # How to identify the object

var char_name:String    # What this character is called for nametag purposes

# Animation state
export var sprite_key:String  # Current chosen sprite
# Depending on the object, the sprite key can be important
#   - default: a default key
#   - talk: the talk animation of a portrait
#   - blink: the blink animation of a portrait
#   - intro: an animation to show before switching to the default
#   - highlight: highlight while the mouse is over a button
#   - clicked: highlight while the mouse is clicking down on a button

var current_sprite:Node
var centered := false   # At x=0, y=0, the sprite should be in the center of the screen
var mirror := Vector2(1,1)
var _width_override = null
var _height_override = null
var width setget set_width_override, get_width
var height setget set_height_override, get_height
var click_area

var template:Dictionary # Remember the template we were initialized with, useful for save/load

# Positioning
var z:int
var scrollable := true

# Waiting
var wait := false
var wait_signal := "finished_playing"
signal started_playing
signal finished_playing
signal sprite_changed

## Internal use ##
var sprites:Dictionary = {
	
}

var main
var wrightscript
var sprite_root

# Classes
onready var FilesystemS = load("res://System/Files/Filesystem.gd")
onready var PWSpriteC = load("res://System/Graphics/PWSprite.gd")

# SetGets
func set_width_override(width):
	_width_override = width
func set_height_override(height):
	_height_override = height
func get_width():
	if _width_override != null:
		return _width_override
	if current_sprite:
		return current_sprite.width
	return 0
func get_height():
	if _height_override != null:
		return _height_override
	if current_sprite:
		return current_sprite.height
	return 0

# Cleanup

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
	
func init():
	if not sprite_root:
		sprite_root = Node2D.new()
		add_child(sprite_root)

#Sprite template:
#  path: path of sprite to load
#  animation_mode: loop, once, blink, talk, ...
func add_sprite(sprite_key, sprite_template):
	if not sprite_template["path"]:
		return
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
	sprite.load_animation(filename, null, template["rect"])
	sprites[sprite_key] = sprite
	return sprite
	
func load_sprites(template, sprite_key=null):
	init()
	self.template = template
	free_members()
	for sprite_key in template["sprites"]:
		var sprite_options = template["sprites"][sprite_key]
		add_sprite(sprite_key, sprite_options)
	
	# (combined) files turn into talk and blink animations
	process_combined()
	
	# if specific (required) animation types are not loaded, use the default
	process_missing()

	if not sprite_key:
		sprite_key = template["start_sprite"]
	# TODO mirror property should be set by the sprite!
	mirror.x = template["mirror"][0]
	mirror.y = template["mirror"][1]
	scrollable = template["scrollable"]
	
	if template["clickable"]:
		click_area = ClickArea.new()
		click_area.macroname = template["click_macro"]
		click_area.macroargs = template["click_args"]
		add_child(click_area)
		
	set_sprite(sprite_key)
		
func has_sprite(sprite_key):
	return sprite_key in sprites
	
# If we have a combined talk/blink sprite, separate the
# Frames into a separate talk sprite and blink sprite
func process_combined():
	if has_sprite("combined"):
		var count = sprites["combined"].animated_sprite.frames.get_frame_count("default")
		if not "talk" in sprites:
			add_sprite("talk", template["sprites"]["combined"])
			while sprites["talk"].animated_sprite.frames.get_frame_count("default") > count/2:
				sprites["talk"].animated_sprite.frames.remove_frame("default", count/2)
		if not "blink" in sprites:
			add_sprite("blink", template["sprites"]["combined"])
			while sprites["blink"].animated_sprite.frames.get_frame_count("default") > count/2:
				sprites["blink"].animated_sprite.frames.remove_frame("default", 0)


func process_missing():
	var tsprites = template["sprites"]
	for key in tsprites:
		if tsprites[key].get("fallback", false):
			if has_sprite(tsprites[key]["fallback"]) and not has_sprite(key):
				sprites[key] = sprites[tsprites[key]["fallback"]]

	
func set_sprite(new_sprite_key):
	if not new_sprite_key in sprites:
		return
	if sprite_key != new_sprite_key:
		if current_sprite:
			if current_sprite.is_connected("finished_playing", self, "sprite_finished_playing"):
				current_sprite.disconnect("finished_playing", self, "sprite_finished_playing")
			sprite_root.remove_child(current_sprite)
		sprite_key = new_sprite_key
		current_sprite = sprites[sprite_key]

		sprite_root.add_child(current_sprite)
		set_wait(wait)
		emit_signal("started_playing")
		current_sprite.connect("finished_playing", self, "sprite_finished_playing")
		# TODO center and mirror should be controlled by the sprite
		if centered:
			current_sprite.position = Vector2(256/2-current_sprite.width/2, 192/2-current_sprite.height/2)
		if mirror.x < 0:
			current_sprite.scale.x = -1
			current_sprite.position.x += current_sprite.width
		if mirror.y < 0:
			current_sprite.scale.y = -1
			current_sprite.position.y += current_sprite.height
		emit_signal("sprite_changed")

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
			return
		wait = false
		return

	# We will never finish playing if we don't have a sprite
	if wait_signal == "finished_playing":
		wait = false

	wait = value

func sprite_finished_playing():
	emit_signal("finished_playing")

# Effects 
func set_grey(value):
	for sprite in sprites.values():
		sprite.set_grey(value)
