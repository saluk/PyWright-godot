extends Node2D
class_name WrightObject

# Definitions
export var root_path:String = "res://"
export var base_path:String    # The base path ("edgeworth") before variants and sprites
export var variant_path:String # The variant path ("normal") before sprites are loaded
export var script_name:String  # How to identify the object
var variables:Variables # Object local variables accessed via [script_name].x 

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

var current_sprite:Node2D
var centered := false   # At x=0, y=0, the sprite should be in the center of the screen
var mirror := Vector2(1,1)
var _width_override = null
var _height_override = null
var width setget set_width_override, get_width
var height setget set_height_override, get_height
var click_area  # S 
var button # S

var template:Dictionary # Remember the template we were initialized with, useful for save/load
var cannot_save = false

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
var wrightscript  # Keeps a reference to the script that created us TODO ability for objects to be cleared when a script ends
# TODO not sure that wrightscript really needs to be a specific script
# if wrightscript doesn't exist (often happens after a load) we should just get the top script
var stack
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
	# Current sprite *should* be cleared as its in the tree but just in case
	if current_sprite:
		current_sprite.queue_free()
		current_sprite = null
	for sprite in sprites.values():
		if not sprite.is_queued_for_deletion():
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
	
func init():
	variables = Variables.new()
	if not sprite_root:
		sprite_root = Node2D.new()
		sprite_root.name = "SpriteRoot"
		add_child(sprite_root)

# Just used for logging
var sprite_paths_searched = []

#Sprite template:
#  path: path of sprite to load
#  animation_mode: loop, once, blink, talk, ...
func add_sprite(sprite_key, sprite_template):
	print("BEGIN SPRITE SEARCH: ", sprite_key, " ", sprite_template)
	# Ensure if we call add_sprite again for the same key we don't leave a reference
	if sprite_key in sprites:
		sprites[sprite_key].free()

	if not sprite_template["path"]:
		return
	var search_path = sprite_template["path"].format({
		"base": base_path,
		"variant": variant_path
	})
	var search_paths = [search_path]
	if search_path.ends_with(".png"):
		search_paths.append(search_path.substr(0,search_path.length()-4))
	while "//" in search_path:
		search_path = search_path.replace("//", "/")
		search_paths.append(search_path)
	var filename
	for path in search_paths:
		print(path)
		filename = Filesystem.lookup_file(
			path,
			root_path,
			[],
			false
		)
		if not filename:
			sprite_paths_searched.append(path)
			continue
		break
	if not filename:
		return
	var sprite = PWSpriteC.new()
	sprite.name = "PWSprite:"+base_path+";"+variant_path
	sprite.load_animation(filename, null, template["rect"])
	sprites[sprite_key] = sprite
	return sprite
	
func load_sprites(template, sprite_key=null):
	sprite_paths_searched = []

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
		click_area.name = "ClickArea"
		click_area.macroname = template["click_macro"]
		click_area.macroargs = template["click_args"]
		add_child(click_area)
	
	# Just the visual of the button, use click area to drive the game
	if template["button_text"]:
		button = Button.new()
		button.text = template["button_text"]
		button.name = "Button:"+template["button_text"]
		button.connect("button_up", click_area, "perform_action")
		add_child(button)
		
	set_sprite(sprite_key)
	if template["sprites"] and not sprites:
		var search_str = "'" + "', '".join(sprite_paths_searched) + "'"
		GlobalErrors.log_error("File Error: Unable to find or load a valid graphic file, searched [%s] at root path %s" % [search_str, root_path])	

func has_sprite(sprite_key):
	return sprite_key in sprites
	
