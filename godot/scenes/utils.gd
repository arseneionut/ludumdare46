extends Node

func split_and_clean(the_string, separator):
	var bits = the_string.strip_edges().split(separator)
	var filtered_bits = []
	for b in bits:
		var b2 = b.strip_edges()
		if b2 != "":
			filtered_bits.append(b2)
	return filtered_bits

func copy_array(array):
	var result = []
	for elt in array:
		result.append(elt)
	return result

var rng = RandomNumberGenerator.new()

func _init():
	rng.randomize()

func safe_get(dict, key, default_value):
	if not dict.has(key):
		return default_value
	var result = dict[key]
	if result == null:
		return default_value
	return result
