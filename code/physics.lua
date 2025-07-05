--[[
version 0.0.7
@help 
	* мир в Box2D измеряется в метрах, а не в пикселях !!!
	* только один world
	* multithread не доступно, в отличие от "Unity Physx"
@todo 
	- concave PolygonShape
	- Contact
	-? World:setContactFilter
	- World:isLocked
	- World:translateOrigin
	-+ World:setCallbacks
	@todo -+ фильтр колизий
		- Fixture:setFilterData
		- Fixture:setCategory
		- Fixture:setMask
		- Fixture:setGroupIndex
		- http://box2d.org/manual.pdf
		- http://www.iforce2d.net/b2dtut/collision-filtering
		- структура
	- physicsShapeEditor
	- profiling
		- график задержки
	- config
		- пауза
	- debug
		- World:getContactCount
		- World:getJointCount		
		-+ draw
			+ angle линией от центра объекта
			-? bbox и body рисовать отдельными слоями
				- bbox рисовать выше body
			+ для всех shape in body
			+ body
				+ отдельный параметр
			+ bbox
				+ отдельный параметр
			+ разные цвета для разных типов body
				+ цвета для рисования хранить тут
	-? box2d particles
		* http://google.github.io/liquidfun/
			* https://bitbucket.org/rude/love/issues/1195/update-replace-box2d-with-liquidfun
	@todo 1 -+? optimization multithread world:update()
		- вынести физику в другой один thread
]]

local thisModule = {}
thisModule.world = false

local debug = {}
debug.on = config.debug.physics.on or false
debug.draw = {}
debug.draw.on = config.debug.physics.draw.on or false
debug.draw.body = {}
debug.draw.body.on = config.debug.physics.draw.body.on or false
debug.draw.bbox = {}
debug.draw.bbox.on = config.debug.physics.draw.bbox.on or false
debug.chart = {}
debug.chart.on = false
debug.chart.bodyCount = {}
debug.chart.bodyCount.on = false

-- test thread

--function love.threaderror(thread, errorstr)
--  print("Thread error!\n"..errorstr)
--  -- thread:getError() will return the same error string now.
--end
--thisModule.thread = love.thread.newThread("\n" .. [[
--	print('hi from thread', ...)
	
--	require('love.physics')
--	require('love.timer')
	
--	thisChannel = love.thread.getChannel("physics")
	
--	while true do
--		pop = thisChannel:pop()
		
--		if pop ~= nil then
--			physicsWorld = pop.physicsWorld
--			dt = pop.dt
--		end
		
--		if physicsWorld and physicsWorld.typeOf and physicsWorld:typeOf('World') and (not physicsWorld:isDestroyed()) and not physicsWorld:isLocked() then
--			physicsWorld:update(dt or 0)
--		end
--		print('thread physicsWorld:update()', physicsWorld, dt)
----		love.timer.sleep(1)
--	end
--]])
--thisModule.channel = love.thread.getChannel("physics")
----thisModule.thread:start()

local fixture1GetUserData = false
local fixture2GetUserData = false
function thisModule:newWorld()
	if not thisModule.world then
		thisModule.world = love.physics.newWorld(0, 0, true)
