--[[
version 0.0.1
@todo 
	
--]]

local ClassParent = require('code.classes.Entity')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end


-- variables private
-- ...

-- variables protected, only in Class
-- ...

-- variables public
ThisModule.z = 11
ThisModule.width = 128
ThisModule.height = 128
ThisModule.drawable = false
ThisModule.shadows = {}
ThisModule.shadows.on = false
ThisModule.shadows.directional = {}                                                                                                             -- для придания наглядности глубины; тени на земле для вида глубины Z
ThisModule.shadows.directional.on = false
ThisModule.shadows.directional.z = 0

do  -- radiosity init
	ThisModule.world = {}
	ThisModule.world.width = ThisModule.width
	ThisModule.world.height = ThisModule.height	
	ThisModule.world.type = 'shader'
	ThisModule.world.light = {}
	ThisModule.world.obstacles = {}
	ThisModule.world.result = {}
	ThisModule.world.result.type = 'canvas'
	ThisModule.world.result.canvas = love.graphics.newCanvas(ThisModule.world.width, ThisModule.world.height)
	ThisModule.world.result.canvas:setFilter('nearest', 'nearest')		
	ThisModule.world.compile = {}
	ThisModule.world.compile.isRun = false
	ThisModule.world.compile.sumCells = 0
	ThisModule.world.compile.sumCellsPast = 0
	ThisModule.world.compile.sumCellsDelta = 0
	ThisModule.world.compile.sumCellsDeltaPast = 0
	ThisModule.world.compile.deltaSameSum = 0
	ThisModule.world.compile.deltaSameSumMax = 0
	ThisModule.world.compile.isDone = false
	ThisModule.world.compile.updateSum = 0
	ThisModule.world.lightSmoothMaxColors = 255             -- 1...255

	ThisModule.shader = {}
	ThisModule.shader.prepareLight = love.graphics.newShader('code/graphics/radiosity/prepareLight.glsl')			-- to black and white
	ThisModule.shader.onlyRed = love.graphics.newShader('code/graphics/radiosity/onlyRed.glsl')	

	-- test ---
	love.graphics.setCanvas(ThisModule.world.result.canvas)
	love.graphics.clear(100, 100, 100, 255)
	love.graphics.setCanvas()
	--------
	--ThisModule.image = love.graphics.newImage(love.image.newImageData(ThisModule.world.width, ThisModule.world.height))
	ThisModule.image = love.graphics.newImage(ThisModule.world.result.canvas:newImageData())

	ThisModule.world.typeShader = {}
	ThisModule.world.typeShader.currentCanvas = 1
	ThisModule.world.typeShader.canvases = {}
	ThisModule.world.typeShader.canvases[1] = love.graphics.newCanvas(ThisModule.world.width, ThisModule.world.height)
	ThisModule.world.typeShader.canvases[2] = love.graphics.newCanvas(ThisModule.world.width, ThisModule.world.height)
	ThisModule.world.typeShader.canvases[1]:setFilter('nearest', 'nearest')
	ThisModule.world.typeShader.canvases[2]:setFilter('nearest', 'nearest')
	ThisModule.world.typeShader.shader = {}
	ThisModule.world.typeShader.shader.compile = love.graphics.newShader("code/graphics/radiosity/compile.glsl")
end

-- methods private
-- ...

-- methods protected
-- ...

-- code

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	if arg.width then
		object.width = arg.width
	end
	if arg.height then
		object.height = arg.height
	end	
	local shape = love.physics.newRectangleShape(0, 0, object.width, object.height, 0)
	local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
--	fixture:setUserData({typeCollision = true})
	
	object.physics.body:setAwake(false)																											-- !!! обязательно, если bodyType="static"; это повышает производительность, т.к. тело само не "засыпает"
	object.physics.fixture = fixture
	
	-- drawBuffer shape
--	local shape = love.physics.newRectangleShape(0, 0, object.width, object.height, 0)
--	local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
	fixture:setSensor(true)
	fixture:setUserData({typeDraw = true})
	
--	object.drawColor = arg.color or {0, 0, 0, 50}
	
