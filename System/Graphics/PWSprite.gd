extends Node2D
class_name PWSprite

var animated_sprite:AnimatedSprite
var sprite_path:String
var script_name:String
var z:int

var frames
var width:int = 1
var height:int = 1

var pivot_center = true  # Whether the pivot point for the sprite should be in the center (true) or upper left (false)

var wait = false   # Pause script until animation has finished playing
var wait_signal = "finished_playing"
var loaded = false
signal finished_playing
signal size_changed

var sound_frames = {}

# TODO needs to handle different animation modes, loop, once, and blink mode at minimum

func free_members():
	if animated_sprite and is_instance_valid(animated_sprite) and not animated_sprite.is_queued_for_deletion():
		animated_sprite.free()

func free():
	print("freeing pwsprite "+name)
	free_members()
	return .free()
	
func queue_free():
	print("queuing pwsprite "+name)
	free_members()
	return .queue_free()
	
func can_wait():
	return animated_sprite.frames.get_frame_count("default") > 1 and not animated_sprite.frames.get_animation_loop("default")
	
func set_wait(b):
	print(animated_sprite.frames.get_frame_count("default"))
	print(animated_sprite.frames.get_animation_loop("default"))
	if can_wait():
		wait = b
		return
	wait = false

# TODO implement remaining textfile commands
#for l in lines:
#    spl = l.split(" ")
#    if l.startswith("horizontal "): self.horizontal = int(spl[1])
#    if l.startswith("vertical "): self.vertical = int(spl[1])
#    if l.startswith("length "):
#        self.length = int(spl[1])
#        setlength = True
#    if l.startswith("loops "): self.loops = int(spl[1])
#    if l.startswith("sfx "):
#        self.sounds[int(spl[1])] = " ".join(spl[2:])
#    if l.startswith("offsetx "): self.offsetx = int(spl[1])
#    if l.startswith("offsety "): self.offsety = int(spl[1])
#    if l.startswith("framecompress "):
#        fc = l.replace("framecompress ","").split(",")
#        if len(fc)==1:
#            self.framecompress = [0,int(fc[0])]
#        else:
#            self.framecompress = [int(x) for x in fc]
#    if l.startswith("blinksplit "):
#        self.split = int(l.replace("blinksplit ",""))
#    if l.startswith("blinkmode "):
#        self.blinkmode = l.replace("blinkmode ","")
#    if l.startswith("blipsound "):
#        self.blipsound = l.replace("blipsound ","").strip()
#    if l.startswith("framedelay "):
#        frame,delay = l.split(" ")[1:]
#        self.delays[int(frame)] = int(delay)
#    if l.startswith("globaldelay "):
#        self.speed = float(l.split(" ",1)[1])
#    if l.startswith("blinkspeed "):
#        self.blinkspeed = [int(x) for x in l.split(" ")[1:]]
#f.close()

func load_info(path:String):
	print("load info:", path)
	var data = {
		'horizontal': '1',
		'vertical': '1',
		'delays': {}
	}
	var f = File.new()
	var err = f.open(path, File.READ)
	if err == OK:
		while not f.eof_reached():
			var line = f.get_line()
			if not line.strip_edges():
				print("next line info")
				continue
			var key_value = line.split(" ")
			if key_value.size() == 2:
				data[key_value[0]] = key_value[1]
			elif key_value[0] == "framedelay":
				data["delays"][int(key_value[1])] = int(key_value[2])
			elif key_value[0] == "sfx":
				# TODO can only have one sound effect per frame
				sound_frames[int(key_value[1])] = key_value[2]
		f.close()
	if data.get('length', null)==null:
		data['length'] = int(data['horizontal']) * int(data['vertical'])
	return data