--		thisModule.world:setSleepingAllowed(false)
		
		----[[ setCallbacks ---------------------------------------------------------------------
		--[=[
			@todo -+ rename func.beginContact to:
				-? onPhysBeginContact
				-? callbackPhysBeginContact
				-? callPhysBeginContact
					- in code.cound
				+?YES physWorldCallbackFunc.beginContact
				-? physCallbackFunc.beginContact
		--]=]
		local function beginContact(fixture1, fixture2, contact)
--			print(os.clock(), 'beginContact')
--			print(os.clock(), contact:getNormal())
--			print(os.clock(), contact:getFriction())
			
			fixture1GetUserData = fixture1:getUserData()
			fixture2GetUserData = fixture2:getUserData()
			if fixture1GetUserData and fixture1GetUserData.physCallbackFunc and fixture1GetUserData.physCallbackFunc.beginContact then
				fixture1GetUserData.physCallbackFunc.beginContact(fixture1, fixture2, contact)
			end
			if fixture2GetUserData and fixture2GetUserData.physCallbackFunc and fixture2GetUserData.physCallbackFunc.beginContact then
				fixture2GetUserData.physCallbackFunc.beginContact(fixture2, fixture1, contact)
			end
		end
		local function endContact(fixture1, fixture2, contact)  -- not done
--			print('endContact', os.clock())
			fixture1GetUserData = fixture1:getUserData()
			fixture2GetUserData = fixture2:getUserData()
			if fixture1GetUserData and fixture1GetUserData.func and fixture1GetUserData.func.endContact then
				fixture1GetUserData.func.endContact(fixture1, fixture2, contact)
			end
			if fixture2GetUserData and fixture2GetUserData.func and fixture2GetUserData.func.endContact then
				fixture2GetUserData.callbackFunc.endContact(fixture1, fixture2, contact)
			end				
		end
		local function preSolve(fixture1, fixture2, contact)
--			print(os.clock(), 'preSolve')
			fixture1GetUserData = fixture1:getUserData()
			fixture2GetUserData = fixture2:getUserData()
			if fixture1GetUserData and fixture1GetUserData.physCallbackFunc and fixture1GetUserData.physCallbackFunc.preSolve then
				fixture1GetUserData.physCallbackFunc.preSolve(fixture1, fixture2, contact)
			end
			if fixture2GetUserData and fixture2GetUserData.physCallbackFunc and fixture2GetUserData.physCallbackFunc.preSolve then
				fixture2GetUserData.physCallbackFunc.preSolve(fixture2, fixture1, contact)
			end			
		end
		local function postSolve(fixture1, fixture2, contact, normalImpulse1, tangentImpulse1, normalImpulse2, tangentImpulse2)
--			print(os.clock(), 'postSolve')
			fixture1GetUserData = fixture1:getUserData()
			fixture2GetUserData = fixture2:getUserData()
			if fixture1GetUserData and fixture1GetUserData.physCallbackFunc and fixture1GetUserData.physCallbackFunc.postSolve then
				fixture1GetUserData.physCallbackFunc.postSolve(fixture1, fixture2, contact, normalImpulse1, tangentImpulse1, normalImpulse2, tangentImpulse2)
			end
			if fixture2GetUserData and fixture2GetUserData.physCallbackFunc and fixture2GetUserData.physCallbackFunc.postSolve then
				fixture2GetUserData.physCallbackFunc.postSolve(fixture2, fixture1, contact, normalImpulse1, tangentImpulse1, normalImpulse2, tangentImpulse2)
			end			
		end	
		
		-- !!! в static    сенсоре beginContact, endContact работает только для неспящих dynamic тел
		-- !!! в kinematic сенсоре beginContact, endContact работает только для спящих и неспящих dynamic тел, только когда он не спит
		-- !!! в dynamic   сенсоре beginContact, endContact работает для всех тел, только когда он не спит
		thisModule.world:setCallbacks( beginContact, endContact, preSolve, postSolve )

		--print(thisModule.world, thisModule.world:getCallbacks())
		--]] ---------------------------------------------------------------------
--		print('new phys world create')
		
		
		-- test thread		
--		thisModule.channel:push({physicsWorld=thisModule.world, dt=love.timer.getDelta()})
		
	end
end

--love.physics.setMeter(1)																														-- @todo - окончательно определиться с этим, от этого зависит степень скорости передвижения boby по экрану; default=30
thisModule:newWorld()

function thisModule:destroyWorld()
	if thisModule.world then
		thisModule.world:destroy()
		thisModule.world = false
	end
end

