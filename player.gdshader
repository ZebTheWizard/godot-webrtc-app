shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (UV.y > 0.4 && UV.y < 0.6) {
		ALBEDO = vec3(0.0, 1.0, 0.0);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
