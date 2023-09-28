extends Reference
class_name Filesystem
	
static func path_join(a, b):
	if a.ends_with("/"):
		a = a.substr(0, a.length()-1)
	if b.begins_with("/"):
		b = b.substr(1, b.length()-1)
	return a+"/"+b
	
static func path_split(path:String):
	var parts = []
	if path.begins_with("res://"):
		parts.append("res://")
		path = path.split("res://", 1)[1]
	for segment in path.split("/"):
		parts.append(segment)
	return parts
	
static func lookup_file(sub_path:String, current_path:String, exts=[]):
	if exts:
		for ext in exts:
			if sub_path.ends_with("."+ext):
				sub_path = sub_path.replace("."+ext, "")
		for ext in exts:
			var found_ext = lookup_file(sub_path+"."+ext, current_path)
			if found_ext:
				return found_ext
		return null

	# find sub_path in current path OR up the folders
	if not current_path.begins_with("res://"):
		current_path = "res://"+current_path
	while 1:
		print("DEBUG search ", sub_path, " at ", current_path)
		var joined_exists = DirectoryCache.has_file(path_join(current_path, sub_path))
		if joined_exists:
			print("returning found:", joined_exists)
			return joined_exists
		if not "/" in current_path and current_path and current_path!=".":
			current_path = "res://"
			continue
		if not current_path or current_path == "res://":
			print("returning not found")
			return null
		current_path = current_path.rsplit("/", true, 1)[0]
		if current_path in ["res", "res:", "res:/"]:
			current_path = "res://"
		
static func load_resource(path:String):
	if ResourceLoader.exists(path):
		var resource = ResourceLoader.load(path, "", true)
		if resource:
			return resource.get_data()
	return null

static func load_image_from_path(path:String) -> Image:
	# TODO - we should try the file before the resource to allow modding
	var image:Image
	image = load_resource(path)
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		image = load_resource(path)
		if not image:
			print("Error loading file: ", path)
			return null
	var buffer:PoolByteArray
	buffer = f.get_buffer(f.get_len())
	f.close()
	image = Image.new()
	var error
	if path.ends_with("png"):
		error = image.load_png_from_buffer(buffer)
	elif path.ends_with("bmp"):
		error = image.load_bmp_from_buffer(buffer)
	elif path.ends_with("jpg"):
		error = image.load_jpg_from_buffer(buffer)
	print("image found: ", image)
	de_pink_image(image)
	return image

static func de_pink_image(img:Image):
	if img.detect_alpha() == Image.ALPHA_NONE:
		img.convert(Image.FORMAT_RGBA8)
		img.lock()
		for x in range(img.get_width()):
			for y in range(img.get_height()):
				var pixel = img.get_pixel(x, y)
				if pixel.r > 0.95 and pixel.g < 0.05 and pixel.b > 0.95:
					pixel.a = 0.0
					pixel.r = 0.0
					pixel.g = 0.0
					pixel.b = 0.0
		img.unlock()
	return img

static func load_atlas_frames(path:String, horizontal=1, vertical=1, length=1) -> Array:
	print(path)
	# Load image
	var texture:Texture
	var image = load_image_from_path(path)
	if image is StreamTexture:
		texture = image
	else:
		texture = ImageTexture.new()
		texture.create_from_image(image, 0)
		texture.flags = 0
		
	if not texture or not image:
		return []
	
	# Build frames
	var frames = []
	var x = 0
	var y = 0
	var width = image.get_width() / horizontal
	var height = image.get_height() / vertical
	print(width," ",height)
	for i in range(length):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2(x, y), Vector2(width, height))
		print(atlas.region)
		frames.append(atlas)
		x += width
		if x >= image.get_width():
			y += height
			if y >= image.get_height():
				break
			x = 0
	return frames

static func load_atlas_specific(path:String, rect_list:Array) -> Array:
	print(path)
	# Load image
	var texture:Texture
	var image = load_image_from_path(path)
	if image is StreamTexture:
		texture = image
	else:
		texture = ImageTexture.new()
		texture.create_from_image(image, 0)
		
	if not texture or not image:
		return []
	
	# Build frames
	var frames = []
	for i in range(rect_list.size()):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = rect_list[i]
		frames.append(atlas)
	return frames