--	object.shadows.directional.on = false
--	object.shadows.directional.z = 2
	
	do
	--	object:initLight({source = love.graphics.newImage("light3.png")})
		object:initLight({source = love.graphics.newCanvas(object.world.width, object.world.height)})
		
		local imageLight = love.graphics.newImage("code/graphics/radiosity/light3.png")
		local imageObstacle = love.graphics.newImage("code/graphics/radiosity/obstacles6Red.png")
	--	require("radiosity2DTopDownView"):initObstacles({source = image})
		
		object:initObstacles({source = love.graphics.newCanvas(object.world.width, object.world.height)})  -- можно рисовать
		
		object:initCompile()
		object:setLightSmoothMaxColors(128)
		
		object:drawRoof(0, 0, function(x, y) love.graphics.draw(imageLight, x, y) end)
	--	object.world.light:fill(true)
		
		object:drawObstacle(0, 0, function(x, y) love.graphics.draw(imageObstacle, x, y) end, true)
	end
	
	
	
	return object
end

--[[
HELP:
	+ maxColors = <number> (1...255; default=128)
TODO:
	- 
--]]
function ThisModule:setLightSmoothMaxColors(maxColors)
	ThisModule.world.lightSmoothMaxColors = maxColors or 128
	
	if ThisModule.world.lightSmoothMaxColors > 255 then
		ThisModule.world.lightSmoothMaxColors = 255
	elseif ThisModule.world.lightSmoothMaxColors < 1 then
		ThisModule.world.lightSmoothMaxColors = 1
	end
	
	if ThisModule.world.type == 'shader' then
		ThisModule.world.typeShader.shader.compile:send('lightSmoothMaxColors', ThisModule.world.lightSmoothMaxColors)
	end
end

function ThisModule:clearWorld()
	love.graphics.setCanvas(ThisModule.world.typeShader.canvases[1], ThisModule.world.typeShader.canvases[2])
	love.graphics.clear()
	love.graphics.setCanvas()
end

--[[
HELP:
	+ arg = <table>, elements:
		+ source = <loveImage>(not compressed), <loveCanvas>
		+ brightness = <number int>(0...255)
TODO:
	- 
--]]
function ThisModule:initLight(arg)
	arg = arg or {}
	
	ThisModule.world.light:setBrightness(arg.brightness)
	
	if arg.source and arg.source.type and arg.source:type() == 'Image' then
		ThisModule.world.light.image = arg.source
		ThisModule.world.light.imageData = ThisModule.world.light.image:getData()
		ThisModule.world.light.image:setFilter('nearest', 'nearest')
	elseif arg.source and arg.source.type and arg.source:type() == 'Canvas' then
		ThisModule.world.light.canvas = arg.source
		ThisModule.world.light.canvas:setFilter('nearest', 'nearest')
	else
		ThisModule.world.light.imageData = love.image.newImageData(ThisModule.world.width, ThisModule.world.height)
		ThisModule.world.light.image = love.graphics.newImage(ThisModule.world.light.imageData)
		ThisModule.world.light.image:setFilter('nearest', 'nearest')
	end
	
end

--[[
HELP:
	+ brightness = <number int>(0...255; default=255)
TODO:
	- 
--]]
function ThisModule.world.light:setBrightness(brightness)
	self.brightness = math.floor(brightness or 255)
	if self.brightness > 255 then self.brightness = 255 end
	if self.brightness < 0 then self.brightness = 0 end
	
	ThisModule.shader.prepareLight:send('brightness', ThisModule.world.light.brightness/255)
end

function ThisModule.world.light:getBrightness()
	return self.brightness
end

--[[
HELP:
	+ arg = <table>, elements:
		+ source = <loveImage>(not compressed), <loveCanvas>
TODO:
	- 
--]]
function ThisModule:initObstacles(arg)
	local arg = arg or {}
	if arg.source and arg.source.type and arg.source:type() == 'Image' then
		ThisModule.world.obstacles.image = arg.source
		ThisModule.world.obstacles.imageData = ThisModule.world.obstacles.image:getData()
		ThisModule.world.obstacles.image:setFilter('nearest', 'nearest')
	elseif arg.source and arg.source.type and arg.source:type() == 'Canvas'  then
		ThisModule.world.obstacles.canvas = arg.source
		ThisModule.world.obstacles.canvas:setFilter('nearest', 'nearest')
	else
		ThisModule.world.obstacles.imageData = love.image.newImageData(ThisModule.world.width, ThisModule.world.height)
		ThisModule.world.obstacles.image = love.graphics.newImage(ThisModule.world.obstacles.imageData)
		ThisModule.world.obstacles.image:setFilter('nearest', 'nearest')
	end
	
end

