extends Node2D

var main
var nametag := ""
var text_to_print := ""
var tb_lines := 3
var created_packs = false
var packs := []
var printed := ""
var printed_lines:Array = []
var has_finished := false
var wait_signal := "tree_exited"

# If there are more packs, when we continue the text, we should show those instead
var next_packs := []
var NEW_TEXTBOX_WIDTH = 10

export(NodePath) var tb_timer
export(NodePath) var text_label_path
onready var text_label:RichTextLabel = get_node(text_label_path)
var z:int

# states while printing
var center = false
var diffcolor = false
var lastspeed = null
var in_paren = ""

var last_speaking_character = null
var last_speaking = ""

var characters_per_update:float = 1.0
var ticks_per_update:float = 2.0
var next_ticks_per_update:float = 1.0
var override_sound = null
var wait_mode = "auto"   
# auto - character delay is at full speed for normal characters and half speed for punctuation
# manual - character delay is always at full speed

var last_text_sound_played = 0.0
var text_sound_rate = 0.04

# Signal that we may need to refresh the arrows
var refresh_arrows_on_next_pack = false

var nt_left_sprite = null
var nt_middle_sprite = null
var nt_right_sprite = null
var nt_sprite = null

var MAX_WHILE = 400
signal run_returned

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
		return null
		
	# add all text to label, then increase visible characters each frame
	# if characters per frame is INF, will print text immediately
	func _print_text(dt:float, force):
		print("BUILDING TEXT FOR PACK", text)
		var rich_text_label = textbox.text_label
		if leftover == null:
			rich_text_label.bbcode_text += self.text
			#textbox.printed += self.text
			leftover =  self.textbox.strip_bbcode(self.text).length()
		
		var delta # Number of characters to add to the display
		var while_loops = 0
		while (not delta or delta > 1 and leftover) and while_loops < textbox.MAX_WHILE:
			if not textbox.is_processing() and not force:
				return
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
			rich_text_label.visible_characters += delta
			print("last delta:", delta)
			leftover -= delta
			if delta >= 1:
				emit_signal("text_printed")
			# TODO this is pretty hacky - Textbox really needs another rewrite
			var t = self.textbox.strip_bbcode(self.textbox.printed)
			if t:
				var c = t[min(rich_text_label.visible_characters-1,t.length()-1)]
				textbox.process_text_character(c)
			if force or characters_per_tick <= 0.01:
				break
		if while_loops >= textbox.MAX_WHILE:
			pass
			
	# execute pack command and change the provided textbox accordingly
	func consume(dt:float, force = false):
		var run_return
		if not has_run:
			run_return = self._run(force)
		if run_return:
			if run_return is GDScriptFunctionState:
				run_return = yield(run_return, "completed")
			self.text = run_return + self.text
		_print_text(dt, force)
		if not leftover or leftover <= 0: self.delete = true
		# figure out how much to print here
		
	func duplicate():
		var p = get_script().new(text, textbox, true)
		p.text = text
		p.textbox = textbox
		p.leftover = leftover
		p.has_run = has_run
		p.characters_per_frame = characters_per_frame
		p.delete = false
		p.time_elapsed = time_elapsed
		return p
		

