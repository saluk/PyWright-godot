extends Reference
class_name Colors

static func string_to_color(text):
	if Commands.main:
		var var_text = Commands.main.stack.variables.get_string("color_%s"%text, null)
		if var_text:
			text = var_text
	var parts = []
	if text.length() == 3:
		for ch in text:
			parts.append(float(int(ch))/9.0)
	elif text.length() == 6:
		for i in range(3):
			parts.append(
				float(("0x"+text.substr(i*2, 2)).hex_to_int())/255.0
			)
	elif text.length() == 8:
		for i in range(4):
			parts.append(
				float(("0x"+text.substr(i*2, 2)).hex_to_int())/255.0
			)
		return Color(parts[0], parts[1], parts[2], parts[3])
	else:
		GlobalErrors.log_error("Invalid color: %s" % text)
		return Color(1,1,1)
	return Color(parts[0], parts[1], parts[2])

static func string_to_hex(text):
	var color = string_to_color(text)
	return color.to_html(false)
