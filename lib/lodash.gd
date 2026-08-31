extends Node

func only(source: Dictionary, allowed_keys: Array) -> Dictionary:
	var result = {}
	for key in allowed_keys:
		if source.has(key):
			result[key] = source[key]
	return result

func omit(source:Dictionary, omit_keys: Array) -> Dictionary:
	var result = {}
	for key in source:
		if key not in omit_keys:
			result[key] = source[key]
	return result
