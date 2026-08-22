extends RigidBody3D

func _physics_process(delta: float) -> void:
	apply_central_force(Vector3(2.1, 0, 0))
