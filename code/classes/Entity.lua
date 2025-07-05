--[[
	@version 0.0.18
	* entity - это (не)материальный (не)видимый предмет, который имеет координаты и находится в world
	* entity существует только в world, нет world - нет объекта
	-+ утечка памяти при добавлении и удалении энтити в world, 
		- есть небольшая утечка в несколько Мб
			- проблема в Box2D, рассказать про это разрабам
		+YES проблема в EntityClass:newObject(arg) -> object.physics.body:setUserData(object)
			+NO удалить Box2DWorld
			+YES self.physics.body:setUserData(nil)	
		+NO скорее всего нужно удалять класс полностью
		+NO смотри WorldEditor.UI -> <create entity>
		+NO модули в package.loaded не удаляются
		+NO jit.flush()
	+ чтобы создать entity сначала нужно создать worldEditor.ui, иначе ни-как
	@todo [
		- EntityTemplate.lua
		+ параметр: можно ли сохранять
		-? в определенном entity class указывать playerController метод, с помощью которого определяется управление игроком этой entity
		@todo - шаблоны Entity
			- шаблон-пример EntityTemplate 
			- wall
			- dynamic box
		- режим отображения только тени
		-+ debug
		- https://en.wikipedia.org/wiki/Entity_component_system
		-+ entity [
			-+ physics		
			- Not alive Game Object		
			- alive Game Object	
				- human	
				- player
					- control
			-+ система игровых объектов: [
				* в Unity: http://docs.unity3d.com/ru/current/Manual/class-GameObject.html
				* в UnrealEngine4: https://docs.unrealengine.com/latest/INT/GettingStarted/Terminology/index.html
				* системы Unity и UnrealEngine4 аналогичны, т.к. GameObject имеет Components
				-?NO компоненты (<class>):
					-NO draw component
						- рисование
							- использует Box2d: body, fixture(isSensor), polygon или circle shapes
					-NO physics component:
						- body
						- fixture
					-? controller component
						- keyboard
						- mouse
					- pathfinding component:
						- Node
				- отрисовка игровых объектов
					-YES рисуется только Entity
					-?NO в каждом объекте проверять, есть ли у него компонент который нужно рисовать (как у меня, только еще нужно проверять компоненты)	
					-?YES есть ли метод inCameraView.draw
			]
			- редактор объектов
				- редактировать физику
		]
		@todo 1 -+ система обновления энтитей Entity:update()
			-? находится в world:entitysUpdate()
			- если нету в энтити метода update(), то она не обновляется, и её нету в списке обновления
				-NO добавлять в спец-список вручную
					-?NO в каждом Классе в конце newObject() добавлять функцию, которая определит, добавлять ли в список объект
				-?YES или, если в Классе есть метод update() (с помощью rawget()), то просто берем из него список всех его объектов и обновляем
					* но тогда нужно избегать повторного обновления, когда один объект обновляет другой, а этот другой будет опять обновляться
						* т.е. нужно только один раз обновлять
				+ параметр on/off update
			-? с помощью thread
				* скорее всего не получится
	]
--]]

local ClassParent = require('code.Class')  -- [code.Class](+F:\Documents\MyGameDevelopment\LOVE\TDS\code\Class.lua)
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end

-- optimization
--local math = math

-- variables static private ########################################################################
-- ...

-- variables static protected, only in Class #######################################################
ThisModule._modGraph = require("code.graphics")
ThisModule._damage = {}
ThisModule._damage.on = false

-- variables static public #########################################################################
ThisModule.modPhys = require("code.physics")
ThisModule.image = false																														-- <LOVE2D image> or false; @todo -? назначить стандартное изображение тут
ThisModule.sprite = false
ThisModule.quad = false																															-- <LOVE2D quad> or false
ThisModule.z = 0
ThisModule.drawable = true
ThisModule.alive = false
ThisModule.mobility = 'static' or 'dynamic' or 'stationary'																						-- |readonly!!!|; @todo - optimization memory этой переменной
ThisModule.shadows = {}
ThisModule.shadows.on = true
ThisModule.shadows.directional = {}                                                                                                             -- для придания наглядности глубины; тени на земле для вида глубины Z
ThisModule.shadows.directional.on = true
ThisModule.shadows.directional.z = 0
ThisModule.debug = {}
ThisModule.debug.on = true
ThisModule.debug.draw = {}
ThisModule.debug.draw.on = true
ThisModule.debug.draw.phys = {}
ThisModule.debug.draw.phys.on = true
ThisModule.saved = false
ThisModule.entityName = ThisModule._myClassName                                                                                                 -- -?NO убрать заглавные буквы из имени, т.к. заглавные буквы только для класса (не важно, т.к. это не код, а просто строка)
ThisModule.allowToSave = true
ThisModule.mass = 0
ThisModule.width = 0
ThisModule.height = 0
ThisModule.health = 100                                                                                                                         -- <number> = 0 ... 100
ThisModule.allowUpdate = true                                                                                                                   -- see world:update()

