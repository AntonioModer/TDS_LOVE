--[[
module draw lights
version 0.0.47
@help 
@todo 
	-+ light and shadows
		- radial blur, пример взять из LibGDX Tutorial на github
		- shadows вынести отдельно, чтобы не было путаницы при разным способам теней
		- посмотреть как рисуются тени (blend modes) в исходниках примеров
		-+ CZ shadows
			- вынести в отдельный модуль
			-+ "не теневая" рамка у объектов, чтобы было видно стенки объектов
			+ передавать параметры в шейдер
			-+ решить проблему с вылезающими теневыми пикселями
		@todo 3 - "полигональные" тени
			- должны рисоваться достаточно быстрее по сравнению с CZ-shadows
		-+ поработать над градиентом света
		- измяемый размер текстуры света
		- оптимизация
			- подстраивать размер shadows.canvas под light.radius, чтобы с увеличением радиуса (> 1000) качество не терялось, а при уменьшении радиуса (< 500) уменьшать размер канваса для повышения производительности
			- разобраться с shadows.entInLight
				+ если нет препятсвий, то рисуем только текстуру света
			-?NO multithreading. рисовать тени на Canvas в отдельном thread
				* The love.graphics and love.window modules have several restrictions and therefore can only be used in the main thread. (https://www.love2d.org/wiki/love.thread)
	-? перенести в Light Class
	- попробовать:
		- shadows github.com/mattdesl/lwjgl-basics/wiki/2D-Pixel-Perfect-Shadows
		- F:\Gamedev\EnginesLibrariesEditors\LOVE\Examples\-graphics\shaders\shadertoy\shadertoy\shader\raycast2d.glsl
		- https://love2d.org/forums/viewtopic.php?f=5&t=81770
--]]

local thisModule = {}

thisModule.debug = {}
thisModule.debug.timer = {}
thisModule.debug.timer.start = 0
thisModule.debug.timer.result = 0

thisModule.sun = {}																																-- глобальный свет (солнце)
thisModule.sun.brightness = 0.5																														-- 0.0 ... 1.0
thisModule.eLB = {}																																	-- entitys lights buffer
thisModule.eLB.lights = {}																															-- keys is number
thisModule.canvas = {}
thisModule.canvas.screen = love.graphics.newCanvas(config.window.width/1, config.window.height/1, 'normal')
--thisModule.shadows.canvas.screen:setFilter('nearest', 'nearest')
thisModule.shadows = {}
thisModule.shadows.entInLight = {}																													-- entitysInLight
thisModule.shadows.entInLight.searchIndex = {}

thisModule.shadows.skip = {}
thisModule.shadows.skip.counterDo = 0																													-- 0
thisModule.shadows.skip.doMin = 1																														-- 1...~; выполнять минимум 1 раз
thisModule.shadows.skip.counterSkip = 0																													-- 0
thisModule.shadows.skip.skipMax = 100																														-- 0...1; чем меньше, тем плавнее выглядит, чем больше - тем рывко-образнее; если изменять внешне, то может случиться баг: перестанет обновляться !!!
thisModule.shadows.skip.skiped = false																													-- чтобы во время пропуска можно было выполнять другой код
thisModule.shadows.skip.counterDt = love.timer.getTime()
thisModule.shadows.skip.counterDtLast = 0

thisModule.shadows.cz = {}																															-- Catalin Zima's shadows
thisModule.shadows.canvas = {}
thisModule.shadows.canvas.main = love.graphics.newCanvas(512/1, 512/1, 'normal')
thisModule.shadows.canvas.main:setFilter('nearest', 'nearest')
thisModule.shadows.shader = {}
thisModule.shadows.shader.invertColorsRGB = love.graphics.newShader([[
	vec4 effect(vec4 color, Image texture, vec2 texCoord, vec2 screenCoord) {
		vec4 pixel = Texel(texture, texCoord);
		
		return vec4 (1.0-(pixel.r*color.r), 1.0-(pixel.g*color.g), 1.0-(pixel.b*color.b), pixel.a*color.a);
	}
]])
thisModule.shadows.shader.replaceColorRGB = love.graphics.newShader([[
	vec4 effect(vec4 color, Image texture, vec2 texCoord, vec2 screenCoord) {
		vec4 pixel = Texel(texture, texCoord);
		
		return vec4 (color.r, color.g, color.b, pixel.a);
	}
]])

-- https://bitbucket.org/totorigolo/shadows
thisModule.shadows.cz.byThomasLacroix = {}
thisModule.shadows.cz.byThomasLacroix.canvas = {}
thisModule.shadows.cz.byThomasLacroix.canvas[1] = love.graphics.newCanvas(thisModule.shadows.canvas.main:getHeight(), thisModule.shadows.canvas.main:getHeight(), 'hdr')
thisModule.shadows.cz.byThomasLacroix.canvas[1]:setFilter('nearest', 'nearest')
thisModule.shadows.cz.byThomasLacroix.canvas[2] = love.graphics.newCanvas(thisModule.shadows.canvas.main:getHeight(), thisModule.shadows.canvas.main:getHeight(), 'hdr')
thisModule.shadows.cz.byThomasLacroix.canvas[2]:setFilter('nearest', 'nearest')
thisModule.shadows.cz.byThomasLacroix.shader = {}
thisModule.shadows.cz.byThomasLacroix.shader.distort = love.graphics.newShader([[code/graphics/light/shadows/byThomasLacroix/distort.glsl]])
thisModule.shadows.cz.byThomasLacroix.shader.reduce = love.graphics.newShader([[code/graphics/light/shadows/byThomasLacroix/reduce.glsl]])
thisModule.shadows.cz.byThomasLacroix.shader.shadow = love.graphics.newShader([[code/graphics/light/shadows/byThomasLacroix/shadow.glsl]])	
thisModule.shadows.cz.byThomasLacroix.shader.blurH = love.graphics.newShader([[code/graphics/light/shadows/byThomasLacroix/blurH.glsl]])
thisModule.shadows.cz.byThomasLacroix.shader.blurV = love.graphics.newShader([[code/graphics/light/shadows/byThomasLacroix/blurV.glsl]])
local shadowsQuality = 1																															-- 1 = best; TODO 3 - у каждого света свое качесво теней
thisModule.shadows.cz.byThomasLacroix.shader.reduce:send('renderTargetSize', thisModule.shadows.canvas.main:getHeight()/shadowsQuality)
thisModule.shadows.cz.byThomasLacroix.shader.shadow:send('renderTargetSize', thisModule.shadows.canvas.main:getHeight())
--thisModule.shadows.cz.byThomasLacroix.shader.shadow:send('lightRadiusStandart', require("code.classes.Entity.Light").radius)						-- BUG in Lua

function thisModule.eLB.queryBoundingBoxCallback(fixture)
	local entity = fixture:getBody():getUserData()
	if entity and entity._TABLETYPE == "object" and (not entity.destroyed) and string.find(entity:getClassName(), "Light") then
		thisModule.eLB.lights[#thisModule.eLB.lights+1] = entity																					--!!! ссылка на object
	end
	return true
end

thisModule.shadows.queryBoundingBoxCallback = {}
thisModule.shadows.queryBoundingBoxCallback.filterEntity = {}
thisModule.shadows.queryBoundingBoxCallback.filterEntity.mobility = 'all'																			-- 'all' or 'dynamic' or 'static' or 'stationary'
function thisModule.shadows.queryBoundingBoxCallback.addFixture(fixture)
	local entity = fixture:getBody():getUserData()  -- Entity
	local string = string
	if entity and entity._TABLETYPE == "object" and (not entity.destroyed) and string.sub(entity:getClassName(), 1, 6) == 'Entity' and entity.drawable and (not thisModule.shadows.entInLight.searchIndex[entity]) then
		if string.sub(entity:getClassName(), 1, 12) ~= 'Entity.Light' and entity.shadows.on then
			if thisModule.shadows.queryBoundingBoxCallback.filterEntity.mobility == 'all' or entity.mobility == thisModule.shadows.queryBoundingBoxCallback.filterEntity.mobility then
				thisModule.shadows.entInLight[#thisModule.shadows.entInLight+1] = entity
				thisModule.shadows.entInLight.searchIndex[entity] = #thisModule.shadows.entInLight
			end
		end
	end
end
--[[
@help 
	+ default smooth = true
@todo 
	+ рамка освещения объектов одинакова всегда (степень проникновения света в объекты), независимо от масштаба и размера:
		+? размера текстуры света (не тестировал)
		-+ от радиуса света; нужно передавать данные в шейдер
			+ чем больше радиус, тем меньше степень проникновение света (шейдер shadow.glsl (определяет это переменная dist))
			- чем больше радиус света, тем меньше нужно блура
--]]
-- return <canvas> with drawed shadows or <false>
function thisModule.shadows:compute(light, smooth, getOnlyShadows, additionalShadows)
	if light.destroyed then return false end
	
	-- default smooth = true
	if smooth == nil then
		smooth = true
	end
	
	local canvasShSize = self.canvas.main:getHeight()																					-- canvas shadows size
	local returnCanvas
	
	-- взять объекты, попадающие в свет
	--[[ 
	@todo 
		-+ оптимизация
			-+ обновлять не каждый раз
			* see Class Light
	--]]

	-- test optimization
	local optimizationOn = false
	
	if optimizationOn then
		self.skip = light.skip                                                                                                              -- меняем !!!
		self.skip.skiped = false
		if self.skip.counterDo == self.skip.doMin then
			if not (self.skip.counterSkip == self.skip.skipMax) then			
				self.skip.counterSkip = self.skip.counterSkip+1
				self.skip.skiped = true
				
				self.skip.counterDt = self.skip.counterDtLast+(love.timer.getTime()-self.skip.counterDt)
				self.skip.counterDtLast = self.skip.counterDt
				self.skip.counterDt = love.timer.getTime()
	--			return false
			else
				self.skip.counterDo = 0
			end
		end
		self.skip.counterDt = (love.timer.getTime()-self.skip.counterDt)+self.skip.counterDtLast
		self.skip.counterDtLast = 0
		local counterDt = self.skip.counterDt
		self.skip.counterDt = love.timer.getTime()
		
	--	print(self.skip.counterSkip)
		if not self.skip.skiped then
			self.entInLight = {}
			self.entInLight.searchIndex = {}
			
	--		require("code.physics").collision.circle(light:getX(), light:getY(), light.radius, false, false, self.queryBoundingBoxCallback.addFixture)				-- light.radius-12 это оптимизация памяти, т.к. будет не сильно замента малая дальняя тень от центра света
	--		require("code.physics").collision.rectangle(light:getX()-light.radius, light:getY()-light.radius, light:getX()+light.radius, light:getY()+light.radius, false, false, self.queryBoundingBoxCallback.addFixture)
			require("code.physics").collision.rectangleFast(light:getX()-light.radius, light:getY()-light.radius, light:getX()+light.radius, light:getY()+light.radius, false, false, self.queryBoundingBoxCallback.addFixture)     -- в 3 раза больше ФПС !!!!
			
			
			light.entInLight = self.entInLight
			
			self.skip.counterSkip = 0
			self.skip.counterDo = self.skip.counterDo+1
	--		print(os.clock(), 'update shadows in light')
		end
		
		self.entInLight = light.entInLight or {searchIndex={}}
	else
		self.entInLight = {}
		self.entInLight.searchIndex = {}
		
		require("code.physics").collision.rectangleFast(light:getX()-light.radius, light:getY()-light.radius, light:getX()+light.radius, light:getY()+light.radius, false, false, self.queryBoundingBoxCallback.addFixture)     -- в 3 раза больше ФПС !!!!
--		require("code.physics").collision.circle(light:getX(), light:getY(), light.radius, false, false, self.queryBoundingBoxCallback.addFixture)
	end
	
	if #self.entInLight == 0 then
		return false
	end

	-- вычисляем тени ------------------------------------
	love.graphics.setCanvas(self.canvas.main)		
	love.graphics.clear()
	
	-- рисуем объекты на canvas.temp пропорционально положения света
	local cameraB = {}																														-- cameraBefore
	cameraB.x = camera.x
	cameraB.y = camera.y
	cameraB.scale = camera.scale
	
	camera:setWindow(0, 0, canvasShSize, canvasShSize)
	camera.x, camera.y, camera.scale = light:getX(), light:getY(), (canvasShSize/2)/light.radius
	
	-- @todo - сделать текстуру света с разметкой пикселей, чтобы знать потери пикселей при масшабировании
	-- + чем больше light.radius и чем меньше self.shadows.canvas.main:getHeight() тем хуже качество теней, пикселы рисуются большими, т.к. мы растягиваем self.shadows.canvas.main под light.radius
	--    + качество теней зависит от self.shadows.canvas:getHeight()
	-- +(variant 1: свет в теневом буфере) self.shadows.canvas:getHeight() не должно быть меньше light.imageLight:getHeight(), т.к. будет теряться качество градиента света при рисовании в теневом canvas, т.е. градиент будет уменьшаться с терять количество цвета
	do camera:attach()
		-- shadows
		--   @help но тени не должны быть белыми при их вычислении, т.к. шейдер из CatalinZima-теней не может обрабатывать белые тени
		for i=1, #self.entInLight do
			local entity = self.entInLight[i]
			
			-- CZ
			-- simple shadow map
			if entity then
--				love.graphics.setColor(0, 0, 0, 255)												-- 1
--					love.graphics.setColor(255, 255, 255, 255)										-- issue: если рисовать белые тени, то на энтитях появляется черная рамка при яркости солнца = 1
--					love.graphics.setBlendMode('replace')											-- не работает? BUG? @todo - test it; test it on LOVE 0.10.0; спросить на форуме
--					love.graphics.setShader(thisModule.shadows.shader.replaceColorRGB)				-- 1; вместо setBlendMode('replace') ?; @todo - а полу-розрачные объекты какие тени отбрасывать будут? проверить
				entity:draw({likeShadow = true})
--					love.graphics.setShader()
--					love.graphics.setBlendMode('alpha')							
			end
		end
	camera:detach() end
	
	camera:setWindow(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	camera.x, camera.y, camera.scale = cameraB.x, cameraB.y, cameraB.scale
	
	-- CZ
	if true then
		love.graphics.setCanvas(self.cz.byThomasLacroix.canvas[1])
		love.graphics.clear()
		love.graphics.setShader(self.cz.byThomasLacroix.shader.distort)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(self.canvas.main)
		love.graphics.setShader()							
	end
	if true then
		love.graphics.setCanvas(self.cz.byThomasLacroix.canvas[2])
		love.graphics.clear()
		love.graphics.setShader(self.cz.byThomasLacroix.shader.reduce)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(self.cz.byThomasLacroix.canvas[1])
		love.graphics.setShader()							
	end		
	if true then
		love.graphics.setCanvas(self.cz.byThomasLacroix.canvas[1])
		love.graphics.clear()
		self.cz.byThomasLacroix.shader.shadow:send("lightRadius", light.radius)
		love.graphics.setShader(self.cz.byThomasLacroix.shader.shadow)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(self.cz.byThomasLacroix.canvas[2])
		love.graphics.setShader()
		
		returnCanvas = self.cz.byThomasLacroix.canvas[1]
	end			
	if smooth then
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setCanvas(self.cz.byThomasLacroix.canvas[2])
		love.graphics.clear()
		love.graphics.setShader(self.cz.byThomasLacroix.shader.blurH)
		love.graphics.draw(self.cz.byThomasLacroix.canvas[1])
		
		love.graphics.setCanvas(self.cz.byThomasLacroix.canvas[1])
		love.graphics.clear()
		love.graphics.setShader(self.cz.byThomasLacroix.shader.blurH)
		love.graphics.draw(self.cz.byThomasLacroix.canvas[2])			
		
		love.graphics.setShader()
		
		returnCanvas = self.cz.byThomasLacroix.canvas[1]
	end
	-- суммируем свет и тени
	if not getOnlyShadows then
		self.cz.byThomasLacroix.canvas[2]:setFilter('linear', 'linear')
--		self.cz.byThomasLacroix.canvas[2]:clear()--self.canvas.main:clear()
		love.graphics.setCanvas(self.cz.byThomasLacroix.canvas[2])--love.graphics.setCanvas(self.canvas.main)		
		love.graphics.clear()
		
		-- рисуем объекты на canvas.temp пропорционально положению света
		local cameraB = {}																														-- cameraBefore
		cameraB.x = camera.x
		cameraB.y = camera.y
		cameraB.scale = camera.scale
		
		camera:setWindow(0, 0, canvasShSize, canvasShSize)
		camera.x, camera.y, camera.scale = light:getX(), light:getY(), (canvasShSize/2)/light.radius
		
		do camera:attach()	
			light:draw({onlyRays=true, source = true, color = {255, 255, 255}, brightness = 100})			-- здесь свет нужно рисовать белым цветом, а не цветом света !!! т.к. это базовый свет
			
			-- shadows
			love.graphics.setColor(255, 255, 255, 255)
			self.cz.byThomasLacroix.canvas[1]:setFilter('linear', 'linear')
			love.graphics.draw(self.cz.byThomasLacroix.canvas[1], light:getX(), light:getY(), 0, light.radius/(canvasShSize/2), light.radius/(canvasShSize/2), canvasShSize/2, canvasShSize/2)
			self.cz.byThomasLacroix.canvas[1]:setFilter('nearest', 'nearest')
--			love.graphics.draw(self.canvas.main, light:getX(), light:getY(), 0, light.radius/(canvasShSize/2), light.radius/(canvasShSize/2), canvasShSize/2, canvasShSize/2)					-- чтобы не было видно вылезающих световых пикселей (объект полностью спрятан тенью)
			
			if additionalShadows then
				additionalShadowsCanvas:setFilter('linear', 'linear')
				love.graphics.draw(additionalShadows, light:getX(), light:getY(), 0, light.radius/(canvasShSize/2), light.radius/(canvasShSize/2), canvasShSize/2, canvasShSize/2)
				additionalShadowsCanvas:setFilter('nearest', 'nearest')
			end
		camera:detach() end
		
		camera:setWindow(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
--		camera:setWindow(test.cameraSetWindow.l, test.cameraSetWindow.t, test.cameraSetWindow.w, test.cameraSetWindow.h)						-- test
		camera.x, camera.y, camera.scale = cameraB.x, cameraB.y, cameraB.scale
		
		self.cz.byThomasLacroix.canvas[2]:setFilter('nearest', 'nearest')
		
		returnCanvas = self.cz.byThomasLacroix.canvas[2]
	end
	
	return returnCanvas--self.canvas.main
end

-- light map
function thisModule.shadows:compile(light)
	--[[
	@todo 
		+ сохранение на диск вынести в новый метод, т.к. не всегда нужно сохранять на диск
		-+ to .dds
			+ нельзя сохранять из LOVE2D API
			- или вручную
			- или с помощью батника NVDIA Compess, AMD Compress
			-+ BC7
			+? не возиться с этим во время разработки, долго; только для оптимизации памяти, в релизе игры			
		-+ способ 1: имя файла - ссылка на таблицу
			+ достоинства:
				+ быстрее способа2, т.к. вероятность одинаковых имен очень низкий
			+ сохранять в изображение и на HDD
				как именовать изображение?
					+ ссылка на таблицу света; 
					+ плюс, если такое имя есть, то добавляем счетчик в конце имени
				+ запоминать уникальное имя сохраненного изображения
			+ если есть "fileNameUniquePart", то перезаписать Image на диск:
				+ пере-сохраняем новое
			+ сохранять fileNameUniquePart в мире
			-+ путь сохранения: 
				+ AppData/world/name/shadowMap
				-? непосредственно в папку с игрой
		- способ 2: имя файла - цифра
			- недостаток: каждый раз нужно перебирать весь список чтобы найти свободное число-имя, а это может быть медленно, если много light в world (1000 шт -> 1000000 раз перебирать)
	--]]
	if light.destroyed then return false end
	if light.shadows.mobility == 'static' or light.shadows.mobility == 'stationary' then
		if not love.filesystem.exists(require("code.world").mainFolderPath..require("code.world").name..'/shadowMap') then
			local success = love.filesystem.createDirectory(require("code.world").mainFolderPath..require("code.world").name..'/shadowMap')
		end		
		
		local uid
		if light.shadows.map.compilation.fileNameUniquePart == '' then
			uid = string.sub(tostring(light), #"table: "+1, -1) --'testUid'
		else
			uid = light.shadows.map.compilation.fileNameUniquePart
		end
		local fileName = require("code.world").mainFolderPath..require("code.world").name..'/shadowMap/'..uid
		
		if light.shadows.map.compilation.fileNameUniquePart == '' then																-- раньше не компилили
			-- определяем новое имя изображения
			
			light.shadows.map.compilation.fileNameUniquePart = uid
			
			if love.filesystem.exists(fileName..'.png') then
				fileName = fileName..'_same'
				for i=1, math.huge do
					if not love.filesystem.exists(fileName..i..'.png') then
						fileName = fileName..i
						light.shadows.map.compilation.fileNameUniquePart = uid..'_same'..i
						break
					end
				end
			end
		end
		
		thisModule.shadows.queryBoundingBoxCallback.filterEntity.mobility = 'static'
		local shadowsComputedCanvas = self:compute(light)
		thisModule.shadows.queryBoundingBoxCallback.filterEntity.mobility = 'all'
		if shadowsComputedCanvas ~= false then
			local imageData = shadowsComputedCanvas:newImageData()
			light.shadows.map.compilation.imageLO = love.graphics.newImage(imageData)
		else
			light.shadows.map.compilation.imageLO = false
			light.shadows.map.compilation.fileNameUniquePart = ''
		end
		
--		print(shadowsComputedCanvas)
--		print(fileName)
--		print(light.shadows.map.compilation.fileNameUniquePart)
	end	
end

function thisModule.shadows:saveCompiledShadows(light)
	if light.destroyed then return false end
	if light.shadows.map.compilation.imageLO ~= false and light.shadows.map.compilation.fileNameUniquePart ~= '' and (light.shadows.mobility == 'static' or light.shadows.mobility == 'stationary') and light.saved then
		light.shadows.map.compilation.imageLO:getData():encode('png', require("code.world").mainFolderPath..require("code.world").name..'/shadowMap/'..light.shadows.map.compilation.fileNameUniquePart..'.png')
	end
end

function thisModule.shadows:compileAllLights()
	for k, light in pairs(require("code.classes.Entity.Light"):getAllObjects()) do
		self:compile(light)
	end
end

-- @todo - копировать из save-папки в папку с исходниками, добавить отдельный метод (и в меню редактора игры)
function thisModule.shadows:saveCompiledShadowsAllLights()
	for k, light in pairs(require("code.classes.Entity.Light"):getAllObjects()) do
		self:saveCompiledShadows(light)
	end
end

-- удаляет lightMap в несохраненных энтитях или не нужные lightMap
function thisModule.shadows:deleteTemplightMaps()
	--[[
		+ составляем список всех файлов в папке
		+ убираем из этого списка все сохраненные в мире LightMap
		+ те что остались удаляем с HDD 
	--]]	
	local filesI = love.filesystem.getDirectoryItems(require("code.world").mainFolderPath..require("code.world").name..'/shadowMap')
	
	-- чтобы легче было искать имена
	local filesK = {}
	for i, v in ipairs(filesI) do
		filesK[v] = true
	end

	for k, light in pairs(require("code.classes.Entity.Light"):getAllObjects()) do
		if light.saved and light.shadows.map.compilation.fileNameUniquePart ~= '' then
			filesK[light.shadows.map.compilation.fileNameUniquePart..'.png'] = nil
		end
	end
	
	for k, v in pairs(filesK) do
		love.filesystem.remove(require("code.world").mainFolderPath..require("code.world").name..'/shadowMap/'..k)
	end	
end

--[[
@todo 
	-? тени сохранять отдельно, рисовать совмещением теней и света перед отрисовкой
	-BUG тени могут менять цвет, если один свет не белый, а другой свет освещает его тень
		- потому что первый свет рисуется с тенями с определенным цветом (когда свет и тени совмещаются в одно изображение)
		- потому что весь свет рисуется на одном канвасе canvas.screen
--]]
-- variant = number (1, 2)

function thisModule:draw(variant)
	self.debug.timer.start = love.timer.getTime()
	
	variant = variant or 1
	
	if thisModule.sun.brightness > 1.0 then 
		thisModule.sun.brightness = 1.00 
	elseif thisModule.sun.brightness < 0 then 
		thisModule.sun.brightness = 0 
	end
	love.graphics.setCanvas(self.canvas.screen)
	love.graphics.clear(255*thisModule.sun.brightness, 255*thisModule.sun.brightness, 255*thisModule.sun.brightness, 255)
	love.graphics.setCanvas()
	
	local light
	local canvasResult = false																													-- <link to result canvas> or <false>
	local canvasShSize = self.shadows.canvas.main:getHeight()																					-- canvas shadows size
	local lightStationaryCanvasDynamicShadows
	
	-- test draw radiosity
	do camera:attach()
		love.graphics.setCanvas(self.canvas.screen)
		local radiosityObjects = require("code.classes.Entity.Radiosity"):getAllObjects()
		for k, object in pairs(radiosityObjects) do
			object.drawable = true
			object:draw()
			object.drawable = false
		end
		love.graphics.setCanvas()
	camera:detach() end
	
	for i=1, #self.eLB.lights do
		light = self.eLB.lights[i]
		canvasResult = false
		
		if (not light.destroyed) and light.on == true and light.brightness >= 1 then
			-- shadows		
			if light.shadows.mobility == 'dynamic' and light.shadows.on == true then
				canvasResult = thisModule.shadows:compute(light, true)
			elseif light.shadows.mobility == 'stationary' then
				-- смешиваем статические тени с тенями от динамических Энтити				
			end
			
			love.graphics.setCanvas(self.canvas.screen)
			do camera:attach()
				if variant == 1 then				
					-- variant 1: свет уже в теневом буфере
					love.graphics.setBlendMode('add')																						-- additive or screen
					if light.shadows.mobility == 'dynamic' then
						if canvasResult == false then
							light:draw({onlyRays = true, source = true})
						else
							love.graphics.setColor(light.color[1], light.color[2], light.color[3], light.brightness*(255/100))
							canvasResult:setFilter('linear', 'linear')
							love.graphics.draw(canvasResult, light:getX(), light:getY(), 0, light.radius/(canvasShSize/2), light.radius/(canvasShSize/2), canvasShSize/2, canvasShSize/2)
							canvasResult:setFilter('nearest', 'nearest')
						end
					elseif light.shadows.mobility == 'static' then
						if light.shadows.on == true then
							light:draw({onlyRays = true})
						else
							light:draw({onlyRays = true, source = true})
						end
					elseif light.shadows.mobility == 'stationary' then
						-- рисуем статические тени смешанные с тенями от динамических Энтити				
					end
					love.graphics.setBlendMode('alpha')			
				elseif variant == 2 then
					-- variant 2: тени отдельно от света (качество и удобство лучше чем 1, но медленнее)
					-- @todo + рисуем тени отдельно
					--			+? делаем тени белыми
					--				+? рисуем их цветом 255*thisModule.sun.brightness
					--				-+? чтобы потом рисовать с love.graphics.setBlendMode('subtractive')
					-- 				@help LOVE 0.10.0: Fixed the "add" and "subtract" BlendModes to no longer modify the alpha of the Canvas / screen.
					--					@todo - test subtract BlendMode on 0.10.0
					love.graphics.setBlendMode('screen')
					light:draw({onlyRays=true})
					love.graphics.setBlendMode('alpha')
					
					-- shadows -----------
					if false then	
						-- не верно !!!!! т.к. тени накладываются на свет, а не смешиваются со светом
						love.graphics.setShader(thisModule.shadows.shader.replaceColorRGB)																						-- черные тени в цвет солнца
						love.graphics.setColor(255*thisModule.sun.brightness, 255*thisModule.sun.brightness, 255*thisModule.sun.brightness, 255)
						love.graphics.draw(self.shadows.canvas.main, light:getX(), light:getY(), 0, light.radius/(canvasShSize/2), light.radius/(canvasShSize/2), canvasShSize/2, canvasShSize/2)
						love.graphics.setShader()
					end
					-- test
					if false then				
						love.graphics.setShader(thisModule.shadows.shader.replaceColorRGB)																						-- черные тени в цвет солнца
						love.graphics.setColor(255*thisModule.sun.brightness, 255*thisModule.sun.brightness, 255*thisModule.sun.brightness, 255)
						love.graphics.draw(self.shadows.cz.byThomasLacroix.canvas[1], light:getX(), light:getY(), 0, light.radius/(canvasShSize/2), light.radius/(canvasShSize/2), canvasShSize/2, canvasShSize/2)
						love.graphics.setShader()
					end				
				end
			camera:detach() end
		end
	end
	love.graphics.setCanvas()
	
	
	-- result
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setBlendMode('multiply')
--	love.graphics.draw(self.canvas.screen, 0, 0, 0, 2, 2)
	love.graphics.draw(self.canvas.screen)
	love.graphics.setBlendMode('alpha')
	
	self.debug.timer.result = love.timer.getTime()-self.debug.timer.start
end

function thisModule:test()
	
	-- test thread
	function love.threaderror(thread, errorstr)
	  print("Thread error!\n"..errorstr)
	  -- thread:getError() will return the same error string now.
	end
	local thread = love.thread.newThread("\n" .. [[
		print('start thread', ...)
		
		require('love.graphics')
		
		local canvas = love.graphics.newCanvas(1280, 720, 'normal')
		local channel = love.thread.getChannel("light")
		channel:push({canvas = canvas})
		
		print('end thread', ...)
	]])
	local channel = love.thread.getChannel("light")
	thread:start()
	
	local pop = channel:pop()
	if pop ~= nil then
		print(pop.canvas)
	end	
end

return thisModule
