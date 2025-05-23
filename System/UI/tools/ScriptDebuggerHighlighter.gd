@tool
extends SyntaxHighlighter
class_name ScriptDebuggerHighlighter

@export var text_color:Color
@export var textbox_color:Color
@export var comment_color:Color
@export var macro_color:Color
@export var keyword_color:Color

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var text:String = get_text_edit().get_line(line)
	# TODO - should make a generic line parser for wrightscript
	#		 and reuse that here
	
	var buf:String = text
	# grey out comments
	# split line by rightmost "#", unless rightmost "#" is after an unclosed "
	var d = {0: {'color':text_color}}
	if "#" in text:
		var comment = text.find("#")
		while text.substr(0,comment).count('"') == 1:
			var next_comment = text.substr(comment+1).find('#')
			if next_comment == -1:
				comment = -1
				break
			comment = comment+1+next_comment

		if comment >= 0:
			d[comment] = {'color': comment_color}
			d[text.length()] = {'color': text_color}
			text = text.substr(0, comment-1)
	
	# color quotations
	if '"' in text:
		var first = text.find('"')
		var s = first+1
		buf = text.substr(s)
		d[first] = {'color': textbox_color}
		# color macros inside quotations
		while "{" in buf:
			var left_macro = buf.find('{')
			s = s+left_macro
			d[s] = {'color': macro_color}
			s+=1
			buf = buf.substr(left_macro+1)
			var right_macro = buf.find('}')
			if right_macro>-1:
				s+= right_macro+1
				d[s] = {'color':textbox_color}
				buf = text.substr(s)
		if '"' in buf:
			d[s+buf.find('"')+1] = {'color': text_color}
	else:	
		# get keywords
		for kw in Commands.all_commands():
			buf = text
			var s = 0
			var next_kw = buf.find(kw)
			while next_kw > -1:
				print(kw)
				print("BUF", text, buf.substr(next_kw, len(kw)+1).strip_edges())
				if buf.substr(next_kw, len(kw)+1).strip_edges() != kw:
					s = s+next_kw+len(kw)+1
					buf = text.substr(s)
					next_kw = buf.find(kw)
					continue
				d[s+next_kw] = {'color': keyword_color}
				s+=next_kw+len(kw)
				d[s+1] = {'color': text_color}
				buf = text.substr(s)
				next_kw = buf.find(kw)
				
			
			
	# Sort the keys to fix a bug with how godot is iterating the color regions
	var d2 = {}
	var keys = d.keys()
	keys.sort()
	for k in keys:
		d2[k] = d[k]
	return d2
