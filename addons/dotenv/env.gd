extends Node

var ENV_FILE_PATH = OS.get_executable_path().get_base_dir() + "/.env"

func _ready() -> void:
	ENV_FILE_PATH = get_working_dir().path_join(".env")
	#if OS.has_feature("editor"):
		#ENV_FILE_PATH = "res://.env"
	#else:
		## OS.get_executable_path().get_base_dir() gets the directory containing the binary
		#ENV_FILE_PATH = OS.get_executable_path().get_base_dir().path_join(".env")
	print("ENV_FILE_PATH: ", ENV_FILE_PATH)
	load_env()
	
	
func get_working_dir() -> String:
	# In exported builds, globalize_path("res://") resolves to the shell's current working directory
	var cwd = ProjectSettings.globalize_path("res://")
	
	# Fallback for OS-level execution path if needed
	if cwd.is_empty():
		cwd = OS.get_environment("PWD")
		
	return cwd
	
func load_env() -> void:
	if not FileAccess.file_exists(ENV_FILE_PATH):
		# print("No .env file found at: ", ENV_FILE_PATH)
		return

	var file = FileAccess.open(ENV_FILE_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		
		# Ignore empty lines and comments
		if line.is_empty() or line.begins_with("#"):
			continue
			
		# Split at the first '=' character
		var split_idx = line.find("=")
		if split_idx != -1:
			var key = line.left(split_idx).strip_edges()
			var value = line.right(-split_idx - 1).strip_edges()
			
			# Strip quotes if present around the value
			if (value.begins_with('"') and value.ends_with('"')) or (value.begins_with("'") and value.ends_with("'")):
				value = value.substr(1, value.length() - 2)
				
			OS.set_environment(key, value)

func get_env(variable: String) -> String:
	return OS.get_environment(variable)
