shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float percentage = 0.75;
	float darkness = 0.55;
	float visibility = 0.45;
	
	vec4 color = texture(TEXTURE, UV);
	color = vec4(percentage,percentage, darkness, visibility);
	COLOR = color;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