function ThisModule:setObstacle(x, y, boolean)
	
	if ThisModule.world.matrix[x][y].obstacle == boolean then
		return false
	end
	
	local color = {255, 255, 255}
	if boolean then
		color = {0, 0, 0}
	end
	
	if ThisModule.world.obstacles.image then
		ThisModule.world.obstacles.imageData:setPixel(x, y, color[1], color[2], color[3], 255)
	elseif ThisModule.world.obstacles.canvas then
		
	end
	
	if ThisModule.world.result.type == 'image' then
		ThisModule.world.result.imageData:setPixel(x, y, color[1], color[2], color[3], 255)
		ThisModule.world.result.image:refresh()			
	elseif ThisModule.world.result.type == 'canvas' then
		love.graphics.setCanvas(ThisModule.world.result.canvas)
		love.graphics.setColor(color[1], color[2], color[3], 255)
		love.graphics.rectangle('fill', x, y, 1, 1)
		love.graphics.setCanvas()		
	end

--	ThisModule.world.matrix[x][y].obstacle = boolean
	
	
	ThisModule:reCompile()
--	ThisModule:resultUpdate()
end

--[[
HELP:
	+ if ThisModule.world.result.type == 'canvas'
TODO:
	-+ not done
--]]
function ThisModule:drawObstacle(x, y, drawFunc, boolean)
	if ThisModule.world.type == 'lua' then
		do
			local color = {255, 255, 255}
			if boolean then
				color = {0, 0, 0}
			end		
			if ThisModule.world.obstacles.canvas then
				love.graphics.setCanvas(ThisModule.world.obstacles.canvas)
				love.graphics.setColor(color[1], color[2], color[3], 255)
				drawFunc(x, y)
				love.graphics.setCanvas()			
			end
			
			if ThisModule.world.result.type == 'image' then
				
			elseif ThisModule.world.result.type == 'canvas' then
				love.graphics.setCanvas(ThisModule.world.result.canvas)
				love.graphics.setColor(color[1], color[2], color[3], 255)
				drawFunc(x, y)
				love.graphics.setCanvas()		
			end
		end
	elseif ThisModule.world.type == 'canvas' or ThisModule.world.type == 'shader' then
		local color = {0, 0, 0}
		if boolean then
			color = {255, 255, 255}
		end			
--		love.graphics.setCanvas(ThisModule.world.canvas)
--		love.graphics.setColor(color[1], 0, 0, 255)
--		drawFunc(x, y)
--		love.graphics.setCanvas()
		
		if ThisModule.world.obstacles.canvas then
			
--			love.graphics.setBlendMode("alpha", "premultiplied")
			love.graphics.setCanvas(ThisModule.world.obstacles.canvas)
			love.graphics.setColor(color[1], 0, 0, 255)
			
--			love.graphics.setShader(ThisModule.shader.onlyRed)
			drawFunc(x, y)
--			love.graphics.setShader()
			
			love.graphics.setCanvas()
--			love.graphics.setBlendMode("alpha")
		end
		
		-- debug
		local color = {255, 255, 255}
		if boolean then
			color = {0, 0, 0}
		end
		if ThisModule.world.result.type == 'canvas' then
			love.graphics.setCanvas(ThisModule.world.result.canvas)
			love.graphics.setColor(color[1], color[2], color[3], 255)
			drawFunc(x, y)
			love.graphics.setCanvas()		
		end
	end
	
	ThisModule:reCompile()
end

--[[
HELP:
	+ if ThisModule.world.result.type == 'canvas'
TODO:
	-+ not done
--]]
function ThisModule:drawRoof(x, y, drawFunc, boolean)
	if ThisModule.world.type == 'canvas' or ThisModule.world.type == 'shader' then
		local color = {255, 255, 255}
		if boolean then
			color = {0, 0, 0}
		end			
--		love.graphics.setCanvas(ThisModule.world.canvas)
--		love.graphics.setColor(color[1], 0, 0, 255)
--		drawFunc(x, y)
--		love.graphics.setCanvas()
		
		if ThisModule.world.light.canvas then
			
--			love.graphics.setBlendMode("alpha", "premultiplied")
			love.graphics.setCanvas(ThisModule.world.light.canvas)
			love.graphics.setColor(0, 0, color[1], 255)
			
--			love.graphics.setShader(ThisModule.shader.onlyRed)
			drawFunc(x, y)
--			love.graphics.setShader()
			
			love.graphics.setCanvas()
--			love.graphics.setBlendMode("alpha")
		end
		
		-- debug
--		local color = {255, 255, 255}
--		if boolean then
--			color = {0, 0, 0}
--		end
--		if ThisModule.world.result.type == 'canvas' then
--			love.graphics.setCanvas(ThisModule.world.result.canvas)
--			love.graphics.setColor(color[1], color[2], color[3], 255)
--			drawFunc(x, y)
--			love.graphics.setCanvas()		
--		end
	end
	
	ThisModule:reCompile()
