extends Node

var arguments: Array = []
var options: Dictionary = {}

func _ready() -> void:
	arguments = get_arguments()
	options = get_options()

static func get_options():
	var result = {}
	var args = OS.get_cmdline_args()
	for i in len(args):
		if args[i].begins_with("--"):
			var arg = args[i].lstrip("--")
			if arg.find("=") > -1:
				var kvp = arg.split("=")
				if len(kvp) > 1:
					result[kvp[0]] = kvp[1]
				else:
					result[kvp[0]] = null
			elif i + 1 < len(args) and not args[i + 1].begins_with("--"):
				result[arg] = args[i + 1]
			else:
				result[arg] = null
	return result
	
static func get_arguments():
	var result = []
	var args = OS.get_cmdline_args()
	var ignore_next = false
	for i in len(args):
		if ignore_next:
			ignore_next = false
			continue
		if args[i].begins_with("--"):
			if i + 1 < len(args) and not args[i + 1].begins_with("--"):
				ignore_next = true
		else:
			result.append(args[i])
	return result