func load_animation(path:String, info=null, sub_rect=null):
	sprite_path = path
	# Load pwv
	
	print("loading info:", path.rsplit(".", true, 1)[0]+'.txt')
	if not info:
		info = load_info(path.rsplit(".", true, 1)[0]+'.txt')
	print("txt:", info)
	
	if AnimationFramesCache.has_cached([path, sub_rect]):
		frames = AnimationFramesCache.get_cached([path, sub_rect])
	else:
		# TODO - sub_rect only works with single frame animations!
		if sub_rect:
			frames = Filesystem.load_atlas_specific(
				path,
				[sub_rect]
			)
		else:
			frames = Filesystem.load_atlas_frames(
				path, 
				int(info['horizontal']),
				int(info['vertical']),
				int(info['length'])
			)
		AnimationFramesCache.set_get_cached([path, sub_rect], frames)
	if frames:
		width = frames[0].region.size.x
		height = frames[0].region.size.y
		if width == 0 or height == 0:
			GlobalErrors.log_error("Sprite frames has no size: %s" % path)
			return
		loaded = true
	
	# Build animated sprite
	animated_sprite = AnimatedSprite.new()
	animated_sprite.name = path.replace(":", "|").replace("/",";")
	animated_sprite.use_parent_material = true
	add_child(animated_sprite)
	animated_sprite.frames = SpriteFrames.new()
	# TODO this is a hack, we are adding frames to slow the animation down when we should use an animationplayer to interpolate instead
	# Also, avoid doing this if there is only one frame. it's not an animation at that point
	if frames.size() > 1:
		var frame_i = 0
		for frame in frames:
			for delay in info["delays"].get(frame_i, 6.0):
				animated_sprite.frames.add_frame("default", frame)
			frame_i += 1
	elif frames:
		animated_sprite.frames.add_frame("default", frames[0])
	else:
		return
	animated_sprite.frames.set_animation_speed("default", 60.0)
	animated_sprite.play("default")
	print("good")
	if info.get('loops') != "1" and info.get('loops') != "yes" and info.get('loops') != "true":
		animated_sprite.frames.set_animation_loop("default", false)
	else:
		animated_sprite.frames.set_animation_loop("default", true)
	rescale(width, height)
	
	material = ShaderMaterial.new()
	material.shader = load("res://System/Graphics/image_filters.shader")
	
	animated_sprite.connect("animation_finished", self, "finish_playing")
	if "wbench" in sprite_path:
		pass
	return self
	
func finish_playing():
	self.emit_signal("finished_playing")
		
func from_frame(frame):
	width = frame.region.size.x
	height = frame.region.size.y
	animated_sprite = AnimatedSprite.new()
	animated_sprite.use_parent_material = true
	add_child(animated_sprite)
	animated_sprite.frames = SpriteFrames.new()
	animated_sprite.frames.add_frame("default", frame)
	material = ShaderMaterial.new()
	material.shader = load("res://System/Graphics/image_filters.shader")
	
func rescale(size_x, size_y):
	var sc_w = float(size_x)/float(max(1, width))
	var sc_h = float(size_y)/float(max(1, height))
	animated_sprite.scale.x = sc_w
	animated_sprite.scale.y = sc_h
	width = size_x
	height = size_y
	if pivot_center:
		animated_sprite.position = Vector2(width/2, height/2)
		animated_sprite.position = Vector2(width/2, height/2)
	self.emit_signal("size_changed")
	

func set_grey(value):
	if material:
		material.set_shader_param("greyscale_amt", float(value))

func set_colorize(color, amount):
	if material:
		material.set_shader_param("to_color", color)
		material.set_shader_param("to_color_amount", amount)

# mostly used for tests
func get_animation_progress():
	if not animated_sprite:
		return 0
	var count = animated_sprite.frames.get_frame_count(animated_sprite.animation)
	return float(animated_sprite.frame/count)

func _process(dt):
	# TODO only plays sounds once, doesn't handle loops
	for sound_frame in sound_frames.keys():
		if animated_sprite.frame >= sound_frame:
			Commands.call_command("sfx", Commands.main.top_script(), [sound_frames[sound_frame]])
			sound_frames.erase(sound_frame)
