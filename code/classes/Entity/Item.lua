--[[
@version 0.0.1
@todo 
	* когда на земле
		+ не сталкиваются с живыми существами
		- не отбрасывать тень по Z-координате
	* когда не на земле
		+ сталкиваются с живыми существами
		- отбрасывать тень по Z-координате, чтобы показать, что предмет изменил высоту по Z
	-+ взаимодействие игрока с Item, смотри code.player
		+ state machine, которая полностью изменяет предмет (физика, переменные, ...), а не только image
	- parameters
		@todo 1 -? pickable
		-?NO draggable
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
ThisModule.z = 0
ThisModule.image = ThisModule._modGraph.images.items.test.onFloor
ThisModule.sprite = ThisModule._modGraph.sprites.items.test.onFloor

ThisModule.info = {}
ThisModule.info[1] = function () return '...' end

ThisModule._statesAllTable = {
	onFloor = {
--		, image = ThisModule._modGraph.images.items.weapons.test.onFloor
--		sprite = ThisModule._modGraph.sprites.items.weapons.test.onFloor
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
--			print(os.clock(), 'state onFloor')
			local selfEnt = selfObjectState.userData.selfEnt
			
			local collisionWithMiddle = false
			if other == nil or (other and (not other.notCheckCollisionWithMiddle)) then
				local fixtures = require("code.physics").collision.rectangle(selfEnt:getX(), selfEnt:getY(), selfEnt:getX(), selfEnt:getY())
				if fixtures then
					for i=1, #fixtures do
						local fixture = fixtures[i]
						if (not fixture:isDestroyed()) then
							local categories = {fixture:getCategory()}
			--				print(categories[1], categories[2])
							for i1=1, #categories do
								if categories[i1] == 4 and (type(fixture:getUserData()) == 'table' and fixture:getUserData().itemCanRestOnMe) then
									collisionWithMiddle = true
								end
							end
						end			
					end
				end
			end
			
			if selfState.image then selfEnt.image = selfState.image end
			if selfState.sprite then selfEnt.sprite = selfState.sprite end
			
			selfEnt.physics.body:setActive(true)
			
--			print(collisionWithMiddle)
			if collisionWithMiddle then
				selfEnt.physics.fixture:setCategory(2)
				selfEnt.physics.fixture:setMask(4)
				selfEnt.z = 2
				selfEnt.shadows.directional.z = 2
			else
				if selfEnt.physics and selfEnt.physics.fixtureDefaultCategories then
					selfEnt.physics.fixture:setCategory(unpack(selfEnt.physics.fixtureDefaultCategories))
				else
					selfEnt.physics.fixture:setCategory(3)
				end
				if selfEnt.physics and selfEnt.physics.fixtureDefaultMasks then
					selfEnt.physics.fixture:setMask(unpack(selfEnt.physics.fixtureDefaultMasks))
				else
					selfEnt.physics.fixture:setMask(2)
				end
				
				selfEnt.z = selfEnt:getClass().z or 0
				selfEnt.shadows.directional.z = selfEnt:getClass().shadows.directional.z or 0
			end
			local position = (other and other.position) or {whoChangeMyState:getPosition()}
			selfEnt:setPosition(unpack(position))
			
		end
	}
	, taken = {
--		, image = ThisModule._modGraph.images.items.weapons.test.taken
--		sprite = ThisModule._modGraph.sprites.items.weapons.test.taken
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			if selfState.image then selfEnt.image = selfState.image end
			if selfState.sprite then selfEnt.sprite = selfState.sprite end
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.body:setActive(false)
		end
	}
	, throw = {
		funcCondition = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			if (not game.player.dragHands.is) or (not whoChangeMyState.throwItemInHands) --[[and (not self._bodyPart.hands.entityIn) --]]then return false end
			if whoChangeMyState.state and whoChangeMyState.state.ro_stateCurrentName ~= 'aiming' then return false end
			return true
		end
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfObjectState.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state throw')
			
			selfEnt.physics.body:setActive(true)
			selfEnt.physics.fixture:setCategory(2)
			selfEnt.physics.fixture:setMask(4)
			selfEnt.shadows.directional.z = 2
			selfEnt.z = 5
			
			if whoChangeMyState.throwItemInHands then
				whoChangeMyState:throwItemInHands()
			end
		end
	}
	, dragged = {
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfObjectState.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state dragged')
			
			selfEnt.physics.fixture:setCategory(2)
			selfEnt.physics.fixture:setMask(4)
			selfEnt.shadows.directional.z = 2
			selfEnt.z = 5
		end
	}	
}

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	arg.mobility = "dynamic"
	local object = ClassParent.newObject(self, arg)
	
	if arg.physics == nil or (arg.physics and not arg.physics.dontCreateFixtures) then
		do  -- physics
		--	object.physics.body:setAwake(false)
		--	object.physics.body:setMass(1)
		--	object.physics.body:setMassData(0, 0, 1, 1)
		--	object.physics.body:setInertia(1000000)
		--	object.physics.body:setLinearDamping(100)
			
			local shape = love.physics.newRectangleShape(0, 0, (self.image or self.sprite.image):getWidth(), (self.image or self.sprite.image):getHeight(), 0)  --love.physics.newCircleShape(0, 0, math.max(self.image:getWidth(), self.image:getHeight())/2)
			local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
			object.physics.fixture = fixture
			
			if object.physics and object.physics.fixtureDefaultCategories then
				object.physics.fixture:setCategory(unpack(object.physics.fixtureDefaultCategories))
			else
				object.physics.fixture:setCategory(3)
			end
			if object.physics and object.physics.fixtureDefaultMasks then
				object.physics.fixture:setMask(unpack(object.physics.fixtureDefaultMasks))
			else
				object.physics.fixture:setMask(2)
			end
	--		fixture:setGroupIndex(3)
			
			if arg.physics and arg.physics.sensor == true then
				fixture:setSensor(true)
			end
		end
		
		do  -- drawBuffer shape
			local shape = love.physics.newRectangleShape(0, 0, (self.image or self.sprite.image):getWidth(), (self.image or self.sprite.image):getHeight(), 0)
			local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
			fixture:setSensor(true)
			fixture:setUserData({typeDraw = true})
		end
	end
	
--	print(object.physics.body:getLinearDamping())
	
	object.shadows.on = false
	
	object.state = require('code.logic.state').new()
	object.state.userData = {selfEnt=object}
	object.state:initStates(self._statesAllTable or {})
	
	object.info = ThisModule.info
	object.info[1] = ThisModule.info[1]
	
	return object
end

ThisModule.event = {}
ThisModule.minSpeedToFallOnFloor = 100
function ThisModule.event.stopMovingAfterThrow(self)
	self.state:setState('onFloor', self)
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
--	print(self, self.destroyed)
	-- если снаряд не движется
	if --[[rawget(self.event, 'stopMovingAfterThrow') and --]]self.state.ro_stateCurrent == self._statesAllTable.throw then
		----[[ best
--		if self.destroyed then return false end
		local x, y = self.physics.body:getLinearVelocity()
		if math.vector(x, y):len() < self.minSpeedToFallOnFloor then
--			self:destroy()
--			print('destroy')
			
			self.event.stopMovingAfterThrow(self)
			
			return nil
		end --]]
		--[[ not best
		if not self.physics.body:isAwake() then
			self:destroy()
			print('destroy')
			return nil		
		end --]]
--		print('update')
	end
	
	-- @todo - optimisation, вынести в очередь
	if self.state.ro_stateCurrent == self._statesAllTable.onFloor and (not self.physics.fixture:isDestroyed()) then
		local masks = {self.physics.fixture:getMask()}
		local collisionWithMiddle = false
		for i1=1, #masks do
			if masks[i1] == 4 then
				collisionWithMiddle = true
			end
		end
		if collisionWithMiddle == true then
			-- если объект на миддле лежал раньше, то проверяем заново коллизию
			collisionWithMiddle = false
			local fixtures = require("code.physics").collision.rectangle(self:getX(), self:getY(), self:getX(), self:getY())
			if fixtures then
				for i=1, #fixtures do
					local fixture = fixtures[i]
					if (not fixture:isDestroyed()) then
						local categories = {fixture:getCategory()}
		--				print(categories[1], categories[2])
						for i1=1, #categories do
							if categories[i1] == 4 and (type(fixture:getUserData()) == 'table' and fixture:getUserData().itemCanRestOnMe) then
								collisionWithMiddle = true
							end
						end
					end
				end
				if not collisionWithMiddle then
					if self.physics and self.physics.fixtureDefaultCategories then
						self.physics.fixture:setCategory(unpack(self.physics.fixtureDefaultCategories))
					else
						self.physics.fixture:setCategory(3)
					end
					-- сталкиваемся с миддле, объект упал на землю
					if self.physics and self.physics.fixtureDefaultMasks then
						self.physics.fixture:setMask(unpack(self.physics.fixtureDefaultMasks))
					else
						self.physics.fixture:setMask(2)
					end                         
					
					self.z = self:getClass().z or 0
					self.shadows.directional.z = self:getClass().shadows.directional.z or 0
				end
			end
		end
	end	
	
end

--[[
	* @arg mode <number> <nil> = 1 ... (default 1)
	* @arg whoUsedMe <entity>
	* @arg other <any>
--]]
function ThisModule:useStart(mode, whoUsedMe, other)
--	print('start use', self.entityName, mode, whoUsedMe.entityName)
	if mode == 1 then
--		if whoUsedMe.throwItemInHands then
			self.state:setState('throw', whoUsedMe)
--		end
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

return ThisModule