end

--[[
HELP:
	+ boolean = <boolean>(true=white, true=black; default=false)
TODO:
	- 
--]]
function ThisModule.world.light:fill(boolean)
	if ThisModule.world.type == 'canvas' or ThisModule.world.type == 'shader' then
		local color = {0, 0, 0}
		if boolean then
			color = {255, 255, 255}
		end
		
		if ThisModule.world.light.canvas then
			love.graphics.setCanvas(ThisModule.world.light.canvas)
			love.graphics.clear(color[1], color[2], color[3], 255)
			love.graphics.setCanvas()
		end
	end
	
	ThisModule:reCompile()	
end

--[[
HELP:
	+ resultUpdate = <boolean>(default=false)
TODO:
	- вместо mapPixel() рисовать свет и препятствия на canvas в определенный канал цвета
--]]
function ThisModule:initCompile(resultUpdate)
	if resultUpdate == nil then resultUpdate = false end
	if ThisModule.world.type == 'lua' then
		do
			-- set lightEnergy		
			local brightness
			if ThisModule.world.result.type == 'image' then
				ThisModule.world.light.imageData:mapPixel(function(x, y, r, g, b, a)
					brightness = b - (255 - ThisModule.world.light.brightness)
					if brightness < 0 then brightness = 0 end
					
					ThisModule.world.matrix[x][y].lightEnergy = brightness
					
					if resultUpdate then
						ThisModule.world.result.imageData:setPixel(x, y, brightness, brightness, brightness, a)
					end
					
					return r, g, b, a
				end)
			elseif ThisModule.world.result.type == 'canvas' then
				ThisModule.world.light.imageData:mapPixel(function(x, y, r, g, b, a)
					brightness = b - (255 - ThisModule.world.light.brightness)
					if brightness < 0 then brightness = 0 end
					
					ThisModule.world.matrix[x][y].lightEnergy = brightness
					
					return r, g, b, a
				end)
				
				if resultUpdate then
					-- draw on canvas
					love.graphics.setCanvas(ThisModule.world.result.canvas)
					love.graphics.clear()
					love.graphics.setColor(255, 255, 255, 255)
					love.graphics.draw(ThisModule.world.light.image)
					love.graphics.setCanvas()			
				end
			end
			
			-- set obstacles
			local imageData
			if ThisModule.world.obstacles.canvas then
				imageData = ThisModule.world.obstacles.canvas:newImageData()
			else
				imageData = ThisModule.world.obstacles.imageData
			end
			
			if ThisModule.world.result.type == 'image' then
				imageData:mapPixel(function(x, y, r, g, b, a)
					if r == 0 and g == 0 and b == 0 and a == 255 then
						ThisModule.world.matrix[x][y].obstacle = true
						
						if resultUpdate then
							ThisModule.world.result.imageData:setPixel(x, y, 0, 0, 0, 255)
						end
					end
					
					return r, g, b, a
				end)
			elseif ThisModule.world.result.type == 'canvas' then
				imageData:mapPixel(function(x, y, r, g, b, a)
					if r == 0 and g == 0 and b == 0 and a == 255 then
						ThisModule.world.matrix[x][y].obstacle = true
					end
					
					return r, g, b, a
				end)			
				
				if resultUpdate then
					-- draw on canvas
					love.graphics.setCanvas(ThisModule.world.result.canvas)
					love.graphics.clear()
					love.graphics.setColor(255, 255, 255, 255)
					love.graphics.draw(ThisModule.world.obstacles.image)
					love.graphics.setCanvas()
				end			
			end
		end
	elseif ThisModule.world.type == 'canvas' then
		do
			-- draw on canvas
			love.graphics.setCanvas(ThisModule.world.canvas)
			love.graphics.clear()
			
			love.graphics.setColor(0, 0, 255, 255)
			love.graphics.draw(ThisModule.world.light.canvas or ThisModule.world.light.image)
			
			-- нужно из ThisModule.world.obstacles оставить только красный канал
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.setShader(ThisModule.shader.onlyRed)
			love.graphics.draw(ThisModule.world.obstacles.canvas or ThisModule.world.obstacles.image)
			love.graphics.setShader()
			
			love.graphics.setCanvas()
			
			
			ThisModule.world.result.imageData = ThisModule.world.canvas:newImageData()
			ThisModule.world.result.image = love.graphics.newImage(ThisModule.world.result.imageData)
			ThisModule.world.result.image:setFilter('nearest', 'nearest')
		end
	elseif ThisModule.world.type == 'shader' then
		-- draw on canvas
		love.graphics.setCanvas(ThisModule.world.typeShader.canvases[2])
		love.graphics.clear()
		
		love.graphics.setColor(0, 0, 255, 255)
		love.graphics.draw(ThisModule.world.light.canvas or ThisModule.world.light.image)
		
		-- нужно из ThisModule.world.obstacles оставить только красный канал
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setShader(ThisModule.shader.onlyRed)
		love.graphics.draw(ThisModule.world.obstacles.canvas or ThisModule.world.obstacles.image)		
		love.graphics.setShader()
		
		love.graphics.setCanvas()
		
		love.graphics.setCanvas(ThisModule.world.typeShader.canvases[1])
		love.graphics.clear()
		love.graphics.setCanvas()
		
		ThisModule.world.typeShader.currentCanvas = 1
	end