-- methods static private ##########################################################################
-- ...

-- methods static protected ########################################################################
-- ...

-- methods static public ###########################################################################

--[[
	* @arg arg <table> <nil> (default <nil>) = [ 
		* @arg arg.x <number> <nil> (default 0)
		* @arg arg.y <number> <nil> (default 0)
		* @arg arg.angle <number> <nil> = 0 ... 360 (babylons-degrees) (default 0)
		* @arg arg.mobility <string> <nil> = 'static' or 'dynamic' or 'stationary' (default 'static')
		* @arg arg["shadows.on"] <boolean> <nil> (default true)
		* @arg arg.entityName <string> <nil> (default className)
		* @arg arg.saved <boolean> <nil> (default false)
		* @arg arg.physics <table> <nil> (default <nil>) = 
			* @arg arg.physics.bodyType <string> <nil> = 'kinematic' (default <nil>)
	]
	* @return <object>
	* @todo 
		-?NO arg.physics.sensor
			* т.к. тут не создается fixture, которая назначается сенсором
--]]
function ThisModule:newObject(arg)                            -- @usage Class:newObject({x = 0, y = 0, angle = 0, mobility = 'dynamic', ["shadows.on"] = true, entityName = 'entity', saved = false, physics = {bodyType = 'kinematic'}})  -- @return <object>
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	-- nonstatic variables, methods ================================================================
	
	object.saved = arg.saved
	object.drawable = self.drawable
	object.alive = false
	if type(arg.mobility) == 'string' and (arg.mobility == 'static' or arg.mobility == 'dynamic' or arg.mobility == 'stationary') then
		object.mobility = arg.mobility
	end
	object.shadows = {}
	if type(arg["shadows.on"]) == 'boolean' then
		object.shadows.on = arg["shadows.on"]
	else
		object.shadows.on = true
	end
	object.shadows.directional = {}                                                                                                             -- для придания наглядности глубины; тени на земле для вида глубины Z
	object.shadows.directional.on = true
	object.shadows.directional.z = 0
	object.debug = {}
	object.debug.on = true
	object.debug.draw = {}
	object.debug.draw.on = true
	object.debug.draw.phys = {}
	object.debug.draw.phys.on = true	
	
	require("code.physics"):newWorld()
	object.physics = {}
	object.physics.bodyType = (arg.physics or {}).bodyType or object.mobility
	if object.mobility == 'stationary' then
		object.physics.bodyType = 'static'
	end
	object.physics.body = love.physics.newBody(require("code.physics").world, arg.x or 0, arg.y or 0, object.physics.bodyType)
	object.physics.body:setUserData(object)
	if arg.angle then
		object:setAngle(arg.angle)
	end
--	print(object.physics.body:getLinearDamping())
	object.physics.body:setLinearDamping(10)
	object.physics.body:setAngularDamping(10)	

	local world = require("code.world")
	if not world.EntityClasses[self._myClassName] then world.EntityClasses[self._myClassName] = self end
	
	self.entityName = self._myClassName                                                                                                         -- -?NO убрать заглавные буквы из имени, т.к. заглавные буквы только для класса (не важно, т.к. это не код, а просто строка)
	if type(arg.entityName) == 'string' then
		object.entityName = arg.entityName..' '.. self:getObjectsCount()
	end
	object.entityName = self._myClassName..' '.. self:getObjectsCount()                                                                         -- |debug!!!| 
	
	-- чтобы создать entity сначала нужно создать worldEditor.ui, иначе никак
	object.worldEditorUILEIWItem = require("code.worldEditor").ui.entitiesInWorld:insertItem({                                                   -- worldEditorUIListEntityInWorldItem
			name = object.entityName ..  [[ (]] .. tostring(object) .. [[)]],  
			func = function()
				require("code.worldEditor").select:selectEntity(object)
			end
	})
	
	return object
end

function ThisModule:setMiddle()
	
end

