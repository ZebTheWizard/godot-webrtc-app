extends Node

var running:bool = false
var process_id: int = -1:
	set(value):
		print('set process id: ', value)
		process_id = value
		running = value != -1
		if value == -1:
			print("====Server process terminated.====")
		
var stdout_pipe: FileAccess
var stderr_pipe: FileAccess

func start():
	var args: PackedStringArray = ["run", "--watch", "server"]
	var process_info = OS.execute_with_pipe('bun', args, false)

	process_id = process_info.get('pid')
	stdout_pipe = process_info.get('stdio')
	stderr_pipe = process_info.get('stderr')
	
	print('running: ', running)
	
	return running

func _process(_delta: float) -> void:
	if process_id == -1:
		return
		
	# Check if the process has stopped running
	if not OS.is_process_running(process_id):
		process_id = -1
		return

	# Read standard output line-by-line if available on this tick
	if stdout_pipe and stdout_pipe.is_open():
		while stdout_pipe.get_position() < stdout_pipe.get_length():
			var line: String = stdout_pipe.get_line()
			if line != "":
				_on_bun_stdout_received(line)

	# Read error output if available
	if stderr_pipe and stderr_pipe.is_open():
		var error = []
		while stderr_pipe.get_position() < stderr_pipe.get_length():
			var err_line: String = stderr_pipe.get_line()
			if err_line != "":
				error.push_back(err_line)
		if not error.is_empty():
			push_error("\n".join(error))

func _on_bun_stdout_received(output: String) -> void:
	# Handle your process output here
	print("[Bun Stdout]: ", output)

func _kill_bun_process() -> void:
	print('killing server')
	if process_id != -1 and OS.is_process_running(process_id):
		OS.kill(process_id)
		process_id = -1
	
	if stdout_pipe:
		stdout_pipe.close()
	if stderr_pipe:
		stderr_pipe.close()
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_kill_bun_process()

func _exit_tree() -> void:
	_kill_bun_process()
