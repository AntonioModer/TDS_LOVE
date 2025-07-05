vec4 effect(vec4 color, Image texture, vec2 texCoord, vec2 screenCoord) {
	vec4 pixel = Texel(texture, texCoord);        // This is the current pixel color
	
	//pixel = pixel*color;  // if not work, use this
	
	/**/
	if (pixel.r != 1.0) {
		pixel.g = 0.0;
		pixel.b = 0.0;
		pixel.a = 0.0;
	}
	
	/*
	// test, delete black color
	if (pixel.r == 0.0 && pixel.g == 0.0 && pixel.b == 0.0 && pixel.a == 1.0) {
		pixel.a = 0.0;
	}
	*/
	
	return pixel*color;
}