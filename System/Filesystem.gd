extends Reference
class_name Filesystem

# TODO clean up all the to_lower() for paths, we should really only be cleaning paths when loading files from script
# also see if pre-generating a file index is a better method

static func file_exists(path):
	path = path.to_lower()
	if path.begins_with("res://"):
		path = path.substr(6, path.length())
	if path.begins_with("/"):
		path = path.substr(1, path.length())
	var curdir = "res://"   # The current directory, already corrected
	if (File.new()).file_exists(curdir+path):
		return curdir+path
	if ResourceLoader.exists(curdir+path):
		return curdir+path
	return null
	
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
	
static func insensitive_find_file_in_path(file:String, path:String):
	var dir = Directory.new()
	if not dir.dir_exists(path):
		print("WARNING: invalid directory for find_file_in_path "+path)
		return null
	if not dir.open(path) == OK:
		print("WARNING: could not open folder for find_file_in_path "+path)
		return null
	# TODO make this work with ResourceLoader
	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if file_name == "." or file_name == "..":
			pass
		if file_name.to_lower() == file.to_lower():
			return path_join(path, file_name)
	return null
	
static func lookup_file_direct(sub_path:String, current_path:String):
	# Uses a case insensitive search to determine if the sub_path(s) exists at current_path
	var parts = path_split(sub_path)
	var found = current_path
	var part
	while parts:
		part = parts.pop_front()
		found = insensitive_find_file_in_path(part, found)
		if not found:
			print("WARNING: could not find file or folder: ", part, " at ", current_path)
			return null
	return found
	
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
		var joined_exists = lookup_file_direct(sub_path, current_path)
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
		
# TODO use directoryindexes to speed up looking for files
# only build a directory index from the games/ or test/ level
# we can search the directory index the same way we lookup_file
		
static func load_resource(path:String):
	var resource = ResourceLoader.load(path)
	return resource

static func load_image_from_path(path:String) -> Image:
	# TODO - we should try the file before the resource to allow modding
	var resource = load_resource(path)
	if resource:
		print("resource found")
		return resource
	var f = File.new()
	var err = f.open(path, File.READ)
	var image:Image
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
	return image

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
