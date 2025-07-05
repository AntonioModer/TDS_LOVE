--[[
version 0.0.10
@help 
	+ 
@todo 
	@todo 1 - type spot
		- при рисовании учитывать angle
	+BUG при смене mobility с 'static' на 'dynamic' нужно рисовать source текстуру на source-базовую, т.е. рисовать скомпилиный свет (с тенями) на базовый (без теней); 
		-NO и удалять скомпилиную текстуру
		+ значит нужен метод setMobility(), getMobility()
	+ оптимизация; если brightness = 0 то не выполнять действий над светом
	+ color и brightness разделить
	-+ яркость = color.alpha
		- world editor menu
	-+ dds
		-+ BC7
		+ не возиться во время разработки, долго; только для оптимизации памяти, в релизе игры
	-+ разобраться с плавностью градиента света
		-+ при изменении яркости очень видны "ступеньки"
			+ увеличить размер текстуры света
				+ попробовать разрешение текстуры света в 1024, 256 и сравнить с 512
					@help качество картинки пропорционально размеру текстуры, влияния на производительность замечено не было, оптимально = 512		
			+ их невозможно полностью убрать из-за 24 битных мониторов Truecolor (https://ru.wikipedia.org/wiki/%D0%93%D0%BB%D1%83%D0%B1%D0%B8%D0%BD%D0%B0_%D1%86%D0%B2%D0%B5%D1%82%D0%B0)
				+ https://ru.wikipedia.org/wiki/%D0%9E%D1%82%D1%82%D0%B5%D0%BD%D0%BA%D0%B8_%D1%81%D0%B5%D1%80%D0%BE%D0%B3%D0%BE
			-NO CompressedImageFormat bc6h
			-NO попробывать вместо Image рисовать Canvas-"hdr"
				-NO на нем с помощью шейдеров рисовать градиент радиальный
	- параметр: не/рисовать debug physics, чтобы не мешало смотреть физику твердых тел
	+ при изменении радиуса менять физику (fixture, shape)
	-+ shadows.mobility:
		-+ 'dynamic'
		-+ 'static'
			+ компиляция
				+ только static Entity
				+ save Image
					+ отдельным изображением на HDD
					-?NO в файл сохранения world
				+ create Image
				+ load Image
					+ удалять lightMap несохраненных энтити при загрузке world
				+ draw Image
				+NO при удалении удалять изображение с HDD
					+ если энтити сохранена в файле, то не удалять
		-? 'stationary'
			-? а нужен ли? если динамический свет быстрее рисуется, чем стационарный
				- не нужен для типа теней: shadows.cz.byThomasLacroix
--]]

local ClassParent = require('code.classes.Entity')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end


-- variables static private ########################################################################


-- variables static protected, only in Class #######################################################


-- variables static public #########################################################################
ThisModule.radius = 500																															-- |readonly!!!|; при изменении заменить также в shadow.glsl (в переменной dist) !!!
ThisModule.on = true
ThisModule.type = 'point' or 'spot' or 'directional' --or 'sky'
ThisModule.image = require("code.worldEditor").images.light.point
ThisModule.imageLight = require("code.graphics").images.light.lightSmooth512																	-- @todo - оптимизация: чем больше радиус, тем больше текстура; или использовать MIPMAP(.dds)
ThisModule.brightness = 100																														-- |readonly!!!|;
ThisModule.color = {255, 255, 255}																												-- |readonly!!!|;

ThisModule.shadows.mobility = 'static' or 'dynamic' --or 'stationary'																			-- |readonly!!!|;
ThisModule.shadows.map = {}																														-- shadow map
ThisModule.shadows.map.compilation = {}
ThisModule.shadows.map.compilation.done = false																									-- <boolean>	
ThisModule.shadows.map.compilation.fileNameUniquePart = ''																						-- <string>
ThisModule.shadows.map.compilation.imageLO = false																								-- Image LOVE object; <false> or <LOVE Image>

ThisModule.debug = {}
ThisModule.debug.on = false
ThisModule.debug.draw = {}
ThisModule.debug.draw.on = false
ThisModule.debug.draw.phys = {}
ThisModule.debug.draw.phys.on = false

-- methods static private ##########################################################################


-- methods static protected ########################################################################

-- methods static public ###########################################################################

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	arg.physics = {bodyType = 'dynamic'}
	local object = ClassParent.newObject(self, arg)
	
	-- nonstatic variables, methods
	object.on = arg.on
	object.radius = arg.radius
	object.type = 'point' or 'spot' or 'directional' --or 'sky'
	object.brightness = arg.brightness
	object.color = arg.color or {255, 255, 255}
	
	object.debug = {}
	object.debug.on = false
	object.debug.draw = {}
	object.debug.draw.on = true
	object.debug.draw.phys = {}
	object.debug.draw.phys.on = true	
	
	-- таблица shadows создается заново в ClassParent.newObject() и не наследует значение из данного Класса
	object.shadows.mobility = arg["shadows.mobility"] or self.shadows.mobility
	object.shadows.map = {}																														-- shadow map
	object.shadows.map.compilation = {}
	object.shadows.map.compilation.done = false																									-- <boolean>	
	object.shadows.map.compilation.fileNameUniquePart = arg["shadows.map.compilation.fileNameUniquePart"] or ''									-- <string>
	if object.shadows.map.compilation.fileNameUniquePart ~= '' then
		local filePath = require("code.world").mainFolderPath..require("code.world").name..'/shadowMap/'..object.shadows.map.compilation.fileNameUniquePart..'.png'
		if love.filesystem.exists(filePath) then
			object.shadows.map.compilation.imageLO = love.graphics.newImage(filePath)															-- Image LOVE object; <false> or <LOVE Image>
		else
			object.shadows.map.compilation.imageLO = false
		end
	else
		object.shadows.map.compilation.imageLO = false
	end
	
	local shape = love.physics.newCircleShape(0, 0, object.radius)
	local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
	fixture:setSensor(true)																														-- !!! свет не имеет колизии
	fixture:setUserData({typeDraw = true, selectedInWorldEditor=false})	
	
	
	object.physics.body:setAwake(false)
	
--	print(string.sub(object:getClassName(), 1, 12) == 'Entity.Light')
	
	-- optimization
	object.skip = {}
	object.skip.counterDo = 0																													-- 0
	object.skip.doMin = 1																														-- 1...~; выполнять минимум 1 раз
	object.skip.counterSkip = 0																													-- 0
	object.skip.skipMax = 0																														-- 0...~; 0 - turnoff; чем меньше, тем плавнее выглядит, чем больше - тем рывко-образнее; если изменять внешне, то может случиться баг: перестанет обновляться !!!
	object.skip.skiped = false																													-- чтобы во время пропуска можно было выполнять другой код
	object.skip.counterDt = love.timer.getTime()
	object.skip.counterDtLast = 0
	
	object.physics.body:setSleepingAllowed(false)
	
--	print(object.physics.body:getType())
	
	object.shadows.directional.on = false
	
--	object.dontSelectInWorldEditor = true
	
	return object
end

function ThisModule:setColor(r, g, b)
	if self.destroyed then self:destroyedError() end
	
	if type(r) == 'number' then
		if r > 255 then r = 255 end
		if r < 0 then r = 0 end
		self.color[1] = r
	end
	if type(g) == 'number' then 
		if g > 255 then g = 255 end
		if g < 0 then g = 0 end
		self.color[2] = g
	end
	if type(b) == 'number' then 
		if b > 255 then b = 255 end
		if b < 0 then b = 0 end
		self.color[3] = b
	end
end

function ThisModule:setBrightness(brightness)
	if self.destroyed then self:destroyedError() end
	
	if brightness > 100 then
		brightness = 100
	end
	self.brightness = brightness
end

function ThisModule:setRadius(radius)
	if self.destroyed then self:destroyedError() end
	
	self.radius = radius
	
--	(self.physics.body:getFixtureList())[1]:destroy()																							-- INFO: BUG !!!
	local fixtureList = self.physics.body:getFixtureList()
	fixtureList[1]:destroy()
	
	local shape = love.physics.newCircleShape(0, 0, self.radius)
	local fixture = love.physics.newFixture(self.physics.body, shape, 1)																		-- shape копируется при создании fixture
	fixture:setSensor(true)
	fixture:setUserData({typeDraw = true, selectedInWorldEditor=false})                                                                         -- брать ссылку из прошлой fixture:getUserData()
end

function ThisModule:editInUIList(list)
	if self.destroyed then self:destroyedError() end
	
	ClassParent.editInUIList(self, list)
	
	local wE = require("code.worldEditor")
	
	wE:setItemListEditEntityFunc(list, self, self.on, 'on', function(var) self.on = var; return self.on end)
	wE:setItemListEditEntityFunc(list, self, self.radius, 'radius', function(var) self:setRadius(var); return self.radius end)
	wE:setItemListEditEntityFunc(list, self, self.type, 'type', function(var) self.type = var; return self.type end)
	wE:setItemListEditEntityFunc(list, self, self.color[1], 'color.red', function(var) self:setColor(var); return self.color[1] end)
	wE:setItemListEditEntityFunc(list, self, self.color[2], 'color.green', function(var) self:setColor(nil, var); return self.color[2] end)
	wE:setItemListEditEntityFunc(list, self, self.color[3], 'color.blue', function(var) self:setColor(nil, nil, var); return self.color[3] end)
	wE:setItemListEditEntityFunc(list, self, self.brightness, 'brightness', function(var) self:setBrightness(var); return self.brightness end)
	wE:setItemListEditEntityFunc(list, self, self.shadows.mobility, 'shadows.mobility', function(var) self:setShadowsMobility(var); return self.shadows.mobility end)
	
	if self.shadows.mobility == 'static' or self.shadows.mobility == 'stationary' then
		list:insertItem({name="compile shadows", func=function() self._modGraph.light.shadows:compile(self) end})
		list:insertItem({name="save compiled shadows", func=function() self._modGraph.light.shadows:saveCompiledShadows(self) end})
	end
end

-- arg.onlyRays = bool, arg.debug = bool, arg.source = bool
-- arg.source: рисуем только исходную текстуру света, без теней
function ThisModule:draw(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	if (not arg.onlyRays) then
		if require("code.worldEditor"):isOn() then
			ClassParent.draw(self, arg)
		elseif arg.debug == true then
			ClassParent.draw(self, arg)
		end
		return nil
	end
	
	local color = arg.color or self.color
	love.graphics.setColor(color[1], color[2], color[3], (arg.brightness or self.brightness)*(255/100))
	if self.shadows.map.compilation.imageLO == false or arg.source == true then
		if self.imageLight then
			local imageH = self.imageLight:getHeight()
			love.graphics.draw(self.imageLight, self.physics.body:getX(), self.physics.body:getY(), 0, self.radius/(imageH/2), self.radius/(imageH/2), imageH/2, imageH/2)
		else
			love.graphics.circle('fill', self.physics.body:getX(), self.physics.body:getY(), self.radius)
		end
	elseif self.shadows.map.compilation.imageLO ~= false then
		local imageH = self.shadows.map.compilation.imageLO:getHeight()
		-- @todo - нужно подгонять к self.imageLight:getHeight()
		love.graphics.draw(self.shadows.map.compilation.imageLO, self.physics.body:getX(), self.physics.body:getY(), 0, self.radius/(imageH/2), self.radius/(imageH/2), imageH/2, imageH/2)		
	end
end

function ThisModule:getSavedLuaCode()
	if self.destroyed then self:destroyedError() end
	
	-- одна строка = один entity
	local saveString = ClassParent.getSavedLuaCode(self)	
	if rawget(self, 'radius') ~= nil then
		saveString = saveString..", "..[[radius = ]]..tostring(self.radius)
	end
	if self.on == false then
		saveString = saveString..", "..[[on = ]]..tostring(self.on)
	end
	if self.shadows.mobility ~= 'static' then
		saveString = saveString..", "..[[["shadows.mobility"] = ]]..[["]]..tostring(self.shadows.mobility)..[["]]
	end	
	if self.shadows.map.compilation.fileNameUniquePart ~= '' then
		saveString = saveString..", "..[[["shadows.map.compilation.fileNameUniquePart"] = ]]..[["]]..tostring(self.shadows.map.compilation.fileNameUniquePart)..[["]]
	end
	if rawget(self, 'color') ~= nil and (self.color[1] ~= 255 or self.color[2] ~= 255 or self.color[3] ~= 255) then
		saveString = saveString..", "..[[color = ]].."{"..self.color[1]..", "..self.color[2]..", "..self.color[3].."}"
	end

	return saveString
end

function ThisModule:destroy()
	if self.destroyed then return false end
	
	if type(self) == 'object' then
		-- delete shadows.map from HDD
		if not self.saved then
			local filePath = require("code.world").mainFolderPath..require("code.world").name..'/shadowMap/'..self.shadows.map.compilation.fileNameUniquePart..'.png'
			if love.filesystem.exists(filePath) then
				love.filesystem.remove(filePath)
				self.shadows.map.compilation.imageLO = false
			end
		end
	elseif type(self) == 'class' then
		
	end
	ClassParent.destroy(self)
end

function ThisModule:setShadowsMobility(shadowsMobility)
	if self.destroyed then self:destroyedError() end
	
	if shadowsMobility == "dynamic" and self.shadows.mobility == 'static' then
		self.shadows.map.compilation.fileNameUniquePart = ''
		self.shadows.map.compilation.imageLO = false
	end
	
	self.shadows.mobility = shadowsMobility
end

return ThisModule
