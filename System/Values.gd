extends Reference
class_name Values

static func to_num(v):
	if v is float:
		return v
	if v is String and "." in v:
		return float(v)
	return int(v)
