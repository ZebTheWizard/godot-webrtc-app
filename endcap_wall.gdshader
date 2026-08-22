shader_type spatial;
render_mode unshaded;

uniform vec4 top_outline_color : source_color = vec4(0.0, 0.53, 1.0, 1.0); // Bright Blue
uniform vec4 wall_top_color : source_color = vec4(0.8, 0.1, 0.5, 1.0);     // Pink
uniform vec4 wall_bottom_color : source_color = vec4(0.05, 0.1, 0.4, 1.0);  // Navy

uniform float border_thickness : hint_range(0.0, 0.5) = 0.4;
uniform float wall_height : hint_range(0.1, 10.0) = 1.0;

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	float height_factor = clamp((local_pos.y + (wall_height * 0.5)) / wall_height, 0.0, 1.0);
	vec3 base_gradient = mix(wall_bottom_color.rgb, wall_top_color.rgb, height_factor);

	bool is_top_face = local_normal.y > 0.5;
	
	// Edge detection in UV space
	bool edge_top    = UV.y < 0.6;
	bool edge_right  = UV.y > 0.9;
	bool edge_bottom = UV.x < 0.4;

	if (is_top_face && (edge_right || edge_top || edge_bottom)) {
		ALBEDO = top_outline_color.rgb;
	} else {
		ALBEDO = base_gradient;
	}
}