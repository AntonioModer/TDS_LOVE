--[[
version 0.0.2
@todo 

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
ThisModule._width = 64
ThisModule._height = 8

-- variables public
ThisModule.z = 8
--ThisModule.image = ThisModule._modGraph.images.testDDS
ThisModule.allowToSave = false

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
	
--	object.physics.body:setAwake(false)
--	object.physics.body:setMass(100)
--	object.physics.body:setMassData(0, 0, 1, 1)
--	object.physics.body:setInertia(1000000)	
--	object.physics.body:setLinearDamping(0.01)
	
	-- 
	local shape = love.physics.newRectangleShape(0, 0, object._width, object._height, 0)
	object.physics._fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
	
	-- drawBuffer shape
	local shape = love.physics.newRectangleShape(0, 0, object._width, object._height, 0)
	local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
	fixture:setSensor(true)
	fixture:setUserData({typeDraw = true})
	
	return object
end

function ThisModule:draw(arg)
	if self.destroyed then self:destroyedError() end
	
	ClassParent.draw(self, arg)
	
	if (not arg.debug) then
		local shape = self.physics._fixture:getShape()
		love.graphics.setColor(255, 128, 0)
		love.graphics.polygon("fill", self.physics.body:getWorldPoints(shape:getPoints()))
		love.graphics.setColor(155, 78, 0)
		love.graphics.polygon("line", self.physics.body:getWorldPoints(shape:getPoints()))		
	end
	
end

return ThisModule
