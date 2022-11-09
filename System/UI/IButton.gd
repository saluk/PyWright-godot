extends Node2D
class_name IButton

var script_name = "gui"
var z:int

var frame
var active_frame
var area:Control
var menu
var button_name

var width
var height

func get_size(texture):
	if texture.has_method("get_rect"):
		return texture.get_rect().size
	if "width" in texture and "height" in texture:
		return Vector2(texture.width, texture.height)
	if texture is AnimatedSprite:
		texture = texture.frames.get_frame(texture.animation, texture.frame)
	if texture is AtlasTexture:
		return texture.region.size
		
func build_sprite(frame):
	if not frame:
		return null
	if frame is Sprite or frame is AnimatedSprite or frame is PWSprite:
		return frame
	# TODO should make this a PWSprite
	var sprite = Sprite.new()
	sprite.texture = frame
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = load("res://System/Graphics/clear_pink.shader")
	return sprite
	
func load_art(frame_path, active_frame_path=null, text=""):
	if text:
		# TODO clean this up
		var label = Label.new()
		label.theme = load("res://System/UI/ScriptDebugger.tres")
		label.text = text
		var label_size = label.get_theme_default_font().get_string_size(text)
		width = label_size.x
		height = label_size.y
		area = Control.new()
		area.rect_position = Vector2(-width/2, -height/2)
		area.rect_size = Vector2(width, height)
		add_child(area)
		area.connect("gui_input", self, "_on_Area2D_input_event")
		area.add_child(label)
		return
	var frame = PWSprite.new()
	frame.load_animation(frame_path)
	var active_frame = PWSprite.new()
	active_frame.load_animation(active_frame_path)
	# TODO bad hack
	var pos = Vector2(position.x, position.y)
	load_final_art(frame, active_frame)
	position = pos

func _init(frame=null, active_frame=null, pos=Vector2(0,0), size=null):
	if frame != null:
		load_final_art(frame, active_frame, pos, size)
		
func load_final_art(frame, active_frame=null, pos=Vector2(0,0), size=null):
	self.frame = build_sprite(frame)
	self.active_frame = build_sprite(active_frame)
	self.position = pos
	self.add_child(self.frame)
	self.add_child(self.active_frame)
	if self.active_frame:
		self.active_frame.visible = false
	
	if not size:
		size = get_size(frame)
	width = size.x
	height = size.y
	
	area = Control.new()
	area.rect_position = Vector2(-width/2, -height/2)
	area.rect_size = Vector2(width, height)
	add_child(area)
	area.connect("gui_input", self, "_on_Area2D_input_event")
	
	
func _on_Area2D_input_event(event):
	if event is InputEventMouseButton and event.is_pressed():
		menu.click_option(button_name)
