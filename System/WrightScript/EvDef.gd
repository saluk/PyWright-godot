extends VariableDef
class_name EvDef

func _init(name, default_type="string", default_value=null, split_on=null).(name, default_type, default_value, split_on):
	pass

var ev_db := {}

func refresh():
	var stack = ObjectFactory.get_main().stack
	ev_db = {}
	for page in stack.evidence_pages:
		for ev_key in stack.evidence_pages[page]:
			ev_db[ev_key] = retrieve_all(ev_key)
	pass
func get_page_data(page):
	var stack = ObjectFactory.get_main().stack
	var datas := []
	for ev_key in stack.evidence_pages[page]:
		datas.append(ev_db[ev_key])
	return datas
func get_defined_tags():
	var stack = ObjectFactory.get_main().stack
	var tags = {}
	for variable in stack.variables.global_namespace.store.keys():
		if variable.ends_with("_name") or variable.ends_with("_pic") or variable.ends_with("_check") or variable.ends_with("_desc"):
			tags[variable.split("_")[0]] = 1
	return tags.keys()

func retrieve_all(tag):
	var root_path = ObjectFactory.get_main().top_script().root_path
	var data = {"tag": tag}
	for field in ["name", "pic", "desc", "check", "presentable"]:
		data[field] = _retrieve_field(tag, field)
	# Post processing
	data["presentable"] = Values.to_truth(data["presentable"])
	var lookup_path = "art/ev/"+data["pic"]+".png"
	data["pic_path"] = "art/ev/"+data["pic"]+".png"
	var ev_path = Filesystem.lookup_file(
		"art/ev/"+data["pic"]+".png",
		root_path
	)
	if not ev_path:
		data["pic_path"] = "art/ev/envelope.png"
	return data
func _retrieve_field(tag, field):
	name = tag+"_"+field
	default_value = null
	var stored = retrieve()
	if stored != null:
		return stored
	# default value for each field
	if field in ["name", "pic"]:
		if tag.ends_with("$"):
			return tag.substr(0, tag.length()-1)
		return tag
	if field == "desc":
		return ""
	if field == "presentable":
		return "true"
	return null
