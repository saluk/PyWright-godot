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
	
var classes = {
	"WrightObject": "res://System/Scene/WrightObject.gd",
	"CourtRecord": "res://System/UI/CourtRecord.gd",
	"Investigate": "res://System/UI/Investigate.gd",
	"Penalty": "res://System/UI/Penalty.gd",
	"Examine": "res://System/UI/Examine.gd",
	"PWList": "res://System/UI/PWList.gd"
}
	
var TEMPLATES = {
	"bg":
		{
			"default_name": "bg",
			"class": "WrightObject",
			"sprites": {
				"default": {
					"path": "art/bg/{base}.png",
					"animation_mode": "loop",
					"mirror": [1, 1]
				}
			},
			"centered": false,
			"mirror": [1, 1],
			"block_script": false,
			"groups": [Commands.SPRITE_GROUP, Commands.BG_GROUP, Commands.CLEAR_GROUP],
			"start_sprite": "default",
			"sort_with": "bg",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": true,
			"click_macro": "",
			"click_args": [],
			"position": [0,0]
		},
	"fg":
		{
			"default_name": "fg",
			"class": "WrightObject",
			"sprites": {
				"default": {
					"path": "art/fg/{base}.png",
					"animation_mode": "loop",
					"mirror": [1, 1]
				}
			},
			"centered": true,
			"mirror": [1, 1],
			"block_script": true,
			"groups": [Commands.SPRITE_GROUP, Commands.FG_GROUP, Commands.CLEAR_GROUP],
			"start_sprite": "default",
			"sort_with": "fg",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": true,
			"click_macro": "",
			"click_args": [],
			"position": [0,0]
		},
	"ev":
		{
			"default_name": "ev",
			"class": "WrightObject",
			"sprites": {
				"default": {
					"path": "art/ev/{base}.png",
					"animation_mode": "loop",
					"mirror": [1, 1]
				}
			},
			"centered": false,
			"mirror": [1, 1],
			"block_script": false,
			"groups": [Commands.SPRITE_GROUP, Commands.CLEAR_GROUP],
			"start_sprite": "default",
			"sort_with": "evidence",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": true,
			"click_macro": "",
			"click_args": [],
			"position": [0,0]
		},
	"graphic":
		{
			"default_name": "graphic",
			"class": "WrightObject",
			"sprites": {
				"default": {
					"path": "art/{base}.png",
					"animation_mode": "loop",
					"mirror": [1, 1]
				}
			},
			"centered": false,
			"mirror": [1, 1],
			"block_script": false,
			"groups": [Commands.SPRITE_GROUP],
			"start_sprite": "default",
			"sort_with": "fg",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": true,
			"click_macro": "",
			"click_args": [],
			"position": [0,0]
		},
	"portrait":
		{
			"default_name": "portrait",
			"class": "WrightObject",
			"sprites": {
				"talk": {
					"path": "art/port/{base}/{variant}(talk).png",
					"animation_mode": "talk",
					"mirror": [1, 1],
					"fallback": "default"
				},
				"blink": {
					"path": "art/port/{base}/{variant}(blink).png",
					"animation_mode": "blink",
					"mirror": [1, 1],
					"fallback": "default"
				},
				"combined": {
					"path": "art/port/{base}/{variant}(combined).png",
					"animation_mode": "loop",
					"mirror": [1, 1]
				},
				"default": {
					"path": "art/port/{base}/{variant}.png",
					"animation_mode": "loop",
					"mirror": [1, 1]
				}
			},
			"centered": true,
			"mirror": [1, 1],
			"block_script": false,
			"groups": [Commands.CHAR_GROUP, Commands.SPRITE_GROUP, Commands.CLEAR_GROUP],
			"start_sprite": "blink",
			"sort_with": "portrait",
			"default_variant": "normal",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": true,
			"click_macro": "",
			"click_args": [],
			"position": [0,0]
		},
	"button":
		{
			"default_name": "button",
			"class": "WrightObject",
			"sprites": {
				"default": {
					"path": "art/{base}.png",
					"animation_mode": "once",
					"mirror": [1, 1]
				},
				"highlight": {
					"path": "art/{base}_high.png",
					"animation_mode": "once",
					"mirror": [1, 1]
				}
			},
			"centered": false,
			"mirror": [1, 1],
			"block_script": false,
			"groups": [Commands.SPRITE_GROUP],
			"start_sprite": "default",
			"sort_with": "gui",
			"default_variant": "",
			"rect": null,
			"clickable": true,
			"button_text": false,
			"scrollable": false,
			"click_macro": "",  # TODO click_macro and click_args should be properties rather then in the template
			"click_args": [],
			"position": [0,0]
		},
	"court_record":
		{
			"default_name": "evidence_menu",
			"class": "CourtRecord",
			"sprites": {},
			"centered": false,
			"mirror": [1, 1],
			"block_script": true,
			"groups": [Commands.SPRITE_GROUP],
			"start_sprite": "",
			"sort_with": "evidence_menu",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": false,
			"click_macro": "",  # TODO click_macro and click_args should be properties rather then in the template
			"click_args": [],
			"position": [0,0]
		},
	"investigate":
		{
			"default_name": "invest_menu",
			"class": "Investigate",
			"sprites": {},
			"centered": false,
			"mirror": [1, 1],
			"block_script": true,
			"groups": [Commands.SPRITE_GROUP],
			"start_sprite": "",
			"sort_with": "menu",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": false,
			"click_macro": "",  # TODO click_macro and click_args should be properties rather then in the template
			"click_args": [],
			"position": [0,0]
		},
	"examine_menu":
		{
			"default_name": "examine_menu",
			"class": "Examine",
			"sprites": {},
			"centered": false,
			"mirror": [1, 1],
			"block_script": true,
			"groups": [Commands.SPRITE_GROUP],
			"start_sprite": "",
			"sort_with": "examine_menu",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": false,
			"click_macro": "",  # TODO click_macro and click_args should be properties rather then in the template
			"click_args": [],
			"position": [0,0]
		},
	"list_menu":
		{
			"default_name": "listmenu",
			"class": "PWList",
			"sprites": {},
			"centered": false,
			"mirror": [1, 1],
			"block_script": true,
			"groups": [Commands.SPRITE_GROUP, Commands.LIST_GROUP],
			"start_sprite": "",
			"sort_with": "examine_menu",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": true,
			"click_macro": "",  # TODO click_macro and click_args should be properties rather then in the template
			"click_args": [],
			"position": [0,0]
		},
	"penalty":
		{
			"default_name": "evidence_menu",
			"class": "Penalty",
			"sprites": {},
			"centered": false,
			"mirror": [1, 1],
			"block_script": true,
			"groups": [Commands.SPRITE_GROUP, Commands.PENALTY_GROUP],
			"start_sprite": "",
			"sort_with": "penalty",
			"default_variant": "",
			"rect": null,
			"clickable": false,
			"button_text": false,
			"scrollable": false,
			"click_macro": "",  # TODO click_macro and click_args should be properties rather then in the template
			"click_args": [],
			"position": [0,0]
		}
}

