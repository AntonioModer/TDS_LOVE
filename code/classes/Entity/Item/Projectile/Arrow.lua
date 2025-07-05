local ClassParent = require('code.classes.Entity.Item.Projectile')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end

ThisModule.image = ThisModule._modGraph.images.items.projectile.arrow.onFloor

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

--		fixture:setRestitution(1)       -- для гранаты >= 0
--		fixture:setDensity(10)
--		fixture:setFriction(10)
		
		fixture:setCategory(3)
		fixture:setMask(2, 4)
		fixture:setGroupIndex(-1)
		
		object.physics.fixture = fixture
		
		object.sticky = {}
		object.sticky.toEntity = false
		object.sticky.done = false
		object.sticky.joint = false
		object.sticky.set = ThisModule.sticky.set
		
		local physCallbackFunc = {}
		----[[
		function physCallbackFunc.postSolve(fixtureSelf, fixtureOther, contact)
			if (not fixtureOther:isDestroyed()) then
				local otherEntity = fixtureOther:getBody():getUserData()
--				if otherEntity:getClassName() ~= 'Entity.Item.Projectile.Arrow' then
					object.sticky.toEntity = otherEntity
--				end
				-- @todo 1 -? ограничение прилипания на скорость (хотя это уже есть, если скорость маленькая, то state == 'onFloor', смотри update())
				--[=[
				if otherEntity and (not otherEntity.destroyed) then
					local localX1, localY1 = otherEntity.physics.body:getLocalPoint(otherEntity:getX(), otherEntity:getY())
					localX1, localY1 = otherEntity.physics.body:getWorldPoint(localX1, localY1)                                                 -- bugCrutch; костыль под правильный API, пока не исправлен @bug; после исправления @bug, убрать эту строчку
					object.physics.jointstickyy = love.physics.newWeldJoint(object.physics.body, otherEntity.physics.body                        -- BUG нельзя тут создать joint (error: Box2D assertion failed: IsLocked() == false)
						, localX1, localY1
						, localX1, localY1
						, false
						, otherEntity.physics.body:getAngle() - object.physics.body:getAngle()--[[math.bDegToRad(angleBefore)--]])    -- 0.10.2
				end
				--]=]
			end
			
--			object:destroy()
--			print('collision')
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
	
	object.state:setState('onFloor', object)
	
	return object
end

ThisModule.sticky = {}
ThisModule.sticky.toEntity = false
ThisModule.sticky.done = false
ThisModule.sticky.joint = false
function ThisModule.sticky.set(self, otherEntity)
	if self.destroyed then self:destroyedError() end
	
	if otherEntity and (not otherEntity.destroyed) then
		local localX1, localY1 = otherEntity.physics.body:getLocalPoint(otherEntity:getX(), otherEntity:getY())
		localX1, localY1 = otherEntity.physics.body:getWorldPoint(localX1, localY1)                                                 -- bugCrutch; костыль под правильный API, пока не исправлен @bug; после исправления @bug, убрать эту строчку
		self.sticky.joint = love.physics.newWeldJoint(self.physics.body, otherEntity.physics.body
			, localX1, localY1
			, localX1, localY1
			, false
			, otherEntity.physics.body:getAngle() - self.physics.body:getAngle()--[[math.bDegToRad(angleBefore)--]])    -- 0.10.2
		self.sticky.done = true
	end	
--	print('sticky')
end

ThisModule.event = {}
function ThisModule.event.moveMaxPathLength(self)
	
end

function ThisModule.event.stopMovingAfterShooting(self)
	if self.sticky.toEntity == false then
		self.state:setState('onFloor', self)
	end
end

ThisModule.event.stopMovingAfterThrow = ClassParent.event.stopMovingAfterThrow

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
	if self.state.ro_stateCurrent == self._statesAllTable.shooting and self.sticky.done == false and self.sticky.toEntity then
		self.sticky.set(self, self.sticky.toEntity)
	end
	
--	print('update')
end

return ThisModule