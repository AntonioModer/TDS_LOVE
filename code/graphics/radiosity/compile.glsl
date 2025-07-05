/*
	version 1.0.0
	HELP:
		+ 2 действия за проход:
			+ сначало рисуем на matrix
			+ чтобы отобразить конечный результат, русуем на конечной текстуре
	TODO:
		+?YES использовать types как в GLSL, а не как в LÖVE:
			GLSL 	            LÖVE shader language
			
			float 	            number
			sampler2D 	        Image
			uniform 	        extern
			texture2D(tex, uv) 	Texel(tex, uv)
		- debug
			-?NO рисовать текст с помощью шейдера
		-? to shadertoy.com
*/
/*
	zlib License

	Copyright (c) 2016 Savoshchanka Anton Aleksandrovich

	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgement in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
*/

uniform float textureSize = 128.0-1.0;
uniform float lightSmoothMaxColors = 128;        // 1...255     // + TODO определять из LOVE2d

/*
	HELP:
		+ тут не получиться отдавать энергию соседней ячейке напрямуюб поэтому нужно принимать свет с соседних ячеек
	TODO:
		- 
*/
float lightEnergyTake(float fromColorB, float toColorB, float lowPow) {
	
	if (fromColorB <= toColorB) { return toColorB; }
	
	toColorB = fromColorB - lowPow;
	
	if (toColorB < 0.0) {
		toColorB = 0.0;
	}
	
	// INFO: compile is run
	
	return toColorB;
}

// for help
//float toNormalizedCoord(float notNormalizedTexCoord, float textureSize) {
	//return notNormalizedTexCoord/textureSize;
//}

/*
	HELP:
		+ cell.obstacle == pixel.r == 1.0
		+ cell.compiledCount == pixel.g == 0.0 ... 1.0 (for debug)
		+ cell.lightEnergy == pixel.b == 0.0 ... 1.0
	TODO:
		- 
*/
vec4 emit(sampler2D matrix, vec2 cellToNormCoord, float lowPow) {
	vec4 cellTo = texture2D(matrix, cellToNormCoord);                                                         // cell-pixel, которая принимает свет
	
	if (cellTo.r == 1.0) { return cellTo; }                                                           // if obstacle then out
	if (cellTo.b >= 1.0) { return cellTo; }                                                            // если максимум яркости
	//if (cellTo.g >= 1.0) { return cellTo; }                                                          // for debug; если compiledCount закончен
	//if (cellTo.b > 0.0) { return cellTo; }                                                          // что это значит, зачем, почему я это писал? код вроде работает, но он вроде не должен работать O.o
	
	/*
		compute
		top-down view
		
		O O O
		O x O
		O O O
		
		sequence:
		1 2 3
		8 x 4
		7 6 5
		
		x - give light energy to this cell
		O - light emited cell
	*/
	
	vec4 cellFrom;                                                                                      // cell которая отдает свет
	vec2 cellFromNormCoord;
	vec2 cellMatrixCoord = vec2(textureSize*cellToNormCoord.x, textureSize*cellToNormCoord.y);
	float maxLightEnergy;
	
	// сравнить энергию всех ячеек, откуда берем и взять только самую яркую; чтобы не обрабатывать каждую ячейку
	
	// 2
	if (cellMatrixCoord.y-1.0 > -1.0) {
		cellFromNormCoord = vec2(cellToNormCoord.x, (cellMatrixCoord.y-1.0)/textureSize);                         // see toNormalizedCoord()
		cellFrom = texture2D(matrix, cellFromNormCoord);                                                          // [cell.x][cell.y-1]
		if (cellFrom.r < 1.0 && cellFrom.b > 0.0 && cellFrom.b > maxLightEnergy /* || cellFrom.b > cellTo.b */) {                // (not cellFrom.obstacle) or (fromColorB > toColorB)
			//cellTo.b = lightEnergyTake(cellFrom.b, cellTo.b, lowPow);
			maxLightEnergy = cellFrom.b;
		}
	}

	// 4
	if (cellMatrixCoord.x+1.0 < textureSize) {
		cellFromNormCoord = vec2((cellMatrixCoord.x+1.0)/textureSize, cellToNormCoord.y);
		cellFrom = texture2D(matrix, cellFromNormCoord);										// [cell.x+1][cell.y]
		if (cellFrom.r < 1.0 && cellFrom.b > 0.0 && cellFrom.b > maxLightEnergy) {
			maxLightEnergy = cellFrom.b;
		}
	}
	
	// 6
	if (cellMatrixCoord.y+1 < textureSize) {
		cellFromNormCoord = vec2(cellToNormCoord.x, (cellMatrixCoord.y+1.0)/textureSize);
		cellFrom = texture2D(matrix, cellFromNormCoord);										// [cell.x][cell.y+1]
		if (cellFrom.r < 1.0 && cellFrom.b > 0.0 && cellFrom.b > maxLightEnergy) {
			maxLightEnergy = cellFrom.b;
		}
	}

	// 8
	if (cellMatrixCoord.x-1 > -1) {
		cellFromNormCoord = vec2((cellMatrixCoord.x-1.0)/textureSize, cellToNormCoord.y);
		cellFrom = texture2D(matrix, cellFromNormCoord);										// [cell.x-1][cell.y]
		if (cellFrom.r < 1.0 && cellFrom.b > 0.0 && cellFrom.b > maxLightEnergy) {
			maxLightEnergy = cellFrom.b;
		}
	}
	
	if (maxLightEnergy > 0.0) {
		cellTo.b = lightEnergyTake(maxLightEnergy, cellTo.b, lowPow);
	}
	
	//cellTo.g += 1.0/lightSmoothMaxColors;                                                // for debug
	
	return cellTo;
}

vec4 effect(vec4 color, sampler2D texture, vec2 textureCoord, vec2 screenCoord) {
	vec4 pixel = texture2D(texture, textureCoord);										// This is the current pixel color
	
	pixel = emit(texture, textureCoord, 1.0/lightSmoothMaxColors);
	
	return pixel;
}