# Get a template to be modified and then passed into create_from_template
func get_template(key, modified_data={}):
	var t = TEMPLATES[key].duplicate(true)
	t.merge(modified_data, true)
	return t
	
# Helper functions to modify a template

# Add, remove, or update a sprite
func update_sprite(template, key, data={}):
	data = data.duplicate(true)
	if not key in template["sprites"]:
		template["sprites"][key] = data
	else:
		template["sprites"][key].merge(data, true)
		
# Update potentially all values in the template
func update_template(template, data={}):
	data = data.duplicate(true)
	template.merge(data, true)

# TODO we probably never need to pass any script other than the top script
# should eliminate need for passing in the script

# TODO implement:
# loops
# rotx, roty, rotz
# scalex, scaley
# stack - use templates for whether the object should stack by default or not
#         non-stacked templates delete any other object generated from the same
#         template key
# fade - shorthand that also creates a fader object
func create_from_template(
		script, 
		template_key_or_template, 
		modify_template={}, 
		arguments=[],
		parent_name=null
	):

	
	# Load and modify template
	var template = template_key_or_template
	if template_key_or_template is String:
		template = get_template(template_key_or_template, modify_template)
	
	# Make object
	var object:Node = load(classes[template["class"]]).new()
	
	# Find parent and add object to it
	var parent
	if not parent_name:
		parent = get_main_screen()
	else:
		parent = Commands.get_objects(parent_name)
		if not parent:
			parent = get_main_screen()
			get_main_screen().log_error("Failed to find parent:"+parent_name)
		else:
			parent = parent[0]
	parent.add_child(object)
	
	# Initialize object values
	object.main = get_main()
	object.wrightscript = script
	object.stack = get_main().stack

	var keyword_arguments = Commands.keywords(arguments)
	var x=int(keyword_arguments.get("x", template["position"][0]))
	var y=int(keyword_arguments.get("y", template["position"][1]))
	object.position = Vector2(x, y)
	object.centered = template["centered"]
	if arguments:
		object.base_path = arguments[0]
	object.variant_path = template["default_variant"]
	if keyword_arguments.get("e", null):
		object.variant_path = keyword_arguments["e"]
	object.root_path = script.root_path
	if keyword_arguments.get("rect", null):
		var rc = keyword_arguments["rect"].split(",")
		template["rect"] = Rect2(int(rc[0]), int(rc[1]), int(rc[2]), int(rc[3]))
	if "flipx" in arguments:
		template["mirror"][0] = -1
	if "flipy" in arguments:
		template["mirror"][1] = -1
	if keyword_arguments.get("button_text", ""):
		template["button_text"] = keyword_arguments.get("button_text")
		
	object.load_sprites(template)
	last_object = object
	if arguments:
		object.script_name = keyword_arguments.get("name", arguments[0])
		object.add_to_group("name_"+object.script_name)
	else:
		if object.base_path:
			object.script_name = object.base_path
		elif object.variant_path:
			object.script_name = object.variant_path
		else:
			object.script_name = template["default_name"]
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
	return object