class CommandPack extends TextPack:
	var command_args := ""
	var command
	var args = []
	var matched_text = false
	
	func _init(line, textbox, connect_signals=false).(line, textbox, connect_signals):
		self.command_args = line
		self.textbox = textbox
		self.parse_command()
		self.text = _to_text(self.textbox)
		
	func parse_command():
		# parse pack text
		var args
		# First read macro with arguments to see if it is a command
		args = Array(self.command_args.split(" "))
		if Commands.is_macro_or_command(args[0]):
			self.command = args[0]
			self.args = args.slice(1,args.size())
			return
		args = []
		for command in [
			"sfx", "sound", "delay", "spd", "_fullspeed", "_endfullspeed",
			"wait", "center", "type", "next", "tbon", "tboff", 
			"e", "f", "s", "p", "c", "$"
		]:
			# TODO because of single letter items, we may not allow macros that start with those letters
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
				matched_text = true
			"center":
				if not tb.center:
					ret = "[center]"
				else:
					ret = "[/center]"
				self.textbox.center = not tb.center
				matched_text = true
			"c":
				if tb.diffcolor:
					ret = "[/color]"
				if not args:
					tb.diffcolor = false
				else:
					ret = "[color=#"+Colors.string_to_hex(args[0])+"]"
					tb.diffcolor = true
				matched_text = true
			"$":
				var packs = tb.tokenize_text(tb.main.stack.variables.get_string(args[0]))
				for p in packs:
					ret += p.text
				matched_text = true
		return ret
		
	
	# executed during typing: speed change, animations, sounds, etc
	# TODO finish execute markup base commands
	# TODO execute macros
	func _run(force = false):
		var args = self.args
		var run_return = null
		if matched_text:
			has_run = true
			return null
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
				if not force:
					textbox.ticks_per_update = 5 * float(args[0])
					textbox.wait_mode = "manual"
			"spd":
				# Set to 0 to make text print instantly
				# Set to anything else as the number of characters per UPDATE
				# default 1
				# -> characters_per_update
				if not force:
					textbox.characters_per_update = float(args[0])
			# Mainly intended to be a way for a macro running inside a textbox to return to the textbox
			# and print out the text again.
			# TODO Might be able to deprecate fullspeed and endfullspeed
			"_fullspeed":
				if not force:
					textbox.lastspeed = textbox.characters_per_update
					textbox.characters_per_update = 0.0   # will force speed to be instant
			"_endfullspeed":
				if not force:
					if textbox.lastspeed != null:
						textbox.characters_per_update = textbox.lastspeed
			"wait":  # set wait mode to auto or manual
				if not force:
					if args[0] in ["auto","manual"]:
						textbox.wait_mode = args[0]
			"type":
				textbox.override_sound = "typewriter.ogg"
				textbox.ticks_per_update = 10
				textbox.wait_mode = "manual"
			"next":
				self.textbox.queue_free()
			"f":
				Commands.call_command("flash", self.textbox.main.top_script(), args)
			"s":
				Commands.call_command("shake", self.textbox.main.top_script(), args)
			"p":
				if not force:
					self.textbox.pause(args, self)
			_:
				self.textbox.refresh_arrows_on_next_pack = true
				var old_script = self.textbox.main.top_script()
				Commands.call_command(self.command, old_script, args)
				
				# TODO macros in text is still very broken
				#textbox.set_process(false)
				#while self.textbox.main.top_script() != old_script:
				#	yield(self.textbox.get_tree(), "idle_frame")
				#textbox.set_process(true)
				#run_return = self.textbox.main.stack.variables.get_string("_return", "")
				#self.textbox.main.stack.variables.del_val("_return")
		has_run = true
		return run_return
		
func _on_text_printed():
	printed = text_label.text.substr(0,text_label.visible_characters+1)
	if not printed:
		return
	print(printed)
	print(text_label.get_visible_line_count())
	print(text_label.get_content_height())
	if printed[-1] == "&":
		pass
	printed_lines = printed.split("\n")
	if printed_lines.size() > 2:
		if printed_lines.size() > 3 or (printed_lines.size() == 3 and get_number_of_lines_for(printed_lines[2]) > 1):
			queue_next_textbox()
	elif printed_lines.size() == 2:
		if get_number_of_lines_for(printed_lines[1]) > 2:
			queue_next_textbox()
	elif printed_lines.size() == 1:
		if get_number_of_lines_for(printed_lines[0]) > 3:
			queue_next_textbox()
	if Time.get_ticks_msec()-last_text_sound_played > text_sound_rate * 1000:
		play_sound()
		last_text_sound_played = Time.get_ticks_msec()
		
func get_number_of_lines_for(text):
	var width_checker = get_node("WidthChecker")
	width_checker.text = text
	return int(width_checker.get_content_height()/15)
		
