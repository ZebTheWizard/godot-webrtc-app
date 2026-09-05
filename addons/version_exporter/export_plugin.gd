@tool
extends EditorExportPlugin

func _get_name() -> String:
	return "GitVersionExporter"

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var output = []
	# Execute git to get the short commit hash (e.g., 'a1b2c3d')
	var exit_code = OS.execute("git", ["rev-parse", "HEAD"], output, true)
	
	var version_string = "unknown"
	if exit_code == 0 and output.size() > 0:
		version_string = output[0].strip_edges()
	
	# Write the commit hash to a small config file included in the build
	var config = ConfigFile.new()
	config.set_value("version", "commit", version_string)
	config.save("res://version.cfg")