end

function ThisModule:reCompile()
	ThisModule:clearWorld()
	self:initCompile()
	
	ThisModule.world.compile.sumCells = 0
	ThisModule.world.compile.sumCellsPast = 0
	ThisModule.world.compile.sumCellsDelta = 0
	ThisModule.world.compile.sumCellsDeltaPast = 0
	ThisModule.world.compile.deltaSameSum = 0
	ThisModule.world.compile.isDone = false
	ThisModule.world.compile.updateSum = 0
end

function ThisModule:resultUpdate()
	if ThisModule.world.type == 'lua' then
		do
			if ThisModule.world.result.type == 'canvas' then
				ThisModule.world.result.imageData = ThisModule.world.result.canvas:newImageData()
				ThisModule.world.result.image = love.graphics.newImage(ThisModule.world.result.imageData)
			end
			
			ThisModule.world.matrix = ThisModule.world.matrix or {}
			for x=0, ThisModule.world.width-1 do                                            -- matrix
				ThisModule.world.matrix[x] = ThisModule.world.matrix[x] or {}
				for y=0, ThisModule.world.height-1 do
					ThisModule.world.matrix[x][y] = ThisModule.world.matrix[x][y] or {}    -- cell
	--				ThisModule.world.matrix[x][y].x = x
	--				ThisModule.world.matrix[x][y].y = y
	--				ThisModule.world.matrix[x][y].obstacle = false
	--				ThisModule.world.matrix[x][y].lightEnergy = 0
	--				ThisModule.world.matrix[x][y].compiled = false                         -- эта клетка полностью просчитана?
	--				ThisModule.world.matrix[x][y].compiledCount = 0                        -- количество взаимодействий при компиляции
					
					if not ThisModule.world.matrix[x][y].obstacle then
						local le = ThisModule.world.matrix[x][y].lightEnergy
						ThisModule.world.result.imageData:setPixel(ThisModule.world.matrix[x][y].x, ThisModule.world.matrix[x][y].y, le, le, le, 255)
					else
						ThisModule.world.result.imageData:setPixel(ThisModule.world.matrix[x][y].x, ThisModule.world.matrix[x][y].y, 0, 0, 0, 255)
					end
				end
			end
			ThisModule.world.result.image:refresh()
			
			if ThisModule.world.result.type == 'image' then
				
			elseif ThisModule.world.result.type == 'canvas' then
				-- draw on canvas
				love.graphics.setCanvas(ThisModule.world.result.canvas)
				love.graphics.clear()
				love.graphics.setColor(255, 255, 255, 255)
				love.graphics.draw(ThisModule.world.result.image)
				love.graphics.setCanvas()			
			end
		end
	elseif ThisModule.world.type == 'canvas' then
		do
			ThisModule.world.result.image:refresh()
			--[[
			-- draw on canvas
			love.graphics.setCanvas(ThisModule.world.canvas)
	--		love.graphics.clear()
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.draw(ThisModule.world.result.image)
			love.graphics.setCanvas()
			--]]
			
			-- debug
			love.graphics.setCanvas(ThisModule.world.result.canvas)
			love.graphics.clear()
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.draw(ThisModule.world.result.image)
			love.graphics.setCanvas()
		end
	elseif ThisModule.world.type == 'shader' then
		-- debug
		love.graphics.setCanvas(ThisModule.world.result.canvas)
		love.graphics.clear()
		love.graphics.setColor(255, 255, 255, 255)
			
		if ThisModule.world.typeShader.currentCanvas == 1 then
			love.graphics.draw(ThisModule.world.typeShader.canvases[2], 0, 0, 0, 1)
		else
			love.graphics.draw(ThisModule.world.typeShader.canvases[1], 0, 0, 0, 1)
		end
		love.graphics.setCanvas()
	end
