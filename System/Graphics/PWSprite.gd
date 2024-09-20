extends Node2D
class_name PWSprite

var info:Dictionary = {
	'horizontal': '1',
	'vertical': '1',
	'delays': {},
	'globaldelay': '6',
	'loops': '0',
	'offsetx': '0',
	'offsety': '0'
}
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
var autoclear := false	  # Will remove the object when finished animating
var loaded = false
var times_to_play = 0   # If greater than 1, when the animation finishes play more times
var random_loop := false   # If true, ignore times_to_play. Randomly play again.
var random_min := 100.0
var random_max := 200.0
signal finished_playing
signal size_changed

var frame = 0
var frametime := 0.0
var sound_frames = {}
var animation_finish_fired = false

# TODO needs to handle different animation modes, loop, once, and blink mode at minimum

func free_members():
	if animated_sprite and is_instance_valid(animated_sprite) and not animated_sprite.is_queued_for_deletion():
		animated_sprite.free()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			on_predelete()

func on_predelete() -> void:
	free_members()

func can_wait():
	return animated_sprite.frames.get_frame_count("default") > 1 and not animated_sprite.frames.get_animation_loop("default")

func set_wait(b):
	print(animated_sprite.frames.get_frame_count("default"))
	print(animated_sprite.frames.get_animation_loop("default"))
	if can_wait():
		wait = b
		return
	wait = false

func _search_file(search_paths:Array, root_path:String):
	var filename
	var sprite_paths_searched = []
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
		return sprite_paths_searched
	return filename

func load_animation(search_path:String, root_path:String, sub_rect=null):
	var search_paths = [search_path]
	if search_path.ends_with(".png"):
		search_paths.append(search_path.substr(0,search_path.length()-4))
	while "//" in search_path:
		search_path = search_path.replace("//", "/")
		search_paths.append(search_path)
	var sprite_filename = _search_file(search_paths.duplicate(), root_path)
	var info_filename = _search_file([search_path.rsplit(".", true, 1)[0]+'.txt'], root_path)
	if not info_filename is Array:
		var valid_info = _load_info(info_filename)
	if info.get('length', null)==null:
		info['length'] = int(info['horizontal']) * int(info['vertical'])
	if not sprite_filename is Array:
		var valid_sprite = _load_animation(sprite_filename, sub_rect)
	else:
		return sprite_filename

func _load_info(path:String):
	print("load info:", path)
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
				info[key_value[0]] = key_value[1]
			elif key_value.size() > 2:
				if key_value[0] == "framedelay":
					info["delays"][int(key_value[1])] = int(key_value[2])
				elif key_value[0] == "sfx":
					# TODO can only have one sound effect per frame
					sound_frames[int(key_value[1])] = key_value[2]
				else:
					info[key_value[0]] = Array(key_value).slice(1, key_value.size()-1)
			elif key_value.size() == 1:
				info[key_value[0]] = true
		f.close()
	else:
		return false
	autoclear = info.get('autoclear', false)

func _load_animation(path:String, sub_rect=null):
	sprite_path = path
	# Load pwv

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
	animated_sprite.frames = SpriteFrames.new()
	#animated_sprite.connect("frame_changed", self, "_frame_changed")
	# TODO this is a hack, we are adding frames to slow the animation down when we should use an animationplayer to interpolate instead
	# Also, avoid doing this if there is only one frame. it's not an animation at that point
	if frames.size() > 1:
		var frame_i = 0
		for frame in frames:
			# TODO get default frame delay
			for delay in info["delays"].get(frame_i, float(info['globaldelay'])):
				animated_sprite.frames.add_frame("default", frame)
				break
			frame_i += 1
	elif frames:
		animated_sprite.frames.add_frame("default", frames[0])
	else:
		return
	animated_sprite.frames.set_animation_speed("default", 60.0)
	animated_sprite.play("default")
	animated_sprite.playing = false
	print("good")
	if info.get('loops') != "1" and info.get('loops') != "yes" and info.get('loops') != "true":
		animated_sprite.frames.set_animation_loop("default", false)
		if int(info.get('loops', 0)) > 1:
			times_to_play = int(info.get('loops'))
	else:
		animated_sprite.frames.set_animation_loop("default", true)

	rescale(width, height)

	material = ShaderMaterial.new()
	material.shader = load("res://System/Graphics/image_filters.shader")

	animated_sprite.connect("animation_finished", self, "finish_playing")
	if "wbench" in sprite_path:
		pass
	Pauseable.new(self)
	add_child(animated_sprite)
	return self