func queue_next_textbox():
	next_packs = []
	for line in printed_lines.slice(3, printed_lines.size()):
		next_packs.append(TextPack.new(line, self, true))
	for pack in packs:
		next_packs.append(pack.duplicate())
	# TODO even bigger hack on determining size of text
	if printed_lines.size() < 4:
		print("leftover start:", next_packs[0].text.substr(next_packs[0].text.length()-next_packs[0].leftover, -1))	
		var last_char = printed_lines[-1][-1]
		print("last_char:", last_char)
		var offset = 0
		# Don't know why this here
		next_packs[0].leftover -= 1
		#Back up how much was printed on the previous line
		var break_on_spaces = true
		if not " " in next_packs[0].text.substr(next_packs[0].text.length()-next_packs[0].leftover, -1):
			break_on_spaces = false
		while get_number_of_lines_for(PoolStringArray(printed_lines).join("\n")) > 3 or last_char != " ":
			last_char = printed_lines[-1][-1]
			if not break_on_spaces:
				last_char = " "
			printed_lines[-1] = printed_lines[-1].substr(0, printed_lines[-1].length()-1)
			print("break_on_spaces", break_on_spaces, " last_char:", last_char, " printed_lines[-1]", printed_lines[-1])
			next_packs[0].leftover += 1
			print("leftover:", next_packs[0].text.substr(next_packs[0].text.length()-next_packs[0].leftover, -1))
	#next_lines = [carryover]
	if next_packs[0].leftover:
		next_packs[0].text = next_packs[0].text.substr(next_packs[0].text.length()-next_packs[0].leftover, -1)
	next_packs[0].leftover = null
	packs = []
	has_finished = true
		
func process_text_character(c):
	var punctuation = main.stack.variables.get_string("_punctuation")
	if c and not in_paren:
		_set_speaking_animation("talk")
	if c == " ":
		next_ticks_per_update = 0.1
	elif c in punctuation and wait_mode == "auto":
		next_ticks_per_update = 2.0
	elif c in "([":
		_set_speaking_animation("blink")
		in_paren = c
	elif c in "])":
		_set_speaking_animation("talk")
		in_paren = ""
	else:
		next_ticks_per_update = 1.0
	visible = true

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
	var font_tb_name = "fonts/"+main.stack.variables.get_string("_font_tb","pwinternational.ttf")
	var font_tb_size = main.stack.variables.get_int("_font_tb_size",10)
	var font_nt_name = "fonts/"+main.stack.variables.get_string("_font_nt","arial.ttf")
	var font_nt_size = main.stack.variables.get_int("_font_nt_size",10)
	var font = main.font_cache.get_cached([font_tb_name, font_tb_size])
	var font_nt = main.font_cache.get_cached([font_nt_name, font_nt_size])
	if not font:
		font_tb_name = Filesystem.lookup_file(
			font_tb_name, 
			main.top_script().root_path
		)
		font = DynamicFont.new()
		font.use_filter = true
		font.use_mipmaps = true
		font.font_data = load(font_tb_name)
		font.size = font_tb_size
		#font.set_spacing(DynamicFont.SPACING_SPACE, -2)
	if not font_nt:
		font_nt_name = Filesystem.lookup_file(
			font_nt_name, 
			main.top_script().root_path
		)
		font_nt = DynamicFont.new()
		font_nt.use_filter = true
		font_nt.use_mipmaps = true
		font_nt.font_data = load(font_nt_name)
		font_nt.size = font_nt_size
		#font_nt.set_spacing(DynamicFont.SPACING_SPACE, -2)
	
	tb_timer = get_node(tb_timer)
	tb_timer.one_shot = true
	
	if main.stack.variables.get_truth("_textbox_skipupdate",false):
		wait_signal = ""
	if not main:
		return
		
	#connect("tree_exited", Commands, "hide_arrows", [main.stack.scripts[-1]])

	get_node("%NametagLabel").text = ""
	get_node("%TextLabel").bbcode_text = ""
	var tb_lines_var = StandardVar.TEXTBOX_LINES.retrieve()
	if tb_lines_var == "auto":
		tb_lines = text_to_print.count("{n}")
	else:
		tb_lines = int(tb_lines_var)
	if tb_lines < 3:
		get_node("%TextLabel").margin_bottom = 14
		get_node("%TextLabel").set("custom_constants/line_separation", 8)
	get_node("%TextLabel").set("custom_fonts/normal_font", font)
	$WidthChecker.set("custom_fonts/normal_font", font)
	get_node("%NametagLabel").set("custom_fonts/font", font_nt)
	z = ZLayers.z_sort["textbox"]
	add_to_group(Commands.TEXTBOX_GROUP)

	var alter_x = StandardVar.TEXTBOX_X.retrieve()
	var alter_y = StandardVar.TEXTBOX_Y.retrieve()
	if alter_x != null:
		get_node("%Handle").position.x = alter_x
	if alter_y != null:
		get_node("%Handle").position.y = alter_y

	var nt_backdrop = get_node("%NametagBackdrop")
	var alter_nt_x = StandardVar.NT_X.retrieve()
	var alter_nt_y = StandardVar.NT_Y.retrieve()
	if alter_nt_x != null:
		nt_backdrop.position.x = alter_nt_x - get_node("%Handle").position.x
	if alter_nt_y != null:
		nt_backdrop.position.y = alter_nt_y - get_node("%Handle").position.y

	var alter_nt_text_x = StandardVar.NT_TEXT_X.retrieve()
	var alter_nt_text_y = StandardVar.NT_TEXT_Y.retrieve()
	if alter_nt_text_x != null:
		get_node("%NametagLabel").rect_position.x = alter_nt_text_x
	if alter_nt_text_y != null:
		get_node("%NametagLabel").rect_position.y = alter_nt_text_y

	update_nametag()
		
	Commands.refresh_arrows(main.stack.scripts[-1])