--[[
@help 
	+ "тяжелый" №1, чем больше body, тем больше задержка
TODO:
	+ оптимизация
		@help "большой пропуск" влияет на физику
		+ задержка между обновлениями
			- вынести в отдельный класс или пример-шаблон
			- задержка через каждое x время
--]]
thisModule.skip = {}
thisModule.skip.counterDo = 0																													-- 0
thisModule.skip.doMax = 1																														-- 1...~; выполнять минимум 1 раз
thisModule.skip.counterSkip = 0																													-- 0
-- +INFO!!! эту оптимизацию пока отключаем; require("code.physics").skip.skipMax = 0, сейчас нужно работать с кодом с таким значением; смотри code...Humanoid
thisModule.skip.skipMax = 0																														-- 0...1; чем меньше, тем плавнее физика выглядит, чем больше - тем рывко-образнее физика; если изменять внешне, то может случиться баг: мир перестанет обновляться !!!
thisModule.skip.skiped = false																													-- чтобы во время пропуска можно было выполнять другой код
thisModule.skip.counterDt = love.timer.getTime()
thisModule.skip.counterDtLast = 0
thisModule.debugTimer = {}
thisModule.debugTimer.start = 0
thisModule.debugTimer.result = 0
thisModule.dt = {}
thisModule.dt.past = 0
thisModule.worldUpdateTime = {}
thisModule.worldUpdateTime.last = 0
thisModule.worldUpdateTime.dangerCount = 0

function thisModule:update(dt)
	if not thisModule.world then return false end
	
	if thisModule.collision.worldRayCast.test.on then
		thisModule.collision.worldRayCast.test:update(dt)
	end
	
	if self.skip.counterDo == self.skip.doMax then
		if not (self.skip.counterSkip == self.skip.skipMax) then			
			self.skip.counterSkip = self.skip.counterSkip+1
			self.skip.skiped = true
			self.skip.counterDt = self.skip.counterDtLast+(love.timer.getTime()-self.skip.counterDt)
			self.skip.counterDtLast = self.skip.counterDt
			self.skip.counterDt = love.timer.getTime()
			return false 
		end
		self.skip.counterDo = 0
	end

	self.skip.counterDt = (love.timer.getTime()-self.skip.counterDt)+self.skip.counterDtLast
	self.skip.counterDtLast = 0
	local counterDt = self.skip.counterDt
	self.skip.counterDt = love.timer.getTime()
	
	self.debugTimer.start = love.timer.getTime()
	--========== main code
--	if thisModule.world then self.world:update(counterDt) end

	----[[ test stabilisation
	local updateAllowed = true
	local dtUpdate = dt
	--[[ smooth, вроде нету разницы с ней
	if dt - thisModule.dt.past > 0.001 then
		dtUpdate = (thisModule.dt.past+dt)/2
		print(os.clock(), 'physics stabilisation, smooth deltaTime surge', dt - thisModule.dt.past)
	end	
	--]]	
	if dt > 0.04 then
		dtUpdate = 0.04
		print(os.clock(), 'physics stabilisation')
	end
	if thisModule.worldUpdateTime.dangerCount > 50 then
		updateAllowed = false
		print(os.clock(), 'warning! physics not update, do not have enough processor power')
	end
--	if thisModule.worldUpdateTime.dangerCount > 5 then print(thisModule.worldUpdateTime.last)  end
	thisModule.dt.past = dt
	if thisModule.world and updateAllowed then self.world:update(dtUpdate) end   -- simple
	--]]
	
--	print('debug: physics world update', dt, thisModule.worldUpdateTime.last, updateAllowed)
	--==========
	self.debugTimer.result = love.timer.getTime()-self.debugTimer.start	
	
	thisModule.worldUpdateTime.last = self.debugTimer.result                                        -- @todo - вынести в debug.chart
	if thisModule.worldUpdateTime.last > 0.05 then
		thisModule.worldUpdateTime.dangerCount = thisModule.worldUpdateTime.dangerCount + (thisModule.worldUpdateTime.last/0.05)
		if thisModule.worldUpdateTime.dangerCount > 51 then thisModule.worldUpdateTime.dangerCount = 51 end
	end
	
	self.skip.counterDo = self.skip.counterDo+1
	self.skip.counterSkip = 0	
	self.skip.skiped = false
