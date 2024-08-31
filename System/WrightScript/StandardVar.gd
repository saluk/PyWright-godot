extends Node

class VariableDef extends Reference:
	var name:String
	var default_value
	var default_type:String
	func _init(name, default_type="string", default_value=null):
		self.name = name
		self.default_value = default_value
		self.default_type = default_type
	func retrieve(source=null):
		if not source:
			source = ObjectFactory.get_main().stack.variables
		return source.call("get_"+default_type, name, default_value)
	func store(value, source=null):
		if not source:
			source = ObjectFactory.get_main().stack.variables
		return source.set_val(name, value)
	func delete(source=null):
		if not source:
			source = ObjectFactory.get_main().stack.variables
		return source.del_val(name)

var COURT_FAIL_LABEL := VariableDef.new("_court_fail_label", "string", "none")

var FONT_LIST := VariableDef.new("_font_list", "string", "pwinternational.ttf")
var FONT_LIST_SIZE := VariableDef.new("_font_list_size", "int", "10")
var FONT_BLOCK_LINEHEIGHT := VariableDef.new("_font_block_lineheight", "int", 10)

var CURRENTLABEL := VariableDef.new("_currentlabel", "string", null)
var LASTLABEL := VariableDef.new("_lastlabel", "string", null)

var PENALTY_SCRIPT := VariableDef.new("_penalty_script", "string", null)

var TEXTBOX_BG := VariableDef.new("_textbox_bg", "string", "general/textbox_2")
var TEXTBOX_X := VariableDef.new("_textbox_x", "int", null)
var TEXTBOX_Y := VariableDef.new("_textbox_y", "int", null)
var NT_X := VariableDef.new("_nt_x", "int", null)
var NT_Y := VariableDef.new("_nt_y", "int", null)
var NT_TEXT_X := VariableDef.new("_nt_text_x", "int", null)
var NT_TEXT_Y := VariableDef.new("_nt_text_y", "int", null)
var TEXTBOX_LINES := VariableDef.new("_textbox_lines", "string", "auto")
