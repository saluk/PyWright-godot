extends Reference
class_name WrightScript

var main:Node
var root_path := ""
var filename := ""
var lines := []
var labels := {}  # each label will have a list of line numbers
var line_num := 0
var line:String

var processing

static func one_frame(dt:float) -> float:
	#  Determine how many frames, at 60 frames per second, have passed over dt
	return dt * 60.0

func _init(main):
	assert(main)
	self.main = main
		
func has_script(scene_name) -> String:
	for name in [scene_name+".script.txt", scene_name+".txt"]:
		var found = Filesystem.lookup_file(name, root_path)
		if found:
			return found
	return ""

func load_txt_file(path:String):
	lines = []
	root_path = path.get_base_dir()+"/"
	filename = path.get_file()
	var f = File.new()
	var err = f.open(path, File.READ)
	if err == OK:
		while not f.eof_reached():
			lines.append(f.get_line())
		f.close()
		preprocess_lines()
	else:
		print("Error loading file ", path)
	
func load_string(string:String):
	lines = []
	root_path = "res://"
	for line in string.split("\n"):
		lines.append(line)
	preprocess_lines()
	
func add_label(label, line_num):
	if not label in labels:
		labels[label] = []
	if not line_num in labels[label]:
		labels[label].append(line_num)
	labels[label].sort()
	
func preprocess_lines():
	var line:String
	var segments:Array
	var i = 0
	while 1:
		if i >= lines.size():
			return
		line = lines[i]
		if line.begins_with("#") or line.begins_with("//"):
			lines[i] = ""
			i += 1
			continue
		line = line.strip_edges(true, true)
		lines[i] = line
		segments = line.split(" ", true, 1)
		if segments and segments[0] == "label":
			add_label(segments[1].strip_edges(), i)
			i += 1
			continue
		elif segments and segments[0] == "include":
			var include_scr = load("res://WrightScript/WrightScript.gd").new(main)
			include_scr.load_txt_file(root_path+segments[1]+".txt")
			var off = 1
			for include_line in include_scr.lines:
				lines.insert(i+off, include_line)
				off += 1
			lines.remove(i)
			continue
		i += 1

func process_wrightscript():
	if not processing:
		processing = execution_loop()
		
func get_next_line(offset:int):
	if line_num+offset >= lines.size():
		return ""
	return lines[line_num+offset]
	
func goto_line_number(offset:int, relative:bool=false):
	if relative:
		line_num = line_num+offset
	else:
		line_num = offset
	if line_num < 0:
		line_num = 0

# TODO we can have multiple labels with the same name in a file, and we should go to the nearest one
func goto_label(label, fail=null):
	var line_nums
	if label in labels:
		line_nums = labels[label]
	elif fail in labels:
		line_nums = labels[fail]
	else:
		print("Tried to go somewhere non existent")
		assert(false)
	# Try to go to next line number
	for possible_line_num in line_nums:
		if possible_line_num > line_num:
			line_num = possible_line_num
			return
	# We couldn't find it, go to the first match
	line_num = line_nums[0]

# Go to the label, unless label is ? in which case we execute the next line
func succeed(label):
	if label == "?":
		return
	goto_label(label)
	
# Go to the dest, unless label is ? in which case we skip the next line
func fail(label, dest=null):
	if label == "?":
		line_num += 1
	elif dest:
		goto_label(dest)
		
func execution_loop():
	while 1:
		if not main or main.blockers:
			yield(main.get_tree(), "idle_frame")
			continue
		if line_num >= lines.size():
			main.stack.remove_script(self)
			return
		line = lines[line_num]
		#print(line_num, ":", line)
		if not line.strip_edges():
			line_num += 1
			continue
		if line[0] == '"' or line[0] == "'":
			line = "text "+line
		var split = line.split(" ") as Array
		var call_command = split[0]
		line_num += 1
		var sig = Commands.call_command(
			call_command, self, split.slice(1, split.size())
		)
		if sig is int:
			if sig == Commands.YIELD:
				yield(main.get_tree(), "idle_frame")
				break
			elif sig == Commands.UNDEFINED:
				main.log_error("No command for "+split[0])
			elif sig == Commands.DEBUG:
				print(" - debug - ")
			else:
				print("undefined return")
		elif sig is SceneTreeTimer:
			#yield(main.get_tree(), "idle_frame")
			yield(sig, "timeout")
			print(sig)
			#continue
		elif sig and sig.get("wait_signal"):
			yield(sig, sig.get("wait_signal"))
			print("done waiting")
	processing = null

#Force script to end
func end():
	#processing = null
	line_num = 0
	lines = []
