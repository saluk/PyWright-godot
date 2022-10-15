extends Node2D
class_name IButton

var frame
var active_frame
var area:Area2D
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
	sprite.material.shader = load("res://Graphics/clear_pink.shader")
	return sprite

func _init(frame, active_frame, pos=Vector2(0,0), size=null):
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
	
	#self.frame.position = Vector2(width/2, height/2)
	#self.active_frame.position = Vector2(width/2, height/2)
	
	self.area = Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.extents = Vector2(width, height)/2
	area.add_child(shape)
	add_child(area)
	area.connect("input_event", self, "_on_Area2D_input_event")
	
	
func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		menu.click_option(button_name)