end

function ThisModule:keypressed(key)
	love.keyboard.setKeyRepeat(true)
	if key == 'down' then
		ThisModule.world.light:setBrightness(ThisModule.world.light:getBrightness()-1)
	elseif key == 'up' then
		ThisModule.world.light:setBrightness(ThisModule.world.light:getBrightness()+1)
	end
end

--[[
HELP:
	+ typeCompile = <string> ('giveLE', 'takeLE'; default='takeLE')
TODO:
	- 
--]]
function ThisModule:updateRadiosity(typeCompile, dt)
	typeCompile = typeCompile or 'takeLE'
	
--	if not ThisModule.world.compile.isRun then return false end
	ThisModule.world.compile.isRun = false
	
	if ThisModule.world.compile.isDone then
--		return false
	end
	if ThisModule.world.compile.updateSum >= ThisModule.world.lightSmoothMaxColors+1 then                                    -- 256 - это максимум; + TODO узнать зависит ли от powLow? да зависит
		ThisModule.world.compile.isDone = true
		ThisModule:resultUpdate()
		
		return false
	end
	
	ThisModule.world.compile.sumCellsPast = ThisModule.world.compile.sumCells
	
	ThisModule.world.compile.updateSum = ThisModule.world.compile.updateSum + 1
	
	if ThisModule.world.type == 'lua' then
		for x=0, ThisModule.world.width-1 do
			for y=0, ThisModule.world.height-1 do
				local cell = ThisModule.world.matrix[x][y]
				ThisModule:emit({cell=cell, powLow=2 --[[, obstaclesReduceLightEnergy=true--]] --[[, lightDirections={1, 2, 3, 4, 5, 6, 7, 8}--]]})
			end
		end
--		ThisModule.world.result.image:refresh()
	elseif ThisModule.world.type == 'canvas' then
		
		ThisModule.world.result.imageData:mapPixel(function(x, y, r, g, b, a)
			local cell = {x=x, y=y, obstacle=r, compiledCount=g, lightEnergy=b}
			local gNew, bNew = ThisModule:emit({cell=cell, type=typeCompile, powLow=255/ThisModule.world.lightSmoothMaxColors})
--			print(gNew, bNew, x, y)
			
			return r, gNew or g, bNew or b, a
		end)
		ThisModule:resultUpdate()
	elseif ThisModule.world.type == 'shader' then
		-- ThisModule.world.compile.isRun = false
--		love.graphics.setCanvas(ThisModule.world.typeShader.canvases.compileIsRun)
--		love.graphics.clear()
--		love.graphics.setCanvas()
		
		love.graphics.setCanvas(ThisModule.world.typeShader.canvases[ThisModule.world.typeShader.currentCanvas])
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setShader(ThisModule.world.typeShader.shader.compile)
		if ThisModule.world.typeShader.currentCanvas == 1 then
			love.graphics.draw(ThisModule.world.typeShader.canvases[2])
		else
			love.graphics.draw(ThisModule.world.typeShader.canvases[1])
		end
		love.graphics.setShader()
		love.graphics.setCanvas()
		
		ThisModule.world.typeShader.currentCanvas = ThisModule.world.typeShader.currentCanvas + 1
		if ThisModule.world.typeShader.currentCanvas > 2 then ThisModule.world.typeShader.currentCanvas = 1 end
		
		-- get ThisModule.world.compile.isRun
--		love.graphics.setCanvas(ThisModule.world.typeShader.canvases.compileIsRun)
--		if ThisModule.world.typeShader.currentCanvas == 1 then
--			love.graphics.draw(ThisModule.world.typeShader.canvases[2])
--		else
--			love.graphics.draw(ThisModule.world.typeShader.canvases[1])
--		end		
--		love.graphics.setCanvas()
--		local imageData = ThisModule.world.typeShader.canvases.compileIsRun:newImageData()
--		local r, g = imageData:getPixel(0, 0)
--		if g < 255 then
--			ThisModule.world.compile.isRun = true
--		end
	end
	
	ThisModule.world.compile.sumCellsDelta = ThisModule.world.compile.sumCells - ThisModule.world.compile.sumCellsPast
	
	--[=[
	-- когда каждый раз обрабатывается одинаковое число ячеек, то свет больше не просчитывается, радиосити провел все расчеты;
	-- BUG2 не верно!!! есть случай когда этот способ не дает скомпилить правильно свет
	if --[[ не обязательно ThisModule.world.compile.sumCellsDelta == ThisModule.world.compile.sumCellsDeltaPast and --]] (not ThisModule.world.compile.isRun)--[[ ANTIBUG2 --]] and ThisModule.world.type ~= 'shader'--[[  --]] then     
--		print(ThisModule.world.compile.sumCellsDelta, ThisModule.world.compile.sumCellsDeltaPast)
		
		ThisModule.world.compile.isDone = true
		ThisModule:resultUpdate()
		
--		ThisModule.world.compile.deltaSameSum = ThisModule.world.compile.deltaSameSum+1
	end
	--]=]
	