var lastplaying
func set_process(enabled):
	if animated_sprite:
		if enabled == false:
			lastplaying = animated_sprite.playing
			animated_sprite.playing = false
		else:
			animated_sprite.playing = lastplaying
	.set_process(enabled)

func finish_playing():
	if animation_finish_fired:
		return
	animation_finish_fired = true
	if random_loop:
		animated_sprite.frame = 0
		var sec = rand_range(random_min / 60.0, random_max / 60.0)
		var t = get_tree().create_timer(sec)
		yield(t, "timeout")
		frame = 0
		animated_sprite.frame = 0
		animation_finish_fired = false
		return
	elif times_to_play > 1:
		frame = 0
		animated_sprite.frame = 0
		#animated_sprite.play("default")
		times_to_play -= 1
		animation_finish_fired = false
		return
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
	animated_sprite.position = Vector2(0,0)
	if pivot_center:
		animated_sprite.position = Vector2(width/2, height/2)
		animated_sprite.position = Vector2(width/2, height/2)
	# TODO we may need to consider how applying offset in this way affects mouse clicking
	animated_sprite.position.x += int(info['offsetx'])
	animated_sprite.position.y += int(info['offsety'])
	self.emit_signal("size_changed")


func set_grey(value):
	if material:
		material.set_shader_param("greyscale_amt", float(value))

func set_colorize(color, amount):
	if material:
		material.set_shader_param("to_color", color)
		material.set_shader_param("to_color_amount", amount)

func apply_blink_settings(template):
	# TODO template could overwrite the settings
	var blinkmode = info.get("blinkmode", "blink")

	if blinkmode == "loop":
		times_to_play = 0
		animated_sprite.frames.set_animation_loop("default", true)
	elif blinkmode == "stop":
		times_to_play = 1
		animated_sprite.frames.set_animation_loop("default", false)
	else:
		var blinkspeed = StandardVar.BLINKSPEED_NEXT.retrieve()
		if blinkspeed:
			StandardVar.BLINKSPEED_NEXT.delete()
		if not blinkspeed:
			blinkspeed = info.get("blinkspeed", null)
		if not blinkspeed:
			blinkspeed = StandardVar.BLINKSPEED_GLOBAL.retrieve()
		if blinkspeed is String:
			blinkspeed = blinkspeed.split(" ", 1)
		random_loop = true
		random_min = float(blinkspeed[0])
		random_max = float(blinkspeed[1])
		animated_sprite.frames.set_animation_loop("default", false)


# mostly used for tests
func get_animation_progress():
	if not animated_sprite:
		return 0
	var count = animated_sprite.frames.get_frame_count(animated_sprite.animation)
	return float(animated_sprite.frame/count)

func _frame_changed():
	for sound_frame in sound_frames.keys():
		if frame == sound_frame:
			Commands.call_command("sfx", Commands.main.top_script(), [sound_frames[sound_frame]])

func _process(dt):
	frametime += dt
	var delay = info['delays'].get(animated_sprite.frame, float(info['globaldelay'])) / 60.0
	while frametime >= delay:
		next_frame()
		frametime = frametime - delay

# TODO more hacks, this is an intermediate step of not actually playing the AnimatedSprite,
# but just setting the frame individually
func next_frame():
	frame += 1
	if frame >= animated_sprite.frames.get_frame_count("default"):
		if animated_sprite.frames.get_animation_loop("default"):
			animated_sprite.emit_signal("animation_finished")
			frame = 0
			_frame_changed()
		else:
			_frame_changed()
			animated_sprite.emit_signal("animation_finished")
			return
	animated_sprite.frame = frame
	_frame_changed()
