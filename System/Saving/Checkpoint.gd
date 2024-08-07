extends Reference
class_name Checkpoint

# Format
# {
#	"script": {"name": "ABC", "line_number": 123},
#	"global_vars": {}

static func save_pywright_checkpoint(main, filename:String):
	GlobalErrors.log_info("Saving checkpoint: %s" % filename)
	# list of objects [[object], [object], [object]]
	# [cls,args,props,dest]
	# Create Assets object
	#	evidence_pages -> items
	#   _track: null
	#   _loop: 0
	#	variables (Global scope): {...}
	#	lists: {}
	# Create script objects
	var objects = []
	
	# Asset object
	var assets = ["Assets", [], {"items":[], "_track": null, "_loop":0, "variables":{}, "lists":{}}, null]
	for page in main.stack.evidence_pages.keys():
		for ev in main.stack.evidence_pages[page]:
			assets[2]["items"].append({"id": ev, "page": page})
	assets[2]["variables"] = main.stack.variables.global_namespace.store
	objects.append(assets)
	
	# Script objects,
	var stack_index = 0
	for script in main.stack.scripts:
		var script_ob = ["assets.Script", [], {}, ["stack", stack_index]]
		script_ob[2] = {
			#"_world_id": 65913720,
			"statement": "",
			"pri": 0,
			"scene": script.filename,
			"cross": null,
			"si": script.line_num,
			"lastline": 0,
			"instatement": false,
			"_objects": [
			],
			"viewed": {}
		}
		stack_index += 1
		objects.append(script_ob)
		
	var file = File.new()
	if file.open(filename, File.WRITE) != OK:
		print("Couldn't open file for saving")
	file.store_string(
		to_json(objects)
	)
	file.close()
