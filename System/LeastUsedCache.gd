extends Node

var MAX_CACHE = 5

var cache = {}

# stores [usage, value]
# when cache gets too big, sort by usage, and cut down by half

func to_key(key_elements):
	var key = ""
	for element in key_elements:
		key += str(element) + "..."
	return key

func has_cached(key_elements):
	var key = to_key(key_elements)
	if cache.has(key):
		return true
		
func get_cached(key_elements):
	var key = to_key(key_elements)
	cache[key][0] += 1
	return cache[key][1]
	
func set_get_cached(key_elements, value):
	var key = to_key(key_elements)
	var current_value = null
	if has_cached(key_elements):
		current_value = get_cached(key_elements)
		current_value[0] += 1
		current_value[1] = value
	else:
		_shrink_cache()
		cache[key] = [1, value]
	return value

func _shrink_cache():
	if cache.size() < MAX_CACHE:
		return
	var array = []
	for key in cache.keys():
		var value = cache[key]
		array.append([key, value])
	array.sort_custom(self, "custom_array_sort")
	cache.clear()
	for i in range(MAX_CACHE/2):
		var row = array[i+MAX_CACHE/2]
		cache[row[0]] = row[1]
	
func custom_array_sort(a, b):
	return a[1][0] < b[1][0]
