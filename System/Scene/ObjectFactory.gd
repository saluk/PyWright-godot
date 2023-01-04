extends Node

var _main
var _main_screen

var main setget , get_main
var main_screen setget , get_main_screen

var last_object

func get_main_screen():
	return get_tree().get_nodes_in_group("MainScreen")[0]
	
func get_main():
	return get_tree().get_nodes_in_group("Main")[0]
	
var TEMPLATES = {
	"bg":
		{
			"sprites": {
				"default": {
					"path": "art/bg/{base}.png",
					"animation_mode": "loop"
				}
			},
			"centered": false,
			"block_script": false,
			"groups": [Commands.SPRITE_GROUP, Commands.BG_GROUP, Commands.CLEAR_GROUP],
			"start_sprite": "default",
			"sort_with": "bg",
			"default_variant": "",
			"process_combined": false,
			"clickable": false
		},
	"fg":
		{
			"sprites": {
				"default": {
					"path": "art/fg/{base}.png",
					"animation_mode": "loop"
				}
			},
			"centered": true,
			"block_script": true,
			"groups": [Commands.SPRITE_GROUP, Commands.FG_GROUP, Commands.CLEAR_GROUP],
			"start_sprite": "default",
			"sort_with": "fg",
			"default_variant": "",
			"process_combined": false,
			"clickable": false
		},
	"graphic":
		{
			"sprites": {
				"default": {
					"path": "art/{base}.png",
					"animation_mode": "loop"
				}
			},
			"centered": false,
			"block_script": false,
			"groups": [Commands.SPRITE_GROUP],
			"start_sprite": "default",
			"sort_with": "fg",
			"default_variant": "",
			"process_combined": false,
			"clickable": false
		},
	"portrait":
		{
			"sprites": {
				"talk": {
					"path": "art/port/{base}/{variant}(talk).png",
					"animation_mode": "talk"
				},
				"blink": {
					"path": "art/port/{base}/{variant}(blink).png",
					"animation_mode": "blink"
				},
				"combined": {
					"path": "art/port/{base}/{variant}(combined).png",
					"animation_mode": "loop"
				},
			},
			"centered": true,
			"block_script": false,
			"groups": [Commands.CHAR_GROUP, Commands.SPRITE_GROUP, Commands.CLEAR_GROUP],
			"start_sprite": "blink",
			"sort_with": "portrait",
			"default_variant": "normal",
			"process_combined": true,
			"clickable": false
		},
	"button":
		{
			"sprites": {
				"default": {
					"path": "art/{base}.png",
					"animation_mode": "once"
				},
				"highlight": {
					"path": "art/{base}_high.png",
					"animation_mode": "once"
				}
			},
			"centered": false,
			"block_script": false,
			"groups": [Commands.SPRITE_GROUP],
			"start_sprite": "default",
			"sort_with": "gui",
			"default_variant": "",
			"process_combined": false,
			"clickable": true
		}
}

func create_from_template(script, template_key_or_template, arguments=[]):
	var object:Node
	var template = template_key_or_template
	if template_key_or_template is String:
		template = TEMPLATES[template_key_or_template]
	object = load("res://System/Scene/WrightObject.gd").new()
	get_main_screen().add_child(object)
	object.main = get_main()
	object.wrightscript = script
	var keyword_arguments = Commands.keywords(arguments)
	var x=int(keyword_arguments.get("x", 0))
	var y=int(keyword_arguments.get("y", 0))
	object.position = Vector2(x, y)
	object.centered = template["centered"]
	var base_path = arguments[0]
	object.base_path = base_path
	object.variant_path = template["default_variant"]
	object.root_path = script.root_path
	if keyword_arguments.get("rect", null):
		var rc = keyword_arguments["rect"].split(",")
		object.sub_rect = Rect2(int(rc[0]), int(rc[1]), int(rc[2]), int(rc[3]))
	object.load_sprites(template)
	last_object = object
	if arguments:
		object.script_name = keyword_arguments.get("name", arguments[0])
		object.add_to_group("name_"+object.script_name)
	if keyword_arguments.get("z", null)!=null:
		object.z = int(keyword_arguments["z"])
	else:
		object.z = ZLayers.z_sort[template["sort_with"]]
	for group in template["groups"]:
		object.add_to_group(group)
	# This is just to help debugging in godot
	# Godot .name should be unique in the scene but WrightScript can have duplicate names
	object.name = object.script_name
	object.set_wait(template["block_script"])
	if "wait" in arguments:
		object.set_wait(true)    #Try to make the object wait, if it is a single play animation that has more than one frame
	if "nowait" in arguments:
		object.set_wait(false)
	if "flipx" in arguments:
		object.sprite_root.scale.x = -1
	if "flipy" in arguments:
		object.sprite_root.scale.y = -1
	return object

# TODO implement:
# loops
# flipx, flipy
# rotx, roty, rotz
# stack
# fade
var WAITERS = ["fg"]
var centered_objects = ["fg"]
func create_object(script, command, class_path, groups, arguments=[]):
	var object:Node
	object = load(class_path).new()
	get_main_screen().add_child(object)
	if "main" in object:
		object.main = get_main()
	var keyword_arguments = Commands.keywords(arguments)
	var x=int(keyword_arguments.get("x", 0))
	var y=int(keyword_arguments.get("y", 0))
	object.position = Vector2(x, y)
	if command in ["bg", "fg"]:
		var filename = Filesystem.lookup_file(
			"art/"+command+"/"+arguments[0]+".png",
			script.root_path
		)
		if not filename:
			main.log_error("No file found for "+arguments[0]+" tried: "+"art/"+command+"/"+arguments[0]+".png")
			return null
		object.load_animation(filename)
	elif command in ["gui"]:
		var frame = Filesystem.lookup_file(
			"art/"+keyword_arguments.get("graphic", "")+".png",
			script.root_path
		)
		var frameactive = Filesystem.lookup_file(
			"art/"+keyword_arguments.get("graphichigh", "")+".png",
			script.root_path
		)
		object.load_art(frame, frameactive, keyword_arguments.get("button_text", ""))
		object.area.rect_position = Vector2(0, 0)
	elif "PWChar" in class_path:
		object.load_character(
			arguments[0], 
			keyword_arguments.get("e", "normal"),
			script.root_path
		)
	elif "PWEvidence" in class_path:
		object.load_art(script.root_path, arguments[0])
	elif object.has_method("load_animation"):
		object.load_animation(
			Filesystem.lookup_file(
				"art/"+arguments[0]+".png",
				script.root_path
			)
		)
	elif object.has_method("load_art"):
		object.load_art(script.root_path)
	var center = Vector2()
	if command in centered_objects:
		object.position += Vector2(256/2-object.width/2, 192/2-object.height/2)
	last_object = object
	if arguments:
		object.script_name = keyword_arguments.get("name", arguments[0])
		object.add_to_group("name_"+object.script_name)
	if keyword_arguments.get("z", null)!=null:
		object.z = int(keyword_arguments["z"])
	else:
		object.z = ZLayers.z_sort[command]
	for group in groups:
		object.add_to_group(group)
	object.name = object.script_name
	#Set object to wait mode if possible and directed to
	if "wait" in object:
		object.set_wait(command in WAITERS)
		# If we say to wait or nowait, apply it
		if "wait" in arguments:
			object.set_wait(true)    #Try to make the object wait, if it is a single play animation that has more than one frame
		if "nowait" in arguments:
			object.set_wait(false)
	return object
