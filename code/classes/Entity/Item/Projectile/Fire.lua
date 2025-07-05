local ClassParent = require('code.classes.Entity.Item.Projectile')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end

ThisModule.shadows = {}
ThisModule.shadows.on = false
ThisModule.shadows.directional = {}                                                                                                             -- для придания наглядности глубины; тени на земле для вида глубины Z
ThisModule.shadows.directional.on = false

ThisModule.image = ThisModule._modGraph.images.items.projectile.fire.onFloor

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
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			
			selfEnt.physics.fixture:setCategory(3)
			selfEnt.physics.fixture:setMask(2, 4)				
			
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
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
--			print(os.clock(), 'state taken')
		end
	}
	, shooting = {                                                                                                                       -- @todo -? rename to "firing"
		funcCondition = ClassParent._statesAllTable.shooting.funcCondition
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
--			print(os.clock(), 'state shooting')
			
			selfEnt.z = 5
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.fixture:setCategory(2)
			selfEnt.physics.fixture:setMask(4)			
			
			selfEnt.timer:after(3, function()                                                                                                   -- 3 сек: взрыв сразу после остановки гранаты; 5 сек: можно взять гранату и кинуть в кидавшего или спокойно убежать
--				print(selfEnt, 'destroy')
				selfEnt:destroy()
			end)
		end
	}
	, throw = ClassParent._statesAllTable.throw
	, dragged = ClassParent._statesAllTable.dragged
}
--ThisModule.state.ro_stateCurrent = ThisModule._statesAllTable.onFloor

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {physics = {dontCreateFixtures = true}}
	arg.physics = arg.physics or {dontCreateFixtures = true}
	if not arg.physics.dontCreateFixtures then arg.physics.dontCreateFixtures = true end
	local object = ClassParent.newObject(self, arg)
	
	
	do -- physics
--		object.physics.body:setMassData(0, 0, 1, 1)
		object.physics.body:setMass(0.1)
--		object.physics.body:setInertia(1000000)
--		print(object.physics.body:getInertia())
		object.physics.body:setLinearDamping(0.5)                                                                                                 -- как граната = 2; как пуля = 0; как стрела = 0.5
		object.physics.body:setAngularDamping(10)
--		object.physics.body:setBullet(true)
--		print(object.physics.body:isBullet())
		object.physics.body:setSleepingAllowed(true)
		object.physics.body:setAwake(true)
		object.physics.body:setFixedRotation(true)
		
		local shape = love.physics.newCircleShape(0, 0, 4)
		local fixture = love.physics.newFixture(object.physics.body, shape, 1)                                                                  -- shape копируется при создании fixture
		
--		print(fixture:getRestitution()) -- def = 0
--		print(fixture:getDensity())     -- def = 1
--		print(fixture:getFriction())    -- def = 0.2

		fixture:setRestitution(0)       -- для гранаты >= 0
--		fixture:setDensity(10)
--		fixture:setFriction(10)
		
		fixture:setCategory(3)
		fixture:setMask(2, 4)
		fixture:setGroupIndex(-3)
		
		object.physics.fixture = fixture
		
		local physCallbackFunc = {}
		----[[
		function physCallbackFunc.preSolve(fixtureSelf, fixtureOther, contact)
			local otherEntity
			if (not fixtureOther:isDestroyed()) then
				
			end
			
			object:destroy()
		end
		--]]
		fixture:setUserData({typeDraw = true, physCallbackFunc = {preSolve = physCallbackFunc.preSolve}})
		
		--[[
		do  --draw
			-- drawBuffer shape
			local shape
			if self.image then
				shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)
			else
				shape = love.physics.newRectangleShape(0, 0, 10, 10, 0)
			end		
			local fixture = love.physics.newFixture(object.physics.body, shape, 0)
			fixture:setSensor(true)
			fixture:setUserData({typeDraw = true})
		end --]]

	end
	
	object.shadows.on = false
--	object.shadows.directional.z = 2
	object.allowToSave = false
	object.shadows.directional.on = false
	
	if arg.lightOn then
		object._light = require("code.classes.Entity.Light"):newObject({x = object:getX(), y = object:getY()})
		object._light.shadows.mobility = 'dynamic'
	end
	
	object.state:setState('onFloor', object)
	
	return object
end

function ThisModule:destroy()
	if self.destroyed then return false end
	ClassParent.destroy(self)
	if self._light then self._light:destroy() end
end

function ThisModule:update(arg)
	if self.destroyed then return false end
--	print(self, self.destroyed)
	ClassParent.update(self, arg)
	
	if self.destroyed then return false end
	if self._light then
		self._light:setPosition(self:getX(), self:getY())
	end
	
--	print('update')
end

return ThisModule