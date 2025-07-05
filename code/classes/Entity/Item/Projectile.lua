--[[
version 0.0.5
@todo 
	+ параметры физики похожи на Humanoid
	@todo 1 -+ удаление
		+ через х время удаляется
			* для гранаты только так
				+?YES переназначить родительский класс в Item
					* удобно для гранат, стрел
					* т.к. в Итем есть useStart(), и это удобно для таймера гранаты
					+ сделать useStart() useStop() при выстрелах
					-?NO тогда нужно чтобы игрок и другие не могли взять его
						- параметр Item.pickable (поднимаемая)
						* нет нужно поднимать, поднимать стрелы, гранаты
			* не подходит для пули, стрелы
				* т.к. если физики тормазит, то таймер удалит снаряд когда снаряд вылетил на половину траектории
		+ удалять, если снаряд не движется
			* https://www.google.by/#newwindow=1&q=box2d+check+if+object+is+not+move
				* http://stackoverflow.com/questions/21999974/how-to-check-if-a-body-has-almost-stopped-moving-in-libgdx-box2d
				* http://box2d.org/forum/viewtopic.php?t=6746
			* не для гранаты
			* для пули, стрелы
			* как дополнительная проверка
			+ нужно постоянно проверять скорость снаряда в update()
			+NO self.physics.body:isAwake()
				* плохое решение, снаряд может медленно двигаться и быть awake, следовательно не удалиться
				* нельзя задать минимальную скорость снаряда, когда нужно его удалять
			* может быть такое, что снаряд будет двигаться дольше нужного или вообще не остановится, когда object.physics.body:setLinearDamping(0)
		+ нужно считать пройденную длинну пути пролета снаряда (в update()), когда достигнута максимальная длинна пути, то удаляем
			-?NO с учетом self.physics.body:getLinearVelocity()
				*? т.к. self.physics.body:getLinearVelocity() это - скорость изменения положения во времени, и по нему невозможно узнать какое расстояние снаряд пролетел
		-?NO удалять когда снаряд вышел из сенсора оружия
			* снаряд может и не выйти из этого радиуса и тогда он не удалиться
			- у каждого оружия есть сенсор-окружность, у снаряда есть physCallbackFunc.endContact() в котором есть условие его удаления, если он выходит из своего сенсора
	+ имеет в fixture.userData physCallbackFunc.beginContact
		+ разобраться как определять родительскую фикстуру
			+ всегда первый аргумент
	@todo 2 -+ other types
		-+ grenade
		-+ arrow
	+ draw image
	- оптимизация: вместо удаления снарядов создать таблицу постоянных снарядов
--]]

local ClassParent = require('code.classes.Entity.Item')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end

ThisModule.debug = {}
ThisModule.debug.on = false
ThisModule.debug.draw = {}
ThisModule.debug.draw.on = true
ThisModule.debug.draw.phys = {}
ThisModule.debug.draw.phys.on = true
ThisModule.image = ThisModule._modGraph.images.items.projectile.common.onFloor

ThisModule.state = {}
ThisModule._statesAllTable = {
	onFloor = {
--		, image = ThisModule._modGraph.images.items.weapons.test.onFloor
--		, sprite = ThisModule._modGraph.sprites.items.weapons.test.onFloor
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt:useStop(nil, whoChangeMyState)
			selfEnt.image = selfState.image
			selfEnt.sprite = selfState.sprite
			selfEnt.shadows.directional.z = 0
			selfEnt.physics.body:setActive(true)
			selfEnt:setPosition(whoChangeMyState:getPosition())
			selfObjectState.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			
			selfEnt.physics.fixture:setCategory(3)
			selfEnt.physics.fixture:setMask(2, 4)	
			
			selfEnt.z = 0
			
--			print(os.clock(), 'state onFloor')
		end
	}
	, onFloor = ClassParent._statesAllTable.onFloor
	, taken = {
--		, image = ThisModule._modGraph.images.items.weapons.test.taken
--		, sprite = ThisModule._modGraph.sprites.items.weapons.test.taken
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.image = selfState.image
			selfEnt.sprite = selfState.sprite
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.body:setActive(false)
			selfObjectState.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			
			print(os.clock(), 'state taken')
		end
	}
	, shooting = {                                                                                                                              -- стрельба                                                                                                                       -- @todo -? rename to "firing"
		funcCondition = function(selfState, selfObjectState, whoChangeMyState, other)
			if type(whoChangeMyState) == 'object' and string.sub(whoChangeMyState:getClassName(), 1, 18) == 'Entity.Item.Weapon' then return true end
		end
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			
			local selfEnt = selfObjectState.userData.selfEnt
			selfObjectState.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state shooting')
			
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.fixture:setCategory(2)
			selfEnt.physics.fixture:setMask(4)			
			
			selfEnt.z = 5
			
--			selfEnt.timer:after(3, function()
--				selfEnt:destroy()
--				print('destroy') 
--			end)
		end
	}
	, throw = ClassParent._statesAllTable.throw
	, dragged = ClassParent._statesAllTable.dragged
}

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local argBeforePhysics = arg.physics
	
	local arg = arg or {physics = {dontCreateFixtures = true}}
	arg.physics = arg.physics or {dontCreateFixtures = true}
	if not arg.physics.dontCreateFixtures then arg.physics.dontCreateFixtures = true end
	local object = ClassParent.newObject(self, arg)
	
	arg.physics = argBeforePhysics
	
	do -- physics
