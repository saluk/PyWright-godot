extends Reference
class_name Filesystem

# Returns text that is safe to be in a filename
static func sanitize_text_for_path(text, remove_slashes=true):
	text = text.replace(":","--").replace(",","..").replace(" ","_")
	if remove_slashes:
		text = text.replace("/",".")
	return text
	
static func make_if_not_exists_dir(path):
	var d = Directory.new()
	# Ensure save folder exists
	if not d.dir_exists(path):
		d.make_dir(path)
	
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
	
static func lookup_file(sub_path:String, current_path:String, exts=[], print_errors=true):
	if FilePathCache.has_cached([sub_path, current_path]):
		return FilePathCache.get_cached([sub_path, current_path])
	var file = _lookup_file(sub_path, current_path, exts, print_errors)
	return FilePathCache.set_get_cached([sub_path, current_path], file)
	
static func _lookup_file(sub_path:String, current_path:String, exts=[], print_errors=true):
	var searched_paths = []
	
	# Searching for a specific extension
	# Remove the extension from the sub_path and search
	# for all possible versions of the file
	if exts:
		for ext in exts:
			if sub_path.ends_with("."+ext):
				sub_path = sub_path.replace("."+ext, "")
		for ext in exts:
			var found_ext = _lookup_file(sub_path+"."+ext, current_path, [], false)
			if found_ext:
				return found_ext
		return null

	# TODO - some cases may need this to be more advanced
	# For now we will search the path that was given, the parent path, and the res:// folder
	
	var state = "given_path"
	while 1:
		print("DEBUG search ", sub_path, " at ", current_path)
		var joined_path = path_join(current_path, sub_path)
		searched_paths.append(joined_path)
		print("JOINED PATH ", joined_path)
		var joined_exists = DirectoryCache.has_file(joined_path)
		if joined_exists:
			print("returning found:", joined_exists)
			return joined_exists
		
		if state == "given_path":
			state = "game_path"
			while current_path.ends_with("/"):
				current_path = current_path.substr(0, current_path.length()-1)
			current_path = current_path.rsplit("/", true, 1)[0]
			continue
			
		elif state == "game_path":
			state = "res"
			current_path = "res://"
			continue
			
		elif state == "res":
			if 1:#print_errors:
				GlobalErrors.log_error("File Error Root: Unable to find or load file, searched [%s]" % [",".join(searched_paths)])	
			break
		
static func load_resource(path:String):
	if ResourceLoader.exists(path):
		var resource = ResourceLoader.load(path, "", true)
		if resource:
			return resource.get_data()
	return null

static func load_image_from_path(path:String) -> Image:
	var image:Image
	image = load_resource(path)
	if not image:
		var f = File.new()
		var err = f.open(path, File.READ)
		if err != OK:
			print("Error loading file: ", path)
			return null
		f.close()
		image = Image.new()
		var error
		error = image.load(path)
		if error != OK:
			GlobalErrors.log_error("Tried and FAILED to load image: %s error: %s" % [path, error])
	print("image found: ", image)
	de_pink_image(image)
	return image

static func de_pink_image(img:Image):
	if img.detect_alpha() == Image.ALPHA_NONE and img.get_size().length():
		img.convert(Image.FORMAT_RGBA8)
		img.lock()
		for x in range(img.get_width()):
			for y in range(img.get_height()):
				var pixel = img.get_pixel(x, y)
				if pixel.r > 0.99 and pixel.g < 0.05 and pixel.b > 0.99:
					pixel.a = 0.0
					pixel.r = 0.0
					pixel.g = 0.0
					pixel.b = 0.0
					img.set_pixel(x, y, pixel)
		img.unlock()
	return img

static func load_atlas_frames(path:String, horizontal=1, vertical=1, length=1) -> Array:
	print(path)
	# Load image
	var texture:Texture
	var image = load_image_from_path(path)
	if image is StreamTexture:
		texture = image
	elif image.get_size().length() > 0:
		texture = ImageTexture.new()
		texture.create_from_image(image, ImageTexture.FLAG_FILTER)
		
	if not texture or not image.get_size().length() > 0:
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

# Rect_list contains lists of strings, [x, y, width, hright]
# use "w" or "h" for width and height to expand
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
		var rx = int(rect_list[i][0].strip_edges())
		var ry = int(rect_list[i][1].strip_edges())
		var rw = rect_list[i][2].strip_edges()
		var rh = rect_list[i][3].strip_edges()
		if rw == "w":
			rw = image.get_height()
		if rh == "h":
			rh = image.get_height()
		var r = Rect2(rx, ry, rw, rh)
		atlas.region = r
		frames.append(atlas)
	return frames

static func sort_files_by_time(file_a, file_b):
	file_a = file_a[0]+"/"+file_a[1]
	file_b = file_b[0]+"/"+file_b[1]
	var file = File.new()
	if file.get_modified_time(file_a) < file.get_modified_time(file_b):
		return true
