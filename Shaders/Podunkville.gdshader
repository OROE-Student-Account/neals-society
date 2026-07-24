shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	float brightness = (color.r + color.g + color.b) / 3.0;
	vec4 greyscale = vec4(brightness, brightness, brightness, color.a);
	if (UV.y > 0.8) {
		COLOR = mix(greyscale, color, (5.0*(UV.y-0.8)));
	} else {
		COLOR = greyscale;
	}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
