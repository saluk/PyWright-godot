extends Node2D

var main
var nametag := ""
var text_to_print := ""
var packs := []
var printed := ""
var has_finished := false
var wait_signal := "tree_exited"
export(NodePath) var tb_timer
var z:int

# states while printing
var center = false
var diffcolor = false

var characters_per_update:float = 1.0
var ticks_per_update:float = 2.0
var next_ticks_per_update:float = 1.0
var override_sound = null

var last_text_sound_played = 0.0
var text_sound_rate = 0.2

var MAX_WHILE = 400

class TextPack:
	var text = ""
	var textbox
	var leftover
	var has_run = false
	var characters_per_frame = 1
	var delete = false
	var time_elapsed = 0.0
	signal text_printed
	
	func _init(text, textbox, connect_signals=false):
		self.text = text
		self.textbox = textbox
		if connect_signals:
			self.connect("text_printed", self.textbox, "_on_text_printed")
		
	func _run(force = false): 
		has_run = true
		
	# add all text to label, then increase visible characters each frame
	# if characters per frame is INF, will print text immediately
	func _print_text(dt:float, rich_text_label, force):
		if leftover == null:
			rich_text_label.bbcode_text += self.text
			textbox.printed += self.text
			leftover =  self.textbox.strip_bbcode(self.text).length()
		
		var delta # Number of characters to add to the display
		var while_loops = 0
		while (not delta or delta > 1 and leftover) and while_loops < textbox.MAX_WHILE:
			while_loops += 1
			var characters_per_tick = float(textbox.characters_per_update) / float(textbox.ticks_per_update * textbox.next_ticks_per_update)
			if characters_per_tick < 0.01 or force:
				delta = leftover
			else:
				var characters_per_second = characters_per_tick * 60.0
				
				time_elapsed += dt
				delta = time_elapsed * characters_per_second
				if delta < 1:
					return
				delta = int(delta)
				delta = 1
				time_elapsed -= delta/characters_per_second

			emit_signal("text_printed")
			rich_text_label.visible_characters += delta
			leftover -= delta
			# TODO this is pretty hacky - Textbox really needs another rewrite
			var t = self.textbox.strip_bbcode(self.textbox.printed)
			if t and t[min(rich_text_label.visible_characters-1,t.length()-1)] == " ":
				textbox.next_ticks_per_update = 0.1
			else:
				textbox.next_ticks_per_update = 1.0
			if t:
				textbox.visible = true
			if force or characters_per_tick <= 0.01:
				break
		if while_loops >= textbox.MAX_WHILE:
			pass
			
	# execute pack command and change the provided textbox accordingly
	func consume(rich_text_label, dt:float, force = false):
		if not has_run:
			self._run(force)
		_print_text(dt, rich_text_label, force)
		if not leftover or leftover <= 0: self.delete = true

class CommandPack extends TextPack:
	var command_args := ""
	var command
	var args = []
	
	func _init(line, textbox, connect_signals=false).(line, textbox, connect_signals):
		self.command_args = line
		self.textbox = textbox
		self.parse_command()
		self.text = _to_text(self.textbox)
		
	func parse_command():
		# parse pack text
		var args
		for command in [
			"sfx", "sound", "delay", "spd", "_fullspeed", "_endfullspeed",
			"wait", "center", "type", "next", "tbon", "tboff", 
			"e", "f", "s", "p", "c", "$"
		]:
			if self.command_args.begins_with(command):
				args = self.command_args.substr(command.length()).strip_edges()
				if args:
					args = args.split(" ")
				else:
					args = []
				self.command = command
				self.args = args
				return
		print("command not found:", self.command_args)
		command = command_args
		
	# text-only changes. Resolved before typing: variables, bbcode
	func _to_text(tb):
		var ret = ""
		match self.command:
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
				var packs = tb.tokenize_text(tb.main.stack.variables.get_string(args[0]))
				for p in packs:
					ret += p.text
		return ret
		
	
	# executed during typing: speed change, animations, sounds, etc
	# TODO finish execute markup base commands
	# TODO execute macros
	func _run(force = false):
		var args = self.args
		match self.command:
			"e":
				Commands.call_command("emo", self.textbox.main.top_script(), args)
			"sfx":
				textbox.play_sound(args[0])
			"sound":
				textbox.override_sound = ""
				if args and args[0].strip_edges():
					textbox.override_sound = args[0]
			"delay":
				# the number of frames between UPDATE
				# default 2
				# MULTIPLIED by punctuation delays
				# -> ticks_per_update
				# ALSO sets wait mode to manual, which makes actual delay 5 times what was set
				textbox.ticks_per_update = 5 * float(args[0])
				print(textbox.ticks_per_update)
			"spd":
				# Set to 0 to make text print instantly
				# Set to anything else as the number of characters per UPDATE
				# default 1
				# -> characters_per_update
				textbox.characters_per_update = float(args[0])
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
			"e":
				pass
			"f":
				Commands.call_command("flash", self.textbox.main.top_script(), args)
			"s":
				Commands.call_command("shake", self.textbox.main.top_script(), args)
			"p":
				if not force:
					self.textbox.pause(args, self)
			_:
				Commands.call_command(self.command, self.textbox.main.top_script(), args)
		has_run = true
		
