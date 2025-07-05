// setLightBrightness

extern number brightness = 1.0;

vec4 effect(vec4 color, Image texture, vec2 texCoord, vec2 screenCoord) {
	vec4 pixel = Texel(texture, texCoord);        // This is the current pixel color
	
	// brightness
	//pixel.b = pixel.b-color.b;                  // or, for optimization	
	pixel.b = pixel.b - (1.0 - brightness);
	if (pixel.b < 0.0) {
		pixel.b = 0.0;
	}
	pixel.r = pixel.b;
	pixel.g = pixel.b;
	
	/* debug, pixel.b бывает меньше нуля, но когда это случается, то пиксели всегда черные;
	   значит можно не беспокоится, что цвета меньше нуля будут неадекватные
	if (pixel.b < 0.0) {
		pixel.r = 1.0;
		pixel.g = 0.0;
	}	
	*/
	
	pixel = pixel * color;                        // с учетом color, чтобы свет мог быть разноцветным
	
	return pixel;
}