--		object.physics.body:setMassData(0, 0, 1, 1)
		object.physics.body:setMass(0.1)
--		object.physics.body:setInertia(1000000)
--		print(object.physics.body:getInertia())
		object.physics.body:setLinearDamping(2)                                                                                                 -- как граната = 2; как пуля = 0; как стрела = 0.5
		object.physics.body:setAngularDamping(10)
		object.physics.body:setBullet(true)
--		print(object.physics.body:isBullet())
		object.physics.body:setSleepingAllowed(true)
		object.physics.body:setAwake(true)
	--	object.physics.body:setFixedRotation(true)
		
		
		if arg == nil or arg.physics == nil or (arg.physics and not arg.physics.dontCreateFixtures) then
			local shape
			if self.image then
				shape = love.physics.newCircleShape(0, 0, (math.max(self.image:getWidth(), self.image:getHeight()))/2)
			else
				shape = love.physics.newCircleShape(0, 0, 4)
			end
			local fixture = love.physics.newFixture(object.physics.body, shape, 1)                                                                  -- shape копируется при создании fixture
			
	--		print(fixture:getRestitution()) -- def = 0
	--		print(fixture:getDensity())     -- def = 1
	--		print(fixture:getFriction())    -- def = 0.2

	--		fixture:setRestitution(1)       -- для гранаты >= 0
	--		fixture:setDensity(10)
	--		fixture:setFriction(10)
			
			fixture:setCategory(3)
			fixture:setMask(2)
	--		fixture:setGroupIndex(2)
			
			object.physics.fixture = fixture
			
			local physCallbackFunc = {}
			--[[
			function physCallbackFunc.preSolve(fixtureSelf, fixtureOther, contact)
				local otherEntity
				if (not fixtureOther:isDestroyed()) then
					
				end
				
				object:destroy()
			end
			--]]
			
			----[[
			do  --draw
				-- drawBuffer shape
	--			local shape
	--			if self.image then
	--				shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)
	--			else
	--				shape = love.physics.newRectangleShape(0, 0, 10, 10, 0)
	--			end		
	--			local fixture = love.physics.newFixture(object.physics.body, shape, 0)
	--			fixture:setSensor(true)

				fixture:setUserData({typeDraw = true, physCallbackFunc = {preSolve = physCallbackFunc.preSolve}})
				

			end --]]
		end
		object.shadows.on = false
--		object.shadows.directional.z = 2		
	end
	
--	print('new')
	
	object.path = {}
	object.path.length = {}
	object.path.length.current = 0
	object.path.length.max = 500
	object.path.past = {}
	object.path.past.x = false
	object.path.past.y = false
	
	object.timer = require('code.timer').new()
	
	return object
end

ThisModule.event = {}
function ThisModule.event.moveMaxPathLength(self)
	
end

ThisModule.minSpeedToFallOnFloor = 100
function ThisModule.event.stopMovingAfterShooting(self)
	self.state:setState('onFloor', self)
end

ThisModule.event.stopMovingAfterThrow = ClassParent.event.stopMovingAfterThrow

--[[
	* @arg mode <number> <nil> = 1 ... (default 1)
	* @arg whoUsedMe <entity>
	* @arg other <any>
--]]
function ThisModule:useStart(mode, whoUsedMe, other)
--	print('start use', self.entityName, mode, whoUsedMe.entityName)
	if mode == 1 then
		self.state:setState('shooting', whoUsedMe)
		self.state:setState('throw', whoUsedMe)
	end
end

--[[
	* @arg mode <number> <nil> = 1 ... (default 1)
	* @arg whoUsedMe <entity>
	* @arg other <any>
--]]
function ThisModule:useStop(mode, whoUsedMe, other)
--	print('stop use', self.entityName, mode, whoUsedMe.entityName)
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
	if self.timer then
		self.timer:update(arg.dt)
		if self.destroyed then return false end                                                                                                 -- |обязательно!!!| проверять, т.к. таймер может удалить объект 
	end
	
--	print(self, self.destroyed)
	-- если снаряд не движется
	if --[[ rawget(self.event, 'stopMovingAfterShooting') and --]]self.state.ro_stateCurrent == self._statesAllTable.shooting then
		----[[ best
--		if self.destroyed then return false end
		local x, y = self.physics.body:getLinearVelocity()
		if math.vector(x, y):len() < self.minSpeedToFallOnFloor then
--			self:destroy()
--			print('destroy')
			
			self.event.stopMovingAfterShooting(self)
			
			return nil
		end --]]
		--[[ not best
		if not self.physics.body:isAwake() then
			self:destroy()
			print('destroy')
			return nil		
		end --]]
	end
	
	----[[ считать пройденную длинну пути пролета снаряда
	if rawget(self.event, 'moveMaxPathLength') and self.state.ro_stateCurrent == self._statesAllTable.shooting then
		if self.path.past.x == false then
			self.path.past.x = self:getX()
		end
		if self.path.past.y == false then
			self.path.past.y = self:getY()
		end
		self.path.length.current = self.path.length.current + math.dist(self:getX(), self:getY(), self.path.past.x, self.path.past.y)
		self.path.past.x = self:getX()
		self.path.past.y = self:getY()
		if self.path.length.current >= self.path.length.max then
--			self:destroy()
--			print('destroy', self.path.length.current)
			
			self.event.moveMaxPathLength(self)
			
			return nil
		end
	end
	--]]
	
--	print('update')
end

return ThisModule



