--	if ThisModule.world.compile.deltaSameSum > ThisModule.world.compile.deltaSameSumMax then
--		ThisModule.world.compile.deltaSameSumMax = ThisModule.world.compile.deltaSameSum
--	end	
	-- ANTIBUG2
	--  > 1; BUG2.1 не верно!!! есть случай когда этот способ не дает скомпилить правильно свет
	-- 50?...?; какое начало и какой предел?
	--[[
	if ThisModule.world.compile.deltaSameSum > 50 then
		ThisModule.world.compile.sumCells = 0
		ThisModule.world.compile.sumCellsPast = 0
		ThisModule.world.compile.sumCellsDelta = 0
		ThisModule.world.compile.sumCellsDeltaPast = 0
		ThisModule.world.compile.deltaSameSum = 0
		
		ThisModule.world.compile.isDone = true
		ThisModule.world.result.image:refresh()	
	end
	--]]
	
	ThisModule.world.compile.sumCellsDeltaPast = ThisModule.world.compile.sumCellsDelta
	
--	print('update = ', ThisModule.world.compile.isRun, os.clock())
--	love.timer.sleep(0.1)
--	print(ThisModule.world.typeShader.shader.compile:getWarnings())
end

--[[
HELP:
	+ prepareLight = <boolean> (default=true)
TODO:
	- 
--]]
function ThisModule:drawRadiosity(arg)
	local prepareLight
	if prepareLight == nil then
		prepareLight = true
	end
	
	love.graphics.setColor(255, 255, 255, 255)
--	love.graphics.draw(ThisModule.image.background, 0, 0, 0, 2)
--	love.graphics.clear(255, 130, 130, 255)
	
--	love.graphics.draw(ThisModule.world.light.image, 0, 0, 0, 5)
--	love.graphics.draw(ThisModule.world.obstacles.image, 0, 0, 0, 5)	
	
	-- result.image --------------------------------------------------
--	local brightness = math.sin(love.timer.getTime() * 0.8) * 0.5 + 0.5
--	brightness = brightness*255
--	love.graphics.setColor(brightness, brightness, brightness, 255)     -- такая brightness выглядит фигово, не как ожидал
--	love.graphics.setColor(253, 217, 187, 255)
	
	-- - BUG3 если перекомпилить в реалтайм когда яркость низкая, то яркость не изменяется или изменяется не верно, тусклее
--	ThisModule.world.light:setBrightness(255 - (math.sin(love.timer.getTime() * 0.8) * 0.5 + 0.5)*255)
--	ThisModule.world.light:setBrightness(126)
--	print(ThisModule.world.light:getBrightness())
--	ThisModule.shader.prepareLight:send('brightness', 0.5)
--	print(ThisModule.shader.prepareLight:getWarnings())
--	print(ThisModule.shader.prepareLight:getExternVariable('brightness'))
	
	if prepareLight then
		love.graphics.setShader(ThisModule.shader.prepareLight) -- need !!!
	end
--	love.graphics.setShader(ThisModule.shader.onlyRed)
	love.graphics.setBlendMode('multiply')
	
	if ThisModule.world.type == 'lua' then
		if ThisModule.world.result.type == 'image' then
			love.graphics.draw(ThisModule.world.result.image, 0, 0, 0, 5)
		elseif ThisModule.world.result.type == 'canvas' then
			love.graphics.draw(ThisModule.world.result.canvas, 0, 0, 0, 5)
		end
	elseif ThisModule.world.type == 'canvas' and ThisModule.world.result.image then
--		if ThisModule.world.compile.isDone then
--			love.graphics.draw(ThisModule.world.result.image, 0, 0, 0, 5)			
--		end

--		love.graphics.draw(ThisModule.world.canvas, 0, 0, 0, 5)
		
