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
	var directories = Array(path.split("/"))   # Directories and subdirectories to correct
	var curdir = "res://"   # The current directory, already corrected
	print("check if file exists ", curdir+path)
	if (File.new()).file_exists(curdir+path):
		return curdir+path
	if ResourceLoader.exists(curdir+path):
		return curdir+path
	# DONT correct case
	return null
	# This will correct the case, but we should probably index beforehand instead
#	for i in range(directories.size()):
#		# Get next directory to correct
#		var nextdir = directories.pop_front()
#		var listing = Directory.new()
#		if listing.open(curdir) != OK:
#			return null
#		listing.list_dir_begin()
#		var found = false
#		var next_file_name = listing.get_next()
#		while next_file_name != "":
#			if next_file_name.to_lower() == nextdir.to_lower():
#				nextdir = next_file_name
#				found = true
#				break
#			next_file_name = listing.get_next()
#		if not found:
#			return null
#		if curdir == "res://":
#			curdir += nextdir
#		else:
#			curdir = curdir + "/" + nextdir
#	return curdir
	# Path doesn't exist, find each directory from the root
	
static func path_join(a, b):
	if not a.ends_with("/"):
		return a+"/"+b
	return a+b
	
static func lookup_file(sub_path, current_path):
	sub_path = sub_path.to_lower()
	# find sub_path in current path or up the folders
	while 1:
		var joined = path_join(current_path, sub_path)
		print("try ", joined)
		var joined_exists = file_exists(joined)
		if joined_exists:
			print("returning found")
			return joined_exists
		if not "/" in current_path and current_path and current_path!=".":
			current_path = "res://"
			continue
		if not current_path or current_path == "res://":
			print("returning not found")
			return null
		current_path = current_path.rsplit("/", true, 1)[0]
		
static func load_resource(path:String):
	var resource = ResourceLoader.load(path)
	return resource

static func load_image_from_path(path:String) -> Image:
	path = path.to_lower()
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
	path = path.to_lower()
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
	path = path.to_lower()
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