func update_nametag():
	var nt_image = main.stack.variables.get_string("_nt_image", null)
	if nt_image and not nt_sprite:
		get_node("%NametagBackdrop").visible = false
		nt_sprite = ObjectFactory.create_from_template(
			main.top_script(),
			"graphic",
			{},
			[nt_image],
			null
		)
		nt_sprite.cannot_save = true
		nt_sprite.get_parent().remove_child(nt_sprite)
		get_node("%NametagImage").add_child(nt_sprite)
		nt_sprite.position = Vector2(0,0)
		return
	# Lookup character name 
	var nametag = main.stack.variables.get_string("_speaking_name")
	if not nametag:
		get_node("%NametagBackdrop").visible = false
	else:
		get_node("%NametagLabel").text = nametag
		get_node("%NametagBackdrop").visible = true
		update_nametag_size()
	
func update_nametag_size():
	var label = get_node("%NametagLabel")
	var size = label.get_font("font").get_string_size(label.text)
	size.x += 10
	if not nt_left_sprite:
		nt_left_sprite = ObjectFactory.create_from_template(
			main.top_script(),
			"graphic",
			{},
			[main.stack.variables.get_string(
				"_nt_left",
				main.stack.variables.get_string("_nt_image_left", "general/nt_left")
			)],
			get_node("%NametagBackdrop")
		)
		nt_left_sprite.cannot_save = true
		nt_left_sprite.position = Vector2(0,0)
	if not nt_middle_sprite:
		nt_middle_sprite = ObjectFactory.create_from_template(
			main.top_script(),
			"graphic",
			{},
			[main.stack.variables.get_string(
				"_nt_middle",
				main.stack.variables.get_string("_nt_image_middle", "general/nt_middle")
			)],
			get_node("%NametagBackdrop")
		)
		nt_middle_sprite.cannot_save = true
		nt_middle_sprite.position = Vector2(nt_left_sprite.width-1+int(size.x/2),0)
		nt_middle_sprite.scale.x = size.x
	if not nt_right_sprite:
		nt_right_sprite = ObjectFactory.create_from_template(
			main.top_script(),
			"graphic",
			{},
			[main.stack.variables.get_string(
				"_nt_right",
				main.stack.variables.get_string("_nt_image_right", "general/nt_right")
			)],
			get_node("%NametagBackdrop")
		)
		nt_right_sprite.cannot_save = true
		nt_right_sprite.position = Vector2(nt_middle_sprite.position.x+int(size.x/2),0)
	get_node("%NametagBackdrop").move_child(get_node("%NametagLabel"), get_node("%NametagBackdrop").get_child_count()-1)
		
func stop_timer():
	set_process(true)
	tb_timer.disconnect("timeout", self, "stop_timer")
		
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
	reset_statement()
	
func finish_text():
	var while_loops = 0
	while (not created_packs or packs) and while_loops < MAX_WHILE:
		update_textbox(0, true)
	if while_loops >= MAX_WHILE:
		pass
			
