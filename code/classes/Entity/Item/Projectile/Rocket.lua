--[[
version 0.0.1
@todo 
	
--]]

local ClassParent = require('code.classes.Entity.Item.Projectile')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end

ThisModule.image = ThisModule._modGraph.images.items.projectile.rocket.onFloor

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
			
			selfEnt.z = 0
			
			print(os.clock(), 'state onFloor')
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
			
			print(os.clock(), 'state taken')
		end
	}
	, shooting = {                                                                                                                              -- стрельба                                                                                                                       -- @todo -? rename to "firing"
		funcCondition = ClassParent._statesAllTable.shooting.funcCondition
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state shooting')
			
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.fixture:setCategory(2)
			selfEnt.physics.fixture:setMask(4)			
			
			selfEnt.z = 5
			
			selfEnt.timer:after(selfEnt.fuel.delayBeforeStartBurn, function()
				print('start burn fuel')
				selfEnt.timer:during(selfEnt.flyMaxSec
					, function()
						selfEnt.fuel.burnUpdate(selfEnt)
					end
					,function()
						print('stop burn fuel')
						selfEnt.event = {}
						function selfEnt.event.stopMovingAfterShooting(selfEnt)
							selfEnt.state:setState('onFloor', selfEnt)
						end
					end
				)
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
		object.physics.body:setMass(1)
--		object.physics.body:setInertia(1000000)
--		print(object.physics.body:getInertia())
		object.physics.body:setLinearDamping(2)                                                                                                 -- как граната = 2; как пуля = 0; как стрела = 0.5
		object.physics.body:setAngularDamping(10)
		object.physics.body:setBullet(true)
--		print(object.physics.body:isBullet())
		object.physics.body:setSleepingAllowed(true)
		object.physics.body:setAwake(true)
	--	object.physics.body:setFixedRotation(true)
		
		local shape
		if self.image then
			shape = love.physics.newRectangleShape(0, 0, self.image:getWidth()-2, self.image:getHeight()-2, 0)
		else
			shape = love.physics.newCircleShape(0, 0, 4)
		end
		local fixture = love.physics.newFixture(object.physics.body, shape, 1)                                                                  -- shape копируется при создании fixture
		
--		print(fixture:getRestitution()) -- def = 0
--		print(fixture:getDensity())     -- def = 1
--		print(fixture:getFriction())    -- def = 0.2

--		fixture:setRestitution(0.1)       -- для гранаты >= 0
--		fixture:setDensity(10)
--		fixture:setFriction(10)
		
		fixture:setCategory(3)
		fixture:setMask(2, 4)
--		fixture:setGroupIndex(2)
		
		object.physics.fixture = fixture
		
		local physCallbackFunc = {}
		----[[
		function physCallbackFunc.postSolve(fixtureSelf, fixtureOther, contact)
			if (not fixtureOther:isDestroyed()) then
				local otherEntity = fixtureOther:getBody():getUserData()
				
			end
			if object.state.ro_stateCurrent == object._statesAllTable.shooting then
				object._needBoom = true
			end
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

			fixture:setUserData({typeDraw = true, physCallbackFunc = {postSolve = physCallbackFunc.postSolve}})
		end --]]
	end	
	
	object.fuel = {}
	object.fuel.burnUpdate = ThisModule.fuel.burnUpdate
	object.fuel.delayBeforeStartBurn = 1
	
	object._needBoom = false
	
	object.state:setState('onFloor', object)
	
	return object
end

ThisModule.flyMaxSec = 1
ThisModule.fuel = {}
function ThisModule.fuel.burnUpdate(self)
	local force = math.vector(1, 0):rotateInplace(self.physics.body:getAngle()) * 100
	local fpx, fpy =  self.physics.body:getWorldVector(-20, 0)
	self.physics.body:applyForce(force.x, force.y, self:getX()+fpx, self:getY()+fpy)	
end

ThisModule.event = {}
function ThisModule.event.stopMovingAfterShooting(self)
--	self.state:setState('onFloor', self)
end

ThisModule.event.stopMovingAfterThrow = ClassParent.event.stopMovingAfterThrow

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
	if self._needBoom then
		local x, y = self:getX(), self:getY()
		self:destroy()
		local explosion = require('code.classes.Entity.Explosion'):newObject({x=x, y=y})
		explosion:boom()		
	end
	
--	print('update')
end

return ThisModule