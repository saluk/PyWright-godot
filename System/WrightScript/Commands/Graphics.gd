extends Reference

var main

func _init(commands):
	main = commands.main
		# """Clears all objects from the scene."""
		# if "top" in args:
		#     for o in self.obs:
		#         if hasattr(o,"pos") and o.pos[1]<192:
		#             o.delete()
		#     return
		# elif "bottom" in args:
		#     for o in self.obs:
		#         if hasattr(o,"pos") and o.pos[1]>=192:
		#             o.delete()
		#     return
		# for o in self.obs:
		#     o.delete()
func ws_clear(script, arguments):
	var top = true
	var bottom = true
	if "bottom" in arguments:
		top = false
	if "top" in arguments:
		bottom = false
	script.screen.clear(top, bottom)
func ws_delete(script, arguments):
	var name = Commands.keywords(arguments).get("name", null)
	if name != null:
		script.screen.sort_children()
		var children = script.screen.get_children()
		for i in range(children.size()):
			if not "script_name" in children[-i]:
				continue
			if children[-i].script_name == name:
				children[-i].queue_free()
				children[-i].name = "DELETED_"+children[-1].name
				
func apply_fader(script, obj, arguments):
	if not "fade" in arguments:
		return
	var start = 0.0
	var end = 100.0
	var speed = 5.0
	var wait = true
	var fader = FadeLib.Fader.new(start, end, speed, wait)
	fader.control(obj.script_name)
	script.screen.add_child(fader)
	return fader
				
func ws_obj(script, arguments):
	if not main.get_tree():
		return
	var obj:Node = ObjectFactory.create_from_template(
		script,
		"graphic",
		{},
		arguments
	)
	var fader = apply_fader(script, obj, arguments)
	if fader:
		return fader
	return obj
	
func ws_bg(script, arguments):
	if not main.get_tree():
		return
	if not "stack" in arguments:
		Commands.delete_object_group(Commands.CLEAR_GROUP)
	var bg:Node = ObjectFactory.create_from_template(script, "bg", {}, arguments)
	apply_fader(script, bg, arguments)
	return bg
	
func ws_fg(script, arguments):
	if not main.get_tree():
		return
	var fg:Node = ObjectFactory.create_from_template(script, "fg", {}, arguments)
	apply_fader(script, fg, arguments)
	return fg

# TODO support more commands
# priority=
func ws_char(script, arguments):
	if not main.get_tree():
		return
	var kw = Commands.keywords(arguments)
	# If we don't "stack" then delete existing character
	if not "stack" in arguments and not "hide" in arguments:
		Commands.delete_object_group(Commands.CHAR_GROUP)
	var character = ObjectFactory.create_from_template(
		script,
		"portrait",
		{},
		arguments
	)
	# TODO "e" is handled in ObjectFactory. probably should pick a lane here
	if "be" in kw:
		character.add_sprite("blink", {
			"path": "art/port/{base}/"+kw["be"]+"(blink).png",
			"animation_mode": "blink",
			"mirror": [1, 1],
			"fallback": "default"
		})
	if "hide" in arguments:
		character.visible = false
		Commands.delete_object_group(Commands.HIDDEN_CHAR_GROUP)
		character.add_to_group(Commands.HIDDEN_CHAR_GROUP)
	# This should maybe be a "property" (variable namespaced on the object)
	character.char_name = main.stack.variables.get_string(
		"char_"+character.base_path+"_name",
		character.base_path.capitalize()
	)
	if "nametag" in kw:
		character.char_name = kw["nametag"]
	if "noauto" in arguments:
		# just play character animation as if they weren't a character
		while character.sprites.size() > 1:
			character.remove_sprite(character.sprites.keys()[0])
		if character.sprites:
			character.set_sprite(character.sprites.keys()[0])
	# Called last because _speaking has a setter that sets _speaking_name
	main.stack.variables.set_val("_speaking", character.base_path)
	apply_fader(script, character, arguments)
	return character
	
func ws_emo(script, arguments):
	var kw = Commands.keywords(arguments, true)
	arguments = kw[1]
	kw = kw[0]
	var name = kw.get("name", null)
	var mode = kw.get("mode", null)
	var emotion = ""
	if arguments.size() > 0:
		emotion = arguments[0]
	var characters
	if not name:
		var speaking = Commands.get_speaking_char()
		if speaking:
			characters = [speaking]
	else:
		characters = Commands.get_objects(name, false, Commands.CHAR_GROUP)
	# TODO should this be the first or last found character if multiple characters have the same name?
	if characters:
		characters[0].change_variant(emotion)
		if mode:
			characters[0].set_sprite(mode)
			
# TODO test
func ws_bemo(script, arguments):
	arguments.append("mode=blink")
	return ws_emo(script, arguments)

func ws_ev(script, arguments):
	var ev_name = arguments[0]
	var pic = Commands.main.stack.variables.get_string(ev_name+"_pic", ev_name)
	var ev = ObjectFactory.create_from_template(
		script,
		"ev",
		{
			"sprites": {
				"default": {
					"path": "art/ev/"+pic+".png"
				}
			}
		},
		arguments
	)
	apply_fader(script, ev, arguments)
	return ev

func ws_addev(script, arguments):
	#tag, [page]
	#if tag ends with $ page = profiles
	#otherwise page defaults to evidence
	var tag:String = arguments[0]
	var page = "evidence"
	if tag.ends_with("$"):
		# TODO make sure the name is set up correctly
		page = "profiles"
	if arguments.size()>1:
		page = arguments[1]
	var page_arr = main.stack.evidence_pages.get(page, [])
	if not tag in page_arr:
		page_arr.append(tag)
		main.stack.evidence_pages[page] = page_arr
		
func ws_delev(script, arguments):
	for page in main.stack.evidence_pages:
		var page_array = main.stack.evidence_pages[page]
		if arguments[0] in page_array:
			page_array.erase(arguments[0])

func ws_penalty(script, arguments):
	var variable = Commands.keywords(arguments).get("variable", "penalty")
	var threat = Commands.keywords(arguments).get("threat", null)
	var delay = Commands.keywords(arguments).get("delay", null)
	var damage_amount
	if arguments:
		if "=" in arguments[0]:
			damage_amount = null
		else:
			damage_amount = arguments[0]
	if delay==null:
		delay = 50
		if not damage_amount or threat:
			delay = 0
	Commands.delete_object_group(Commands.PENALTY_GROUP)
	var penalty = ObjectFactory.create_from_template(
		script,
		"penalty",
		{}
	)
	penalty.variable = variable
	if threat:
		penalty.threat_amount = int(threat)
	penalty.delay = int(delay)
	penalty.start_value = main.stack.variables.get_int(variable, 100)
	if damage_amount and damage_amount[0] == "-":
		penalty.end_value = penalty.start_value - int(damage_amount.substr(1))
	elif damage_amount and damage_amount[0] == "+":
		penalty.end_value = penalty.start_value + int(damage_amount.substr(1))
	elif damage_amount:
		penalty.end_value = int(damage_amount)
	else:
		penalty.end_value = penalty.start_value
	penalty.begin()
	if penalty.delay > 0:
		return penalty

func ws_surf3d(script, arguments):
	return Commands.NOTIMPLEMENTED
	
func ws_mesh(script, arguments):
	return Commands.NOTIMPLEMENTED
	