end

thisModule.debug = {}

function thisModule.debug:isOn()
	return debug.on
end

function thisModule.debug:on()
	debug.on = true
--	debug.draw.on = true
--	debug.draw.bbox.on = true
--	debug.draw.body.on = true	
--	debug.chart.on = true
--	debug.chart.bodyCount.on = true
end

function thisModule.debug:off()
	debug.on = false
--	debug.draw.on = false
--	debug.draw.bbox.on = false
--	debug.draw.body.on = false
--	debug.chart.on = false
--	debug.chart.bodyCount.on = false
end

function thisModule.debug:toggle()
	if debug.on then
		self:off()
	else
		self:on()
	end
end

thisModule.debug.draw = {}
thisModule.debug.drawColor = {}
thisModule.debug.drawColor.body = {}
thisModule.debug.drawColor.body.static = {0, 155, 0, 220}
thisModule.debug.drawColor.body.dynamic = {255, 128, 0, 220}
thisModule.debug.drawColor.body.kinematic = {50, 50, 255, 220}

function thisModule.debug.draw:isOn()
	return debug.draw.on
end

function thisModule.debug.draw:on()
	debug.draw.on = true
end

function thisModule.debug.draw:off()
	debug.draw.on = false
end

function thisModule.debug.draw:toggle()
	if debug.draw.on then
		self:off()
	else
		self:on()
	end
end

thisModule.debug.draw.bbox = {}

function thisModule.debug.draw.bbox:isOn()
	return debug.draw.bbox.on
end

function thisModule.debug.draw.bbox:on()
	debug.draw.bbox.on = true
end

function thisModule.debug.draw.bbox:off()
	debug.draw.bbox.on = false
end

function thisModule.debug.draw.bbox:toggle()
	if debug.draw.bbox.on then
		self:off()
	else
		self:on()
	end
end

thisModule.debug.draw.body = {}

function thisModule.debug.draw.body:isOn()
	return debug.draw.body.on
end

function thisModule.debug.draw.body:on()
	debug.draw.body.on = true
end

function thisModule.debug.draw.body:off()
	debug.draw.body.on = false
end

function thisModule.debug.draw.body:toggle()
	if debug.draw.body.on then
		self:off()
	else
		self:on()
	end
end

-- collision #######################################################################################
--[[
@todo 
	-NO return entitys table, not fixtures
	- to new module
	- optimisation
--]]

thisModule.collision = {}