-- @return <number> = 0 ... 360 (babylons-degrees)
function ThisModule:getAngle()
	if self.destroyed then self:destroyedError() end
	
	return math.radToBDeg(self.physics.body:getAngle())
end

-- @arg angle <number> = 0 ... 360 (babylons-degrees)
function ThisModule:setAngle(angle)
	if self.destroyed then self:destroyedError() end
	
	return self.physics.body:setAngle(math.bDegToRad(angle))
end

-- * not done, not used
-- @return table
function ThisModule:getLinksToAllPublicVars()
	if self.destroyed then self:destroyedError() end
	
	local pv = {}
	pv.z = true
	pv.drawable = true
	pv.alive = true
	pv.mobility = true
	pv.shadows = {}
	pv.shadows.on = true
	pv.debug = {}
	pv.debug.on = true
	pv.debug.draw = {}
	pv.debug.draw.on = true
	pv.debug.draw.phys = {}
	pv.debug.draw.phys.on = true
	
	return pv
end

-- for worldEditor
-- @arg listUI <object> = UI.List
function ThisModule:editInUIList(listUI)
	if self.destroyed then self:destroyedError() end
	
	local wE = require("code.worldEditor")
	wE:setItemListEditEntityFunc(listUI, self, self.entityName, 'entityName', function(var) self:setEntityName(var); print(type(self.entityName)); return self.entityName end)
	wE:setItemListEditEntityFunc(listUI, self, self:getX(), 'x', function(var) self:setPosition(var) end)
	wE:setItemListEditEntityFunc(listUI, self, self:getY(), 'y', function(var) self:setPosition(nil, var) end)
	wE:setItemListEditEntityFunc(listUI, self, self:getAngle(), 'angle', function(var) self:setAngle(var); return self:getAngle() end)
	wE:setItemListEditEntityFunc(listUI, self, self.drawable, 'drawable', function(var) self.drawable = var; return self.drawable end)
	wE:setItemListEditEntityFunc(listUI, self, self.mobility, 'mobility', function(var) self:setMobility(var); return self.mobility end)
	wE:setItemListEditEntityFunc(listUI, self, self.shadows.on, 'shadows.on', function(var) self.shadows.on = var; return self.shadows.on end)
	wE:setItemListEditEntityFunc(listUI, self, self.debug.on, 'debug.on', function(var) self.debug.on = var; return self.debug.on end)
end

-- @arg x, y <number> <nil>
-- @example: setPosition(nil, y)
function ThisModule:setPosition(x, y)
	if self.destroyed then self:destroyedError() end
	
	if type(x) == 'number' then self.physics.body:setX(x); --[[self.x = x--]] end
	if type(y) == 'number' then self.physics.body:setY(y); --[[self.y = y--]] end
end

-- @return x, y <number>
function ThisModule:getPosition()
	if self.destroyed then self:destroyedError() end
	
	return self.physics.body:getPosition()
end

-- @return x <number>
function ThisModule:getX()
	if self.destroyed then self:destroyedError() end
	
	return self.physics.body:getX()
end

-- @return y <number>
function ThisModule:getY()
	if self.destroyed then self:destroyedError() end
	
	return self.physics.body:getY()
end

function ThisModule:destroy()
	if self.destroyed then return false end
	
	if type(self) == 'object' then
		for i, fixture in ipairs(self.physics.body:getFixtureList()) do
			fixture:setUserData(nil)
		end
		
		self._modGraph.zDBEL:deleteEntity(self)                                                                                                 -- для отображаемых
		self.physics.body:setUserData(nil)                                                                                                      -- ОБЯЗАТЕЛЬНО, чтобы не было утечки памяти !!!
		self.physics.body:destroy()
		require("code.worldEditor").ui.entitiesInWorld:removeItem(self.worldEditorUILEIWItem.position)
	elseif type(self) == 'class' then
		local world = require("code.world")
		if world.EntityClasses[self._myClassName] then world.EntityClasses[self._myClassName] = nil end		
	end
	
	ClassParent.destroy(self)
end

-- @return <true> <nil> (true if entity.health == 0)
function ThisModule:damage(value)
	if self.destroyed then return false end
	if not self._damage.on then return nil end
	
	self.health = self.health - value
	if self.health <= 0 then
		self.health = 0
		
--		self:destroy()
		return true
	end
end

