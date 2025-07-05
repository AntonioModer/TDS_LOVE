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
ThisModule.z = 1
ThisModule.image = ThisModule._modGraph.images.testDDS

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
	
	-- tests
--	object.physics.body:setAwake(false)
--	object.physics.body:setMass(0)
--	object.physics.body:setMassData(0, 0, 0, 0)
--	object.physics.body:setInertia(10000000)	
--	object.physics.body:setLinearDamping(0)
--	object.physics.body:setAngularDamping(0)
	
	
	local shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)  --love.physics.newCircleShape(0, 0, math.max(self.image:getWidth(), self.image:getHeight())/2)
	local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture

	if arg.physics and arg.physics.sensor == true then
		fixture:setSensor(true)
	end
	
	fixture:setCategory(4)
	
	-- tests
--	fixture:setDensity(0)
--	fixture:setFriction(0)
--	print(fixture:getRestitution())
	
	-- drawBuffer shape
	local shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)
	local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
	fixture:setSensor(true)
	fixture:setUserData({typeDraw = true})
	
	object.shadows.directional.z = 2
	
	return object
end



return ThisModule