local collision = {}
collision.fixtures = {}
collision.objectClassNameFilter = false																										-- ClassName; string or false
collision.fixtureFilterFunc = false
collision.funcDo = false
collision.hc = {}
collision.hc.moduleShapes = require("code.hardoncollider.shapes")
collision.hc.test = {}
function collision.queryBoundingBoxCallback(fixture)
	local shapeType = fixture:getShape():getType()
	if shapeType == "polygon" then
		collision.hc.test.shapeFixture = collision.hc.moduleShapes.newPolygonShape(fixture:getBody():getWorldPoints(fixture:getShape():getPoints()))
	elseif shapeType == "circle" then
		local x, y = fixture:getBody():getWorldPoint(fixture:getShape():getPoint())
		collision.hc.test.shapeFixture = collision.hc.moduleShapes.newCircleShape(x, y, fixture:getShape():getRadius())		
	end

	if collision.hc.test.shapeFixture:collidesWith(collision.hc.test.collidesWithShape) then															-- @todo + проверять коллизию прямоугольника и fixture
		local pass = true
		
		if collision.objectClassNameFilter then
			local object = fixture:getBody():getUserData()
			if not (object._TABLETYPE == "object" and (not object.destroyed) and collision.objectClassNameFilter == object:getClassName()) then
				pass = false
			end
		end
		
		if collision.fixtureFilterFunc then
			if not collision.fixtureFilterFunc(fixture) then
				pass = false
			end
		end
		
		if pass then
			collision.fixtures[#collision.fixtures+1] = fixture
			if collision.funcDo then collision.funcDo(fixture) end
		end
		
	end
	
	return true
end

function collision.queryBoundingBoxCallbackFast(fixture)

	local pass = true
	
	if collision.objectClassNameFilter then
		local object = fixture:getBody():getUserData()
		if not (object._TABLETYPE == "object" and (not object.destroyed) and collision.objectClassNameFilter == object:getClassName()) then
			pass = false
		end
	end
	
	if collision.fixtureFilterFunc then
		if not collision.fixtureFilterFunc(fixture) then
			pass = false
		end
	end
	
	if pass then
		collision.fixtures[#collision.fixtures+1] = fixture
		if collision.funcDo then collision.funcDo(fixture) end
	end
	
	return true
end

-- x1, y1 - top-left; x2, y2 - low-right
-- funcDo = function(fixture)  end
-- fixtureFilterFunc = function(fixture) ... return true or false end
-- return <table> of all fixtures or false
-- @todo -?NO body лист исключений
--       @help используй fixtureFilterFunc
function thisModule.collision.rectangle(x1, y1, x2, y2, objectClassNameFilter, fixtureFilterFunc, funcDo)
	if thisModule.world then
		collision.fixtures = {}																										 -- local !!!
		collision.objectClassNameFilter = objectClassNameFilter or false
		collision.fixtureFilterFunc = fixtureFilterFunc or false
		collision.funcDo = funcDo or false
		
		-- для избежания ошибки в require("code.hardoncollider.shapes").newPolygonShape()
		if (x2-x1) == 0 then
			x2 = x1+0.00001
		end
		if (y2-y1) == 0 then
			y2 = y1+0.00001
		end
		
		-- @todo -? если "точка", то newPointShape()
		collision.hc.test.collidesWithShape = collision.hc.moduleShapes.newPolygonShape(x1, y1, x2, y1, x2, y2, x1, y2)		
		thisModule.world:queryBoundingBox(x1, y1, x2, y2, collision.queryBoundingBoxCallback)
		collision.hc.test.collidesWithShape = false
	end
	
	if #collision.fixtures ~= 0 then
		return collision.fixtures
	else
		return false
	end
end

-- намного быстрее, но точность хуже, колизия определяется по AABB
function thisModule.collision.rectangleFast(x1, y1, x2, y2, objectClassNameFilter, fixtureFilterFunc, funcDo)
	if thisModule.world then
		collision.fixtures = {}																										 -- local !!!
		collision.objectClassNameFilter = objectClassNameFilter or false
		collision.fixtureFilterFunc = fixtureFilterFunc or false
		collision.funcDo = funcDo or false
		
		-- для избежания ошибки в require("code.hardoncollider.shapes").newPolygonShape()
		if (x2-x1) == 0 then
			x2 = x1+0.00001
		end
		if (y2-y1) == 0 then
			y2 = y1+0.00001
		end
		
		-- @todo -? если "точка", то newPointShape()	
		thisModule.world:queryBoundingBox(x1, y1, x2, y2, collision.queryBoundingBoxCallbackFast)
	end
	
	if #collision.fixtures ~= 0 then
		return collision.fixtures
	else
		return false
	end	
end

function thisModule.collision.circle(cx, cy, radius, objectClassNameFilter, fixtureFilterFunc, funcDo)
	if thisModule.world then
		collision.fixtures = {}																										 -- local !!!
		collision.objectClassNameFilter = objectClassNameFilter or false
		collision.fixtureFilterFunc = fixtureFilterFunc or false
		collision.funcDo = funcDo or false
		
		-- @todo -? если "точка", то newPointShape()
		collision.hc.test.collidesWithShape = collision.hc.moduleShapes.newCircleShape(cx, cy, radius)		
		thisModule.world:queryBoundingBox(cx-radius, cy-radius, cx+radius, cy+radius, collision.queryBoundingBoxCallback)
		collision.hc.test.collidesWithShape = false
	end
	
	if #collision.fixtures ~= 0 then
		return collision.fixtures
	else
		return false
	end
end

-- testing example, put in require("code.debug.ui"):

--local foo = function()
--	local wx, wy = camera:toWorld(love.mouse.getPosition())
--	local coll = require("code.physics").collision.rectangle(wx, wy, wx, wy)[1]
--	if tostring(coll) == "Fixture" then
--		return "collision.rectangle isAwake = "..tostring(coll:getBody():isAwake()--[[:getUserData():getClassName()--]])										-- string
--	else
--		return "collision.rectangle = ..."
--	end
--end
--debug.ui.watchList:insertItem({name="collision.rectangle = ...", func = foo})
----------------------------------------------------------------------------------------------------------------

--[[ rayCast =============================================================================================
	@todo +
		+- doc
			- @usage
			+ @example
				* see thisModule.collision.worldRayCast.test
		+ new worldRayCast:cast() (return list of hits)
			+ entity filters
		+ test update.on
		+ test draw.on
		+ контролер, чтобы координаты точек отрезка не совпадали
		+ сортировка ray.hits по длине fraction
--]]

thisModule.collision.worldRayCast = {}

thisModule.collision.worldRayCast.ray = {}
thisModule.collision.worldRayCast.ray.line = math.line()
thisModule.collision.worldRayCast.ray.hitList = {}
thisModule.collision.worldRayCast.ray.hitList.hitClosest = {}
thisModule.collision.worldRayCast.ray.hitList.hitClosest.fraction = math.huge

thisModule.collision.worldRayCast.objectClassNameFilter = false                                                                                                    -- ClassName; <string> or false; фильтр пропуска
thisModule.collision.worldRayCast.fixtureFilterFunc = false                                                                                                        -- фильтр пропуска (true - пропуск); fixtureFilterFunc(fixture, x, y, xn, yn, fraction) @return true or false
thisModule.collision.worldRayCast.funcDo = false                                                                                                                   -- funcDo(fixture, x, y, xn, yn, fraction)

thisModule.collision.worldRayCast.test = {}
thisModule.collision.worldRayCast.test.on = false
thisModule.collision.worldRayCast.test.ray = {}
thisModule.collision.worldRayCast.test.ray.line = math.line()
thisModule.collision.worldRayCast.test.ray.hitList = {}
thisModule.collision.worldRayCast.test.ray.hitList.hitClosest = {fraction=math.huge}

thisModule.collision.worldRayCast.test.filterNames = {
"Entity.Test1"
, "Entity.Test2"
, "Entity.TestRectangle"
, "Entity.Door"
, "Entity.Door.DoorWall"
, "Entity.Humanoid"
}
function thisModule.collision.worldRayCast.test._funcFilter(fixture, x, y, xn, yn, fraction)
	local pass = false
	local object = fixture:getBody():getUserData()
	if object._TABLETYPE == "object" and (not object.destroyed) and object ~= thisModule.entity and fixture:isSensor() == false then
		for i, v in ipairs(thisModule.collision.worldRayCast.test.filterNames) do
			if object:getClassName() == v then
				pass = true
			end
		end
	end
	
	return pass
end
function thisModule.collision.worldRayCast.test._funcDo(fixture, x, y, xn, yn, fraction)
	local entity = fixture:getBody():getUserData()
	if entity._TABLETYPE == "object" and (not entity.destroyed) then
		local force = math.vector(
			thisModule.collision.worldRayCast.ray.line.point2.x - thisModule.collision.worldRayCast.ray.line.point1.x,
			thisModule.collision.worldRayCast.ray.line.point2.y - thisModule.collision.worldRayCast.ray.line.point1.y
		):normalizeInplace() * 3
		entity.physics.body:applyLinearImpulse(force.x, force.y, x, y)
--		entity.physics.body:applyForce(force.x, force.y, x, y)
	end
end

--[[
	* The ray can be controlled with the return value. 
		* A positive value sets a new ray length where 1 is the default value. 
		* A value of 0 terminates the ray. 
		* If the callback function returns -1, the intersection gets ignored as if it didn't happen.
	@todo + type check objectClassNameFilter, fixtureFilterFunc, funcDo	
--]]
function thisModule.collision.worldRayCast.worldRayCastCallback(fixture, x, y, xn, yn, fraction)
	
	local pass = true
	if thisModule.collision.worldRayCast.objectClassNameFilter then
		assert(type(thisModule.collision.worldRayCast.objectClassNameFilter) == 'string', [[objectClassNameFilter must be <string> type, not ']]..type(thisModule.collision.worldRayCast.objectClassNameFilter)..[[' type]])
		local object = fixture:getBody():getUserData()
		if not (object._TABLETYPE == "object" and (not object.destroyed) and thisModule.collision.worldRayCast.objectClassNameFilter == object:getClassName()) then
			pass = false
		end
	end
	if thisModule.collision.worldRayCast.fixtureFilterFunc then
		assert(type(thisModule.collision.worldRayCast.fixtureFilterFunc) == 'function', [[fixtureFilterFunc must be <function> type, not ']]..type(thisModule.collision.worldRayCast.fixtureFilterFunc)..[[' type]])
		if not thisModule.collision.worldRayCast.fixtureFilterFunc(fixture, x, y, xn, yn, fraction) then
			pass = false
		end
	end
	if pass then
		local hit = {}
		hit.fixture = fixture
		hit.x, hit.y = x, y
		hit.xn, hit.yn = xn, yn
		hit.fraction = fraction
		
		table.insert(thisModule.collision.worldRayCast.ray.hitList, hit)
		
		if fraction < thisModule.collision.worldRayCast.ray.hitList.hitClosest.fraction then
			thisModule.collision.worldRayCast.ray.hitList.hitClosest = hit
		end		
		
		if thisModule.collision.worldRayCast.funcDo then
			assert(type(thisModule.collision.worldRayCast.funcDo) == 'function', [[funcDo must be <function> type, not ']]..type(thisModule.collision.worldRayCast.funcDo)..[[' type]])
			thisModule.collision.worldRayCast.funcDo(fixture, x, y, xn, yn, fraction)
		end
	end

	return 1
--	return -1
--	return fraction 
--	return 0
end

function thisModule.collision.worldRayCast.test:update(dt)
	self.ray.line.point1.x = camera.x
	self.ray.line.point1.y = camera.y
	self.ray.line.point2.x, self.ray.line.point2.y = camera:toWorld(love.mouse.getPosition())

--	if self.ray.line.point1 == self.ray.line.point2 then
--		self.ray.line.point2.x = self.ray.line.point2.x + 0.0001
--	end
	
	self.ray.hitList = thisModule.collision.worldRayCast:cast(self.ray.line, nil, thisModule.collision.worldRayCast.test._funcFilter, thisModule.collision.worldRayCast.test._funcDo)
end

-- @todo -+? сделать не тестовой, а стандартной функцией рисования любой ray
	-- * назначить thisModule.collision.worldRayCast.test.ray и рисовать
function thisModule.collision.worldRayCast.test:draw()
	love.graphics.setColor(255, 0, 0, 255)
    love.graphics.line(self.ray.line.point1.x, self.ray.line.point1.y, self.ray.line.point2.x, self.ray.line.point2.y)

    -- Drawing the intersection points and normal vectors if there were any.
     for i = 1, #self.ray.hitList do
         local hit = self.ray.hitList[i]
         love.graphics.setColor(255, 0, 0)
		 love.graphics.print(i, hit.x, hit.y)
         love.graphics.circle("line", hit.x, hit.y, 3)
         love.graphics.setColor(0, 255, 0)
         love.graphics.line(hit.x, hit.y, hit.x + hit.xn * 25, hit.y + hit.yn * 25)
     end
	
	if self.ray.hitList.hitClosest.fixture ~= nil then
		local hit = self.ray.hitList.hitClosest
		love.graphics.setColor(255, 255, 0)
--		love.graphics.print(self.ray.hitList.hitClosest.fraction, hit.x, hit.y+10)
		love.graphics.circle("line", hit.x, hit.y, 3)
		love.graphics.setColor(0, 255, 0)
		love.graphics.line(hit.x, hit.y, hit.x + hit.xn * 25, hit.y + hit.yn * 25)
	end
end

--[[------------------------------------------------------------------------------------------------
	* @arg line <line>
	* @arg objectClassNameFilter <string> <nil> (фильтр пропуска; @example 'Entity.Test1')
	* @arg fixtureFilterFunc <nil> <function> = 
		* 	function(fixture, x, y, xn, yn, fraction) 
				-- ...
				return true or false 
			end
		* фильтр пропуска (true - пропуск)
	* @arg funcDo <nil> <function> = 
		* 	function(fixture, x, y, xn, yn, fraction) 
				-- ...
			end	
		* выполняется для каждой hit
	* @arg sorted <boolean> <nil> (default true)
		* сортировка порядка точек в таблице по дальности, самая ближняя = [1], ..., без сортировки порядок в таблице в разнобой
	* @return <table> hitList = 
		[key <nil> <number> = 1 ... ] = 
			* [see World:rayCast callback function](https://www.love2d.org/wiki/World:rayCast#Callback)
			* fixture <fixture>
			* x <number> (global coordinate)
			* y <number> (global coordinate)
			* xn <number> = -1 ... 0 ... 1 (Unit vector; единичный вектор)
			* yn <number> = -1 ... 0 ... 1 (Unit vector; единичный вектор)
			* fraction <number> = 0 ... 1 ...	
		* hitClosest <table> =
			* fraction <number> = 0 ... 1 ...
--]]------------------------------------------------------------------------------------------------
function thisModule.collision.worldRayCast:cast(line, objectClassNameFilter, fixtureFilterFunc, funcDo, sorted)
	assert(type(line) == 'line', [[argument1 line must be 'line' type, not ']]..type(line)..[[' type]])
	
	self.ray.line = line
	self.ray.hitList = {}
	self.ray.hitList.hitClosest = {fraction=math.huge}
	
	local antibug = 0
	if line.point1 == line.point2 then
		antibug = 0.0001
	end
	
	self.objectClassNameFilter = objectClassNameFilter
	self.fixtureFilterFunc = fixtureFilterFunc
	self.funcDo = funcDo     
	
	thisModule.world:rayCast(line.point1.x, line.point1.y, line.point2.x + antibug, line.point2.y, self.worldRayCastCallback)
	
	self.objectClassNameFilter = false																										-- ClassName; string or false
	self.fixtureFilterFunc = false
	self.funcDo = false    	
	
	if sorted == nil then
		sorted = true
	end
	if sorted then
		table.sort(self.ray.hitList, function (a, b)
			return a.fraction < b.fraction
		end)		
	end
	
--	return self.ray        -- @todo -? copy
	return self.ray.hitList
end

-- #################################################################################################

thisModule.test = {}
function thisModule.test:draw()
	if thisModule.collision.worldRayCast.test.on then
		thisModule.collision.worldRayCast.test:draw()
	end
end

-- read-only table
local proxy = {}
setmetatable(proxy, 
	{
		__index = thisModule,
		__newindex = function (t, k, v)
			error("attempt to update a read-only table", 2)
		end
	}
)
return thisModule