func _on_text_printed():
	if Time.get_ticks_msec()-last_text_sound_played > text_sound_rate:
		play_sound()
		last_text_sound_played = Time.get_ticks_msec()

func play_sound(path=null):
	if path == null:
		path = get_char_sound()
		if override_sound != null:
			path = override_sound
	if path and path.strip_edges():
		Commands.call_command("sfx", main.top_script(), [path])

var DEFAULT_SOUNDS = {
	"blipmale.ogg": "4judge acro apollo armando armstrong atmey ben brother cody daian edgeworth edgeworthDA edgeworth-young ese gant godot grey grossberg grossberg-young gumshoe gumshoe-young hamigaki hobo hotti jake judge kagerou karma kawadzu killer kirihito kyouya kyouya-young larry maki matt max meekins moe mugitsura payne paynette payne-young phoenix phoenix-young redd romaine ron sahwit sal takita terry tigre tsunekatsu varan varan-young victor wellington will yanni zakku".split(" "),
	"blipfemale.ogg": "adrian angel april bikini dahlia dee desiree elise ema franziska ini iris koume lamiroir lana lisa lotta maggey makoto makoto-young masaka maya mia mia-young minami minuki minuki-young morgan oldbag pearl penny regina skye viola yuumi".split(" ")
}
func get_char_sound():
	var character = Commands.get_speaking_char()
	var blipsound = null
	if character:
		blipsound = main.stack.variables.get_string(
			"char_"+character.base_path+"_defsound")
		if not blipsound:
			for key in DEFAULT_SOUNDS:
				if character.base_path in DEFAULT_SOUNDS[key]:
					blipsound = key
	if not blipsound:
		blipsound = main.stack.variables.get_string(
			"char_defsound")
	if not blipsound:
		blipsound = "blipmale.ogg"
	return blipsound

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	var font_path = "res://fonts/pwinternational.ttf"
	var font = DynamicFont.new()
	font.font_data = load(font_path)
	font.size = 10
	font.set_spacing(DynamicFont.SPACING_SPACE, -2)
	
	tb_timer = get_node(tb_timer)
	tb_timer.one_shot = true
	if not main:
		return
		
	connect("tree_exited", Commands, "hide_arrows", [main.stack.scripts[-1]])

	$NametagBackdrop/Label.text = ""
	$Backdrop/Label.bbcode_text = ""
	if main.stack.variables.get_int("_textbox_lines", 3) == 2:
		$Backdrop/Label.margin_bottom = 14
		$Backdrop/Label.set("custom_constants/line_separation", 8)
	$Backdrop/Label.set("custom_fonts/normal_font", font)
	z = ZLayers.z_sort["textbox"]
	add_to_group(Commands.TEXTBOX_GROUP)
	Commands.refresh_arrows(main.stack.scripts[-1])
	update_nametag()
	
	# Debug mode immediately prints text
	if main.stack.variables.get_truth("_debug", false):
		finish_text()

func update_nametag():
	# Lookup character name
	var nametag = main.stack.variables.get_string("_speaking_name")
	if not nametag:
		$NametagBackdrop.visible = false
	else:
		$NametagBackdrop/Label.text = nametag
		$NametagBackdrop.visible = true
	update_nametag_size()
	
