extends Node2D

var main
var nametag := ""
var text_to_print := ""
var packs := []
var printed := ""
var wait_signal := "tree_exited"
var z:int

# states while printing
var center = false
var diffcolor = false

enum {
	TEXT_PACK,
	COMMAND_PACK
}

class TextPack:
	var type
	var text
	var textbox
	func _init(text, textbox):
		self.type = TEXT_PACK
		self.text = text
		self.textbox = textbox
	func to_text():
		return self.text
	func run():
		pass
	

class Pack:
	var type = COMMAND_PACK
	var text := ""
	var args = []
	var textbox
	var cache
	func _init(text, textbox):
		self.text = text
		self.textbox = textbox
		self.textbox.parse_command(self)
		self.cache = _to_text(self.textbox)
	func to_text():
		return self.cache
	# text-only changes. Resolved before typing: variables, bbcode
	func _to_text(tb):
		var ret = ""
		match self.text:
			"n":
				ret = "\n"
			"center":
				if not tb.center:
					ret = "[center]"
				else:
					ret = "[/center]"
				self.textbox.center = not tb.center
			"c":
				if tb.diffcolor:
					ret = "[/color]"
				if not args:
					tb.diffcolor = false
				else:
					ret = "[color=#"+Colors.string_to_hex(args[0])+"]"
					tb.diffcolor = true
			"$":
				ret = tb.main.stack.variables.get_string(args[0])
		return ret
	# executed during typing: speed change, animations, sounds, etc
	func run():
		var args = self.args
		match self.text:
			"e":
				Commands.call_command("emo", self.textbox.main.top_script(), args)
				#update_emotion(args[0])
			"sfx":
				pass
			"sound":
				pass
			"delay":   # delay character printing for a time
				pass
			"spd":
				pass
			"_fullspeed":
				pass
			"_endfullspeed":
				pass
			"wait":  # set wait mode to auto or manual
				pass
			"type":
				pass
			"next":
				self.textbox.queue_free()
			"tbon":
				pass
			"tboff":
				pass
			"e":
				pass
			"f":
				pass
			"s":
				pass
			"p":
				pass
# Called when the node enters the scene tree for the first time.
func _ready():
	if not main:
		return
	$NametagBackdrop/Label.text = ""
	$Backdrop/Label.bbcode_text = ""
	if main.stack.variables.get_int("_textbox_lines", 3) == 2:
		$Backdrop/Label.margin_bottom = 14
		$Backdrop/Label.set("custom_constants/line_separation", 8)
	z = ZLayers.z_sort["textbox"]
	add_to_group(Commands.TEXTBOX_GROUP)
	Commands.refresh_arrows(main.stack.scripts[-1])
	update_nametag()

func update_nametag():
	# Lookup character name
	var nametag
	for character in Commands.get_speaking_char():
		nametag = main.stack.variables.get_string(
			"char_"+character.char_name+"_name", 
			character.char_name.capitalize()
		)
	if not nametag:
		$NametagBackdrop.visible = false
	else:
		$NametagBackdrop/Label.text = nametag
		$NametagBackdrop.visible = true
		
func update_emotion(emotion):
	for character in Commands.get_speaking_char():
		character.load_emotion(emotion)

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		click_continue()
		
func queue_free():
	Commands.hide_arrows(main.stack.scripts[-1])
	.queue_free()
			
func click_continue(immediate_skip=false):
	if not immediate_skip and (text_to_print or packs):
		while text_to_print or packs:
			_process(1)
	else:
		queue_free()
		
func click_next():
	main.stack.scripts[-1].next_statement()
	click_continue(true)

func click_prev():
	main.stack.scripts[-1].prev_statement()
	click_continue(true)
		
func get_next_pack(text_to_print):
	var i = 0
	var pack = ""
	var found_bracket = false
	while i < text_to_print.length():
		var c = text_to_print[i]
		pack += c
		if not found_bracket and i == 0 and c == '{':
			found_bracket = true
			i += 1
			continue
		if found_bracket and i != 0 and c == '}':
			return [Pack.new(pack.substr(1, pack.length()-2), self),text_to_print.substr(i+1)]
		if not found_bracket and i > 0 and c == '{':
			return [TextPack.new(pack.left(pack.length()-1), self),text_to_print.substr(i)]
		i += 1
	return [TextPack.new(pack, self), ""]
	
func parse_command(pack):
	# parse pack text
	var args
	for command in [
		"sfx", "sound", "delay", "spd", "_fullspeed", "_endfullspeed",
		"wait", "center", "type", "next", "tbon", "tboff", 
		"e", "f", "s", "p", "c", "$"
	]:
		if pack.text.begins_with(command):
			args = pack.text.substr(command.length()).strip_edges()
			if args:
				args = args.split(" ")
			else:
				args = []
			pack.text = command
			pack.args = args
			return pack
	print("command not found:", pack.text)
	return pack

func tokenize_text(text_to_print):
	var next_pack
	var packs = []
	var v = get_next_pack(text_to_print)
	next_pack = v[0]
	text_to_print = v[1]
	while text_to_print:
		packs.append(next_pack)
		v = get_next_pack(text_to_print)
		next_pack = v[0]
		text_to_print = v[1]
	packs.append(next_pack)
	return packs
	
func process_text_pack(pack):
	if pack.text.length()>0:
		var text_to_type = pack.text.substr(0,1)
		pack.text = pack.text.substr(1)
		return text_to_type
		
func _set_speaking_animation(name):
	for character in Commands.get_speaking_char():
		character.play_state("talk")
		
func strip_bbcode(source:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(source, "", true)
		
func consume_pack(pack):
	# if type = TEXT_PACK, reveal text
	# if type is COMMAND_PACK, execute the markup, then
	# show the output of pack.to_text()
	var text_to_type = ""
	var consume = false
	if pack.type == TEXT_PACK:
		text_to_type = process_text_pack(pack)
		if not text_to_type:
			consume = true
	elif pack.type == COMMAND_PACK:
		pack.run()
		text_to_type = pack.to_text()
		consume = true
	if text_to_type:
		# text is already in Label, we just need to display the characters
		$Backdrop/Label.visible_characters += strip_bbcode(text_to_type).length()
	return consume
	
func get_all_text(packs):
	var buffer = ""
	for pack in packs:
		buffer += pack.to_text()
	return buffer

func _process(dt):
	update_nametag()
	if not packs and text_to_print:
		packs = tokenize_text(text_to_print)
		# resolve the text to be printed right away 
		# to allow predictive text wrap
		$Backdrop/Label.visible_characters = 0
		$Backdrop/Label.bbcode_text = get_all_text(packs)
		text_to_print = ""
	if packs:
		_set_speaking_animation("talk")
		if consume_pack(packs[0]):
			packs.remove(0)
	else:
		_set_speaking_animation("blink")