# If we have a combined talk/blink sprite, separate the
# Frames into a separate talk sprite and blink sprite
func process_combined():
	if has_sprite("combined"):
		var count = sprites["combined"].animated_sprite.frames.get_frame_count("default")
		if not "talk" in sprites:
			add_sprite("talk", template["sprites"]["combined"])
			# Remove blink frames
			if count > 1:
				while sprites["talk"].animated_sprite.frames.get_frame_count("default") > count/2:
					sprites["talk"].animated_sprite.frames.remove_frame("default", count/2)
		if not "blink" in sprites:
			add_sprite("blink", template["sprites"]["combined"])
			# Remove talk frames
			if count > 1:
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
			SignalUtils.remove_all(current_sprite)
			sprite_root.remove_child(current_sprite)
		sprite_key = new_sprite_key
		current_sprite = sprites[sprite_key]
		current_sprite.set_block_signals(false)

		sprite_root.add_child(current_sprite)
		set_wait(wait)
		emit_signal("started_playing")
		current_sprite.connect("finished_playing", self, "sprite_finished_playing")
		if click_area:
			current_sprite.connect("size_changed", click_area, "sync_area")
		# TODO center and mirror should be controlled by the sprite
		if centered:
			current_sprite.position = Vector2(int(256/2)-int(current_sprite.width/2), int(192/2)-int(current_sprite.height/2))
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
		return

	wait = value

func sprite_finished_playing():
	emit_signal("finished_playing")

# Effects 
func set_grey(value):
	for sprite in sprites.values():
		sprite.set_grey(value)

### mainly for testing ###

# gets the current texture
func get_texture():
	if not current_sprite:
		return null
	var sprite = current_sprite.animated_sprite
	var frames = sprite.frames
	var texture = frames.get_frame(sprite.animation, sprite.frame)
	return texture
	
func get_display_rect():
	if not current_sprite:
		return null
	var texture:Texture = get_texture()
	var size = texture.get_size()
	var pos = current_sprite.global_position
	return Rect2(pos, size)

# true of the object can be found within the given rectangle
func visible_within(collide_rect:Rect2):
	var display_rect = get_display_rect()
	if collide_rect.encloses(display_rect):
		return true
	main.get_node("DebugLayer").draw(
		"draw_rect", [collide_rect, Color.blueviolet, false, 2, true]
	)
	main.get_node("DebugLayer").draw(
		"draw_rect", [display_rect, Color.red, false, 2, true]
	)
	main.pause(true)
	yield(get_tree(), "idle_frame")
	main.pause(false)
	return false



# SAVE/LOAD
var save_properties = [
	"root_path", "base_path", "variant_path", "script_name",
	"char_name", "sprite_key", "centered",
	"_width_override", "_height_override", "template",
	"z", "scrollable", "wait", "wait_signal",
	"rotation_degrees",
	"visible", "position", "scale",
	"modulate"
]
func save_node(data):
	data["mirror"] = [mirror.x, mirror.y]
	data["loader_class"] = "res://System/Scene/WrightObject.gd"
	data["parent_path"] = get_parent().get_path()
	if wrightscript:
		data["script_id"] = wrightscript.u_id
	data["variables"] = SaveState._save_node(variables)

static func create_node(saved_data:Dictionary):
	var ob = load(ObjectFactory.classes[saved_data["template"]["class"]]).new()
	return ob
	
func load_node(tree, saved_data:Dictionary):
	# TODO we should probably standardize saving dictionaries, vectors, and rects
	if "rect" in saved_data["template"] and saved_data["template"]["rect"]:
		var r = saved_data["template"]["rect"].substr(1,saved_data["template"]["rect"].length()-2).split(",")
		saved_data["template"]["rect"] = Rect2(
			int(r[0].strip_edges()),
			int(r[1].strip_edges()),
			int(r[2].strip_edges()),
			int(r[3].strip_edges())
		)
	main = tree.get_nodes_in_group("Main")[0]
	stack = main.stack
	# TODO we should include in save system which screen object is on
	ScreenManager.top_screen().add_child(self)
	load_sprites(saved_data["template"])
	set_sprite(sprite_key)
	SaveState._load_node(tree, variables, saved_data["variables"])

func after_load(tree:SceneTree, saved_data:Dictionary):
	if "script_id" in saved_data:
		for script in stack.scripts:
			if script.u_id == saved_data["script_id"]:
				wrightscript = script
				return
	print("error no script id found")
	# TODO we really should be air-tight in associating scripts correctly
	# but we can ensure things dont break by adding us to the top script
	# I think this happens because "wrightscript" is a reference, 
	# and that script can actually be gone from the stack when the object is saved
	wrightscript = tree.get_nodes_in_group("Main")[0].top_script()