func update_nametag_size():
	var label = $NametagBackdrop/Label
	var size = label.get_font("font").get_string_size(label.text)
	size.x += 10
	$NametagBackdrop/NtMiddle.position.x = int(size.x/2)+2
	$NametagBackdrop/NtMiddle.scale.x = size.x
	$NametagBackdrop/NtRight.position.x = $NametagBackdrop/NtMiddle.position.x+int(size.x/2)
		
func stop_timer():
	set_process(true)
	tb_timer.disconnect("timeout", self, "stop_timer")
	_set_speaking_animation("talk")
		
func pause(args, pack):
	_set_speaking_animation("blink")
	set_process(false)
	tb_timer.wait_time = float(args[0])/60.0
	tb_timer.connect("timeout", self, "stop_timer")
	tb_timer.start()

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		click_continue()
		
func queue_free():
	clean_up()
	.queue_free()
	
func clean_up():
	trigger_text_end_events()
	# TODO we could check whether tboff needs to be called or not
	# In pywright, it's only called when _tb_on is true
	Commands.call_command("tboff", main.top_script(), [])
	
func finish_text():
	var while_loops = 0
	while (text_to_print or packs) and while_loops < MAX_WHILE:
		update_textbox(0, true)
	if while_loops >= MAX_WHILE:
		pass
			
func click_continue(immediate_skip=false):
	if not immediate_skip and (text_to_print or packs):
		finish_text()
	else:
		# when we advance text from script we:
		# - click_continue
		# - but if we only queue_free, it will block the script until a later frame
		# - which means the script will process removing objects before new objects are created
		# - So we force it to be removed from the tree which will signal to unblock the script
		clean_up()
		get_parent().remove_child(self)
		
func click_next():
	main.stack.scripts[-1].next_statement()
	click_continue(true)

func click_prev():
	main.stack.scripts[-1].prev_statement()
	click_continue(true)
		
func get_next_pack(text_to_print, connect_signals=false):
	var i = 0
	var pack = ""
	var found_bracket = false
	var while_loops = 0
	while (i < text_to_print.length() and while_loops < MAX_WHILE):
		var c = text_to_print[i]
		pack += c
		if not found_bracket and i == 0 and c == '{':
			found_bracket = true
			i += 1
			continue
		if found_bracket and i != 0 and c == '}':
			return [CommandPack.new(pack.substr(1, pack.length()-2), self, connect_signals),text_to_print.substr(i+1)]
		if not found_bracket and i > 0 and c == '{':
			return [TextPack.new(pack.left(pack.length()-1), self, connect_signals),text_to_print.substr(i)]
		i += 1
	if while_loops >= MAX_WHILE:
		pass
	return [TextPack.new(pack, self, connect_signals), ""]
	


func tokenize_text(text_to_print, connect_signals=false):
	var next_pack
	var packs = []
	var v = get_next_pack(text_to_print, connect_signals)
	next_pack = v[0]
	text_to_print = v[1]
	var while_loops = 0
	while text_to_print and while_loops < MAX_WHILE:
		while_loops += 1
		packs.append(next_pack)
		v = get_next_pack(text_to_print, connect_signals)
		next_pack = v[0]
		text_to_print = v[1]
	if while_loops >= MAX_WHILE:
		pass
	packs.append(next_pack)
	return packs

func _set_speaking_animation(name):
	var character = Commands.get_speaking_char()
	if character:
		character.set_sprite(name)
		
func strip_bbcode(source:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	var ret = regex.sub(source, "", true)
	regex = RegEx.new()
	regex.compile("[\n\t]")
	#ret = regex.sub(ret, "", true)
	return ret

func update_textbox(dt:float, force = false):
	if not packs and text_to_print:
		packs = tokenize_text(text_to_print, true)
		$Backdrop/Label.visible_characters = 0
		text_to_print = ""
	if packs:
		# TODO we shouldn't set talking until actually printing out text
		_set_speaking_animation("talk")
		packs[0].consume($Backdrop/Label, dt, force)
		if packs[0].delete:
			packs.remove(0)
	else:
		trigger_text_end_events()
			
func trigger_text_end_events():
	if not has_finished:
		has_finished = true
		# TODO Probably close enough to use "printed" which is already in bbcode format
		# PYWRIGHT used the text that still had markup {c}, {n} etc in the text
		main.stack.variables.set_val("_last_written_text", printed)
		_set_speaking_animation("blink")
		main.emit_signal("text_finished")
		
func _process(dt):
	update_nametag()
	update_textbox(dt)