func click_continue(immediate_skip=false):
	if not has_finished and not main.stack.variables.get_truth("_textbox_allow_skip", false):
		return
	if not immediate_skip and packs:
		finish_text()
	else:
		if next_packs:
			packs = next_packs
			has_finished = false
			#var new_text_label = RichTextLabel.new()
			#new_text_label.bbcode_enabled = true
			#text_label.get_parent().add_child(new_text_label)
			#new_text_label.rect_position = text_label.rect_position
			#new_text_label.rect_position = text_label.rect_position
			#text_label.queue_free()
			#new_text_label.visible_characters = 0
			#text_label = new_text_label
			text_label.bbcode_text = ""
			text_label.visible_characters = 0
			printed = ""
			printed_lines = []
			next_packs = []
			return false
		# when we advance text from script we:
		# - click_continue
		# - but if we only queue_free, it will block the script until a later frame
		# - which means the script will process removing objects before new objects are created
		# - So we force it to be removed from the tree which will signal to unblock the script
		clean_up()
		get_parent().remove_child(self)
		queue_free()
		Commands.call_command("sound_textbox_continue", main.stack.scripts[0], [])
	return true
		
func click_next():
	if click_continue(true):
		main.stack.scripts[-1].next_statement()

func click_prev():
	if click_continue(true):
		main.stack.scripts[-1].prev_statement()
		
func get_next_pack(text, connect_signals=false):
	var i = 0
	var pack = ""
	var found_bracket = false
	var while_loops = 0
	while (i < text.length() and while_loops < MAX_WHILE):
		var c = text[i]
		pack += c
		if not found_bracket and i == 0 and c == '{':
			found_bracket = true
			i += 1
			continue
		if found_bracket and i != 0 and c == '}':
			return [CommandPack.new(pack.substr(1, pack.length()-2), self, connect_signals),text.substr(i+1)]
		if not found_bracket and i > 0 and c == '{':
			return [TextPack.new(pack.left(pack.length()-1), self, connect_signals),text.substr(i)]
		i += 1
	if while_loops >= MAX_WHILE:
		pass
	return [TextPack.new(pack, self, connect_signals), ""]
	


func tokenize_text(text, connect_signals=false):
	var next_pack
	var packs = []
	var v = get_next_pack(text, connect_signals)
	next_pack = v[0]
	text = v[1]
	var while_loops = 0
	while text and while_loops < MAX_WHILE:
		while_loops += 1
		packs.append(next_pack)
		v = get_next_pack(text, connect_signals)
		next_pack = v[0]
		text = v[1]
	if while_loops >= MAX_WHILE:
		pass
	packs.append(next_pack)
	return packs

func _set_speaking_animation(name):
	var character = Commands.get_speaking_char()
	if character != last_speaking_character:
		last_speaking_character = character
		last_speaking = ""
	if name != last_speaking:
		last_speaking = name
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
	if not packs and not created_packs:
		packs = tokenize_text(text_to_print, true)
		text_label.visible_characters = 0
		created_packs = true
		Commands.refresh_arrows(main.stack.scripts[-1])
	if packs:
		if refresh_arrows_on_next_pack:
			Commands.refresh_arrows(main.stack.scripts[-1])
			refresh_arrows_on_next_pack = false
		packs[0].consume(dt, force)
		if packs and packs[0].delete:
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
	update_arrows(true)
		
func update_arrows(disable_click=null):
	var arrow = Commands.get_objects("_main_button_arrow")
	var button = Commands.get_objects("_main_button_fg")
	if not arrow or not button:
		return
	if disable_click==null:
		if not has_finished:
			disable_click=true
		else:
			disable_click=false
	if disable_click:
		if not main.stack.variables.get_truth("_textbox_allow_skip", false):
			arrow[0].visible = false
			if button[0].click_area:
				button[0].click_area.enabled = false
	else:
		arrow[0].visible = true
		if button[0].click_area:
			button[0].click_area.enabled = true

func reset_statement():
	main.stack.variables.del_val("_in_statement")
		
func _process(dt):
	update_nametag()
	update_textbox(dt)
	update_arrows()


# SAVE/LOAD
var save_properties = [
	"text_to_print",
	"z",
	"characters_per_update",
	"ticks_per_update",
	"override_sound"
]
func save_node(data):
	data["loader_class"] = "res://System/UI/Textbox.gd"

static func create_node(saved_data:Dictionary):
	var ob = load("res://System/UI/Textbox.tscn").instance()
	ob.text_to_print = saved_data["text_to_print"]
	return ob
	
func load_node(tree, saved_data:Dictionary):
	main = tree.get_nodes_in_group("Main")[0]
	ScreenManager.top_screen().add_child(self)

func after_load(tree:SceneTree, saved_data:Dictionary):
	pass
