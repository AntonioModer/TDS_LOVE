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
ThisModule.image = false

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
	
	-- tests
--	object.physics.body:setAwake(false)
--	object.physics.body:setMass(0)
--	object.physics.body:setMassData(0, 0, 0, 0)
--	object.physics.body:setInertia(10000000)	
--	object.physics.body:setLinearDamping(0)
--	object.physics.body:setAngularDamping(0)
	
	
	local shape = love.physics.newCircleShape(0, 0, arg.r)
	object.physics.fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture

	if arg.physics and arg.physics.sensor == true then
		object.physics.fixture:setSensor(true)
	end
	
	-- tests
--	object.physics.fixture:setDensity(0)
	object.physics.fixture:setFriction(0)
--	print(object.physics.fixture:getFriction())

	-- drawBuffer
	object.physics.fixture:setUserData({typeDraw = true})
	object.physics.fixture:setCategory(2)
	object.physics.fixture:setGroupIndex(arg.physics.fixtureGroupIndex or -2)
	
	return object
end

function ThisModule:draw(arg)
	if self.destroyed then self:destroyedError() end
	
	ClassParent.draw(self, arg)
	
	if (not arg.debug) and self.drawable then
		local shape = self.physics.fixture:getShape()
		
		local x, y = self.physics.body:getWorldPoints(shape:getPoint())
		
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.circle("fill", x, y, shape:getRadius())

	end
end

return ThisModule
