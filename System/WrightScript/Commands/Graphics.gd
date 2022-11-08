extends Reference

var main
var command

func _init(commands):
	main = commands.main
	command = commands

func ws_clear(script, arguments):
	Commands.clear_main_screen()
func ws_delete(script, arguments):
	var name = Commands.keywords(arguments).get("name", null)
	if name != null:
		Commands.main_screen.sort_children()
		var children = Commands.main_screen.get_children()
		for i in range(children.size()):
			if not "script_name" in children[-i]:
				continue
			if children[-i].script_name == name:
				children[-i].queue_free()
				children[-i].name = "DELETED_"+children[-1].name
				
func ws_obj(script, arguments):
	if not main.get_tree():
		return
	var obj:Node = Commands.create_object(
		script,
		"graphic",
		"res://System/Graphics/PWSprite.gd",
		[Commands.SPRITE_GROUP],
		arguments
	)
	
func ws_gui(script, arguments):
	if not main.get_tree():
		return
	var guitype = arguments.pop_front()
	if guitype.to_lower() == "button":
		var macroname = arguments.pop_front()
		var spl = Commands.keywords(arguments, true)
		var kw = spl[0]
		var args = spl[1]
		var text = PoolStringArray(args).join(" ")
		var button = Commands.create_object(
			script, 
			"gui", 
			"res://System/UI/IButton.gd", 
			[Commands.SPRITE_GROUP],
			arguments
		)
		button.menu = self
		button.button_name = macroname
func click_option(option):
	Commands.call_macro(Commands.is_macro(option), main.stack.scripts[-1], [])
	
func ws_bg(script, arguments):
	if not main.get_tree():
		return
	if not "stack" in arguments:
		main.get_tree().call_group(Commands.CLEAR_GROUP, "queue_free")
	var bg:Node = Commands.create_object(script, "bg", "res://System/Graphics/PWSprite.gd", 
	[Commands.SPRITE_GROUP, Commands.BG_GROUP, Commands.CLEAR_GROUP], arguments)
	
func ws_fg(script, arguments):
	if not main.get_tree():
		return
	var fg:Node = Commands.create_object(script, "fg", "res://System/Graphics/PWSprite.gd", 
	[Commands.SPRITE_GROUP, Commands.FG_GROUP, Commands.CLEAR_GROUP], arguments)

func ws_char(script, arguments):
	if not main.get_tree():
		return
	# If we don't "stack" then delete existing character
	if not "stack" in arguments and not "hide" in arguments:
		main.get_tree().call_group(Commands.CHAR_GROUP, "queue_free")
	var character = Commands.create_object(
		script,
		"portrait", 
		"res://System/Graphics/PWChar.gd",
		[Commands.CHAR_GROUP, Commands.SPRITE_GROUP, Commands.CLEAR_GROUP],
		arguments
	)
	if "hide" in arguments:
		character.visible = false
		main.get_tree().call_group(Commands.HIDDEN_CHAR_GROUP, "queue_free")
		character.add_to_group(Commands.HIDDEN_CHAR_GROUP)
	main.stack.variables.set_val("_speaking", character.char_name)
	
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
		characters = Commands.get_speaking_char()
	else:
		characters = Commands.get_objects(name, false, Commands.CHAR_GROUP)
	if characters:
		characters[0].load_emotion(emotion)
		if mode:
			characters[0].play_state(mode)

func ws_ev(script, arguments):
	var ev = Commands.create_object(
		script,
		"evidence",
		"res://System/Graphics/PWEvidence.gd",
		[Commands.SPRITE_GROUP, Commands.CLEAR_GROUP],
		arguments
	)

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
		if not (damage_amount or threat):
			delay = 0
	main.get_tree().call_group(Commands.PENALTY_GROUP, "queue_free")
	var penalty = Commands.create_object(script, "penalty", "res://System/UI/Penalty.gd", 
		[Commands.SPRITE_GROUP, Commands.PENALTY_GROUP], ["name=penalty"])
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