--[[
	* @arg arg <table> = 
		* @arg arg.x <number> <nil>
		* @arg arg.y <number> <nil>
		* @arg arg.angle <number> <nil> (in rad)
		* @arg arg.likeShadow <boolean> (default = nil)
		* @arg arg.debug <boolean> (default = nil)
		* @arg arg.shadowsDirectional <boolean> (default = nil)                                                                                      -- not done !!!
	* "тяжелый"
	@todo 
		-? rename arg.debug to arg.debugOnly
		-?NO arg.drawFunction, чтобы рисовать софтверную графику
			* можно просто создать новый Класс с новым методом draw()
--]]
--local love = love                                                                                                                                -- влияние на скорость не замечено
function ThisModule:draw(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	if (not arg.debug) and (self.image or self.mesh or self.sprite) and self.drawable then
--		local scale = 1
		local shadowsDirectionalCoordsAdd  = {}                             -- simpleShadowCoords additional
		shadowsDirectionalCoordsAdd.x, shadowsDirectionalCoordsAdd.y = 0, 0
		if arg.likeShadow then
			love.graphics.setColor(0, 0, 0, 255)
--			scale = 0.9                                                                                                                            -- "не теневая" рамка у объектов, чтобы было видно стенки объектов; не очень правильно
		elseif arg.shadowsDirectional and self.shadows.directional.on then                                                                                                            -- not done !!!
			love.graphics.setColor(0, 0, 0, 100)
			shadowsDirectionalCoordsAdd.x, shadowsDirectionalCoordsAdd.y = 3+(self.shadows.directional.z*3), 3+(self.shadows.directional.z*3)
--			scale = 1.2
		else
			love.graphics.setColor(255, 255, 255, 255)
		end
		
		local x, y
		if arg.x and arg.y then
			x, y = arg.x+shadowsDirectionalCoordsAdd.x, arg.y+shadowsDirectionalCoordsAdd.y
		else
			x, y = self.physics.body:getX()+shadowsDirectionalCoordsAdd.x, self.physics.body:getY()+shadowsDirectionalCoordsAdd.y
		end
		
		
		if self.image and (not self.mesh)then
			love.graphics.draw(self.image, x, y, arg.angle or self.physics.body:getAngle(), scale or 1, scale or 1, arg.originX or self.image:getWidth()/2, arg.originY or self.image:getHeight()/2)
--			if arg.shadowsDirectional and self.shadows.directional.on then
--				x, y = self.physics.body:getX()-shadowsDirectionalCoordsAdd.x, self.physics.body:getY()-shadowsDirectionalCoordsAdd.y
--				love.graphics.draw(self.image, x, y, arg.angle or self.physics.body:getAngle(), scale or 1, scale or 1, self.image:getWidth()/2, self.image:getHeight()/2)		
--			end
		elseif self.mesh then
			love.graphics.draw(self.mesh, x, y, self.physics.body:getAngle(), scale or 1, scale or 1)
--			if arg.shadowsDirectional and self.shadows.directional.on then
--				x, y = self.physics.body:getX()-shadowsDirectionalCoordsAdd.x, self.physics.body:getY()-shadowsDirectionalCoordsAdd.y
--				love.graphics.draw(self.mesh, x, y, self.physics.body:getAngle(), scale or 1, scale or 1)
--			end			
		elseif self.sprite and (not self.image) then
			self.sprite.transform.position.x = x
			self.sprite.transform.position.y = y
--			self.sprite.transform.angle = arg.angle or self.sprite.transform.angle or self.physics.body:getAngle()
			self.sprite.transform.scale.x = scale or self.sprite.transform.scale.x
			self.sprite.transform.scale.y = scale or self.sprite.transform.scale.y
			self.sprite.transform.origin.x = arg.originX or self.sprite.transform.origin.x
			self.sprite.transform.origin.y = arg.originY or self.sprite.transform.origin.y
			self.sprite:draw({
				angle = arg.angle or self.physics.body:getAngle()+self.sprite.transform.angle
			})
--			love.graphics.draw(self.sprite, x, y, arg.angle or self.physics.body:getAngle(), scale or self.sprite.transform.scale.x, scale or self.sprite.transform.scale.y, 
--			  arg.originX or self.sprite.origin.x, arg.originY or self.sprite.origin.y)
		end
	end
	
	if arg.debug and (not arg.likeShadow) and debug:isOn() and debug.draw:isOn() and self.modPhys.debug:isOn() and self.modPhys.debug.draw:isOn() and self.debug.on and self.debug.draw.on and self.debug.draw.phys.on then
		local fixtures = self.physics.body:getFixtureList()
		local bodyType = self.physics.body:getType()
		for i=1, #fixtures do
			local fixture = fixtures[i]
			local shape = fixture:getShape()
			
			if self.modPhys.debug.draw.bbox:isOn() then
				local topLeftX, topLeftY, bottomRightX, bottomRightY = fixture:getBoundingBox(1)
				if self.physics.body:isAwake() then 
					love.graphics.setColor(0, 255, 255, 100)
				else 
					love.graphics.setColor(0, 255, 255, 50) 
				end
				love.graphics.rectangle("fill", topLeftX, topLeftY, bottomRightX-topLeftX, bottomRightY-topLeftY)
--				love.graphics.rectangle("line", topLeftX, topLeftY, bottomRightX-topLeftX, bottomRightY-topLeftY)
			end
			
			if self.modPhys.debug.draw.body:isOn() then
				local color = self.modPhys.debug.drawColor.body[bodyType]
				if self.physics.body:isAwake() then 
					love.graphics.setColor(color[1], color[2], color[3], color[4]) 
				else 
					love.graphics.setColor(color[1], color[2], color[3], color[4]-100) 
				end
				if shape:getType() == "circle" then
					local x, y = self.physics.body:getWorldPoints(shape:getPoint())
					love.graphics.circle("fill", x, y, shape:getRadius())
					love.graphics.circle("line", x, y, shape:getRadius())
				elseif shape:getType() == "polygon" then
					love.graphics.polygon("fill", self.physics.body:getWorldPoints(shape:getPoints()))
					love.graphics.polygon("line", self.physics.body:getWorldPoints(shape:getPoints()))
				end
				
				-- direction
				local dx, dy = self.physics.body:getWorldPoint(10, 0)
				love.graphics.setColor(200, 0, 0, 255)
				love.graphics.circle("fill", self.physics.body:getX(), self.physics.body:getY(), 2)
				love.graphics.line(self.physics.body:getX(), self.physics.body:getY(), dx, dy)
			end
		end
	end
	
	-- test text
--	if arg.debug and debug:isOn() and debug.draw:isOn() then
--		x, y = self.physics.body:getPosition()
--		love.graphics.setColor(255, 0, 0, 255)
--		love.graphics.print(tostring(self), x, y)
--	end
	
	return true
end

-- @return <string>
function ThisModule:getSavedLuaCode()
	if self.destroyed then self:destroyedError() end
	
	-- одна строка = один entity
	local saveString = ''
	if rawget(self, 'entityName') then
		saveString = saveString..[[entityName = ]]..[["]]..tostring(self.entityName)..[["]]..", "
	end
	saveString = saveString..[[x = ]]..tostring(self.physics.body:getX())
	saveString = saveString..", "..[[y = ]]..tostring(self.physics.body:getY())
	if self:getAngle() ~= 0 then
		saveString = saveString..", "..[[angle = ]]..tostring(self:getAngle())
	end
	if rawget(self, 'mobility') then
		saveString = saveString..", "..[[mobility = ]]..[["]]..tostring(self.mobility)..[["]]
	end
	if not self.shadows.on then
		saveString = saveString..", "..[[["shadows.on"] = ]]..tostring(self.shadows.on)
	end		
	if self.saved then
		saveString = saveString..", "..[[saved = ]]..tostring(self.saved)
	end	

	return saveString
end

-- @arg mobility <string> = 'static' or 'dynamic' or 'stationary'
function ThisModule:setMobility(mobility)
	if self.destroyed then self:destroyedError() end
	
	if type(mobility) ~= 'string' or (mobility ~= 'static' and mobility ~= 'dynamic' and mobility ~= 'stationary') then
		error('')
	end
	self.mobility = mobility
	
	if mobility == 'stationary' then
		mobility = 'static'
	end	
	self.physics.body:setType(mobility)
end

-- @arg newName <string>
function ThisModule:setEntityName(newName)
	if self.destroyed then self:destroyedError() end
	
	if type(newName) ~= 'string' then
		error('')
	end
	
	self.entityName = newName
	self.worldEditorUILEIWItem.name = self.entityName
end

--[[
	*!!! чтобы Энтити обновлялась нужно:
		* allowUpdate = true
		* добавить в класс минимум пустой метод update() (смотри code.world:update())
--]]
function ThisModule:update(arg)
	if self.destroyed then self:destroyedError() end
	
--	print('test')
end

return ThisModule