--		love.graphics.draw(ThisModule.world.obstacles.canvas, 0, 0, 0, 5)
		
		-- debug
		if ThisModule.world.result.type == 'canvas' then
			love.graphics.draw(ThisModule.world.result.canvas, 0, 0, 0, 5)
		end
	elseif ThisModule.world.type == 'shader' then
		-- debug
		if ThisModule.world.result.type == 'canvas' then
			
			love.graphics.draw(ThisModule.world.result.canvas, self:getX()-(self.width/2), self:getY()-(self.height/2), 0, 5)
--			love.graphics.draw(ThisModule.world.light.canvas, 0, 0, 0, 5)
		end		
		
--		if ThisModule.world.typeShader.currentCanvas == 1 then
--			love.graphics.draw(ThisModule.world.typeShader.canvases[2], 0, 0, 0, 5)
--		else
--			love.graphics.draw(ThisModule.world.typeShader.canvases[1], 0, 0, 0, 5)
--		end
	end
	
	love.graphics.setBlendMode('alpha')
	love.graphics.setShader()
	---------------------------------------
	--[[
	local x = 5
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle('fill', x-5, 10-5, 700, 100)
	love.graphics.setColor(0, 0, 0, 255)
	-- y: 10 23 34 47 60 73
	love.graphics.print('FPS: '..love.timer.getFPS(), x, 10)
	love.graphics.print('compile.isRun = ' .. tostring(ThisModule.world.compile.isRun), x, 23)
	love.graphics.print('compile.sumCellsDelta = ' .. tostring(ThisModule.world.compile.sumCellsDelta), x, 34)
	love.graphics.print('compile.updateSum = ' .. tostring(ThisModule.world.compile.updateSum), x, 47)
	love.graphics.print('compile.isDone = ' .. tostring(ThisModule.world.compile.isDone), x, 60)
	love.graphics.print('info = ' .. tostring(config.window.title), x, 73)
	--]]
end


function ThisModule:update(arg)
	if self.destroyed then return false end
--	ClassParent.update(self, arg)
	
	ThisModule:updateRadiosity()
	
	
end

function ThisModule:editInUIList(list)
	if self.destroyed then self:destroyedError() end
	
	ClassParent.editInUIList(self, list)
	
	local wE = require("code.worldEditor")
	
	wE:setItemListEditEntityFunc(list, self, self.width, 'width', function(var) self:setSize(var, nil); return self.width end)
	wE:setItemListEditEntityFunc(list, self, self.height, 'height', function(var) self:setSize(nil, var); return self.height end)
end

--[[
	@help 
		+ удалять и создавать новые фикстуры:
			+ фикстуры столкновений
			+ drawBuffer
--]]
function ThisModule:setSize(width, height)
	if type(width) == 'number' then
		self.width = width
	end
	if type(height) == 'number' then
		self.height = height
	end
	
	for i, fixture in ipairs(self.physics.body:getFixtureList()) do
		if fixture:getUserData() then
			local shape = love.physics.newRectangleShape(0, 0, self.width, self.height, 0)
			local fixtureNew = love.physics.newFixture(self.physics.body, shape, 1)																		-- shape копируется при создании fixture
			fixtureNew:setUserData(fixture:getUserData())
			fixtureNew:setCategory(fixture:getCategory())
			
			fixture:setUserData(nil)
			fixture:destroy()
		end
	end
end

function ThisModule:getSavedLuaCode()
	if self.destroyed then self:destroyedError() end
	
	-- одна строка = один entity
	local saveString = ClassParent.getSavedLuaCode(self)	
--	if rawget(self, 'width') ~= nil then
		saveString = saveString..", "..[[width = ]]..tostring(self.width)
--	end
--	if rawget(self, 'height') ~= nil then
		saveString = saveString..", "..[[height = ]]..tostring(self.height)
--	end	

	return saveString
end

function ThisModule:draw(arg)
--	ClassParent.draw(self, arg)
	if not self.drawable then return nil end
	
	local arg = arg or {}
	if (not arg.debug) and (self.image or self.mesh or self.sprite) and (not arg.shadowsDirectional) and (not arg.likeShadow) then
		do --[[
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.setBlendMode('multiply')
			
			love.graphics.draw(self.image, self:getX()-(ThisModule.width/2), self:getY()-(ThisModule.height/2), self.physics.body:getAngle(), scale or 1, scale or 1)
			
			love.graphics.setBlendMode('alpha')
		--]]
		end  
		
		self:drawRadiosity()
	end
end

return ThisModule
