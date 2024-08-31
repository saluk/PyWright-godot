extends Reference
class_name Values

static func to_num(v):
	if v is float or v is int:
		return v
	if v is String:
		if v.is_valid_integer():
			return int(v)
		if v.is_valid_float():
			return float(v)
	return null

static func to_str(v):
	if v is String:
		return v
	return null
	
static func to_int(v):
	if v is int:
		return v
	if v!=null and v.is_valid_integer():
		return int(v)
	return null

static func to_float(v):
	if v is float:
		return v
	if v.is_valid_float():
		return float(v)
	return null

static func to_truth(v):
	return WSExpression.string_to_bool(v)
	
static func to_truth_string(v):
	if to_truth(v):
		return 'true'
	return 'false'
