extends Reference
class_name WrightScriptStack

var main
var scripts := []

var variables:Variables
var evidence_pages := {
	
}

enum {
	STACK_READY,
	STACK_PROCESSING,
	STACK_COMPLETE
}
var state = STACK_READY

func _init(main):
	assert(main)
	self.main = main
	variables = Variables.new()

signal stack_empty
	
func add_script(script_text):
	var new_script = WrightScript.new(main)
	new_script.load_string(script_text)
	scripts.append(new_script)
	
func load_script(script_path):
	var new_script = WrightScript.new(main)
	new_script.load_txt_file(script_path)
	scripts.append(new_script)
	
func remove_script(script):
	if script in scripts:
		scripts.erase(script)
		script.end()
		
func clear_scripts():
	for script in scripts:
		script.end()
		scripts.erase(script)

func process():
	if not scripts:
		if state == STACK_PROCESSING:
			emit_signal("stack_empty")
			state = STACK_COMPLETE
		return
	if state == STACK_READY:
		state = STACK_PROCESSING
	var current_script = scripts[-1]
	current_script.process_wrightscript()

