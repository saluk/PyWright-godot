extends Node2D

var main
var nametag := ""
var text_to_print := ""
var packs := []
var printed := ""
var wait_signal := "tree_exited"
export(NodePath) var tb_timer
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
	var characters_per_frame = 1
	var leftover
	var delete = false
	func _init(text, textbox):
		self.type = TEXT_PACK
		self.text = text
		self.textbox = textbox

	# add all text to label, then increase visible characters each frame
	func consume(rich_text_label, force = false):
		if leftover == null:
			rich_text_label.bbcode_text += self.text
			leftover =  self.textbox.strip_bbcode(self.text).length()
		var delta = min(characters_per_frame, leftover)
		rich_text_label.visible_characters += delta
		leftover -= delta
		if leftover == 0:
			self.delete = true

class Pack:
	var type = COMMAND_PACK
	var text := ""
	var args = []
	var textbox
	var cache = ""
	var delete = false
	func _init(text, textbox):
		self.text = text
		self.textbox = textbox
		self.textbox.parse_command(self)
		self.cache = _to_text(self.textbox)
		
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
	
	# override to do arbitrary things to rich_text_label at runtime. 
	# by default, we append the cached output of _to_text
	func print_text(rich_text_label):
		rich_text_label.bbcode_text += self.cache
		var visible = self.textbox.strip_bbcode(self.cache).length()
		rich_text_label.visible_characters += visible
		
	# execute pack command and change the provided textbox accordingly
	func consume(rich_text_label, force = false):
		self.run(force)
		print_text(rich_text_label)
		
	
	# executed during typing: speed change, animations, sounds, etc
	# TODO finish execute markup base commands
	# TODO execute macros
	func run(force = false):
		self.delete = true
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
				if not force:
					self.textbox.pause(args, self)
					self.delete = false


# Called when the node enters the scene tree for the first time.
func _ready():
	tb_timer = get_node(tb_timer)
	tb_timer.one_shot = true
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
		
func stop_timer(pack):
	packs.remove(0)
		
func pause(args, pack):
	if tb_timer.is_stopped():
		tb_timer.connect("timeout", self, "stop_timer", [pack])
		tb_timer.start()

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		click_continue()
		
func queue_free():
	Commands.hide_arrows(main.stack.scripts[-1])
	.queue_free()
			
func click_continue(immediate_skip=false):
	if not immediate_skip and (text_to_print or packs):
		while text_to_print or packs:
			update_textbox(true)
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

func _set_speaking_animation(name):
	for character in Commands.get_speaking_char():
		character.play_state("talk")
		
func strip_bbcode(source:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	var ret = regex.sub(source, "", true)
	regex = RegEx.new()
	regex.compile("[\n\t]")
	ret = regex.sub(ret, "", true)
	return ret

func update_textbox(force = false):
	update_nametag()
	if not packs and text_to_print:
		packs = tokenize_text(text_to_print)
		$Backdrop/Label.visible_characters = 0
		text_to_print = ""
	if packs:
		_set_speaking_animation("talk")
		packs[0].consume($Backdrop/Label, force)
		if packs[0].delete:
			packs.remove(0)
	else:
		_set_speaking_animation("blink")
		
func _process(dt):
	update_textbox()
