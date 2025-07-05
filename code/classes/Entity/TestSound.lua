--[[
version 0.0.6
@todo 
	BUG - self.shadows.on при переключении значения в UI отображается всегда true, но если выделить другую entity и снова выделить эту, то значение станет отображаться корректно
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
ThisModule.z = 2
ThisModule.image = ThisModule._modGraph.images.testDDS

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
--	arg.mobility = "dynamic"
	local object = ClassParent.newObject(self, arg)
	
	object.debug = {}
	object.debug.on = true
	object.debug.draw = {}
	object.debug.draw.on = true
	object.debug.draw.phys = {}
	object.debug.draw.phys.on = true		
	
--	object.physics.body:setAwake(false)
--	object.physics.body:setMass(1)
--	object.physics.body:setMassData(0, 0, 1, 1)
--	object.physics.body:setInertia(1000000)	
--	object.physics.body:setLinearDamping(100)
	
	local shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)  --love.physics.newCircleShape(0, 0, math.max(self.image:getWidth(), self.image:getHeight())/2)
	local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture

	if arg.physics and arg.physics.sensor == true then
		fixture:setSensor(true)
	end
	
	-- drawBuffer shape
	local shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)
	local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
	fixture:setSensor(true)
	fixture:setUserData({typeDraw = true})
	
	-- sound
	local soundTest = require("code.sound").lib.mono.phone.source:clone()
	soundTest:setLooping(true)
	local ref, max = require("code.sound").lib.mono.phone.source:getAttenuationDistances()
	local shape = love.physics.newCircleShape(0, 0, max)
	local fixture = love.physics.newFixture(object.physics.body, shape, 0)																		-- shape копируется при создании fixture
	fixture:setSensor(true)
	fixture:setUserData({typeSound=true, sound = soundTest, selectedInWorldEditor=false})
	
--	local soundTest = require("code.sound").lib.mono.phone.source:clone()
--	soundTest:setLooping(true)
--	local ref, max = require("code.sound").lib.mono.phone.source:getAttenuationDistances()
--	local shape = love.physics.newCircleShape(0, 0, max)
--	local fixture = love.physics.newFixture(object.physics.body, shape, 0)																		-- shape копируется при создании fixture
--	fixture:setSensor(true)
--	fixture:setUserData({typeSound=true, sound = soundTest, selectedInWorldEditor=false})	
	
	return object
end

function ThisModule:destroy()
	if self.destroyed then return false end
	
	if type(self) == 'object' then
		for i, fixture in ipairs(self.physics.body:getFixtureList()) do
			if fixture:getUserData() and fixture:getUserData().sound then
				fixture:getUserData().sound:stop()
			end
		end		
	end
	
	ClassParent.destroy(self)
end

return ThisModule
