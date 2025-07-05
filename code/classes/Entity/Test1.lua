--[[
version 0.0.6
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
ThisModule.z = 10
ThisModule.image = ThisModule._modGraph.images.testWhite

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	local shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0) --love.physics.newCircleShape(0, 0, math.max(self.image:getWidth(), self.image:getHeight())/2)
	local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
	
	object.physics.body:setAwake(false)																											-- !!! обязательно, если bodyType="static"; это повышает производительность, т.к. тело само не "засыпает"
	
	-- drawBuffer shape
	local shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)
	local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
	fixture:setSensor(true)
	fixture:setUserData({typeDraw = true})
	
	--[[ test physics, много шэйпов в одном объекте
	local matrixSize = math.ceil(100000^0.5)
	local startX, startY, width, height, step = 0, 0, matrixSize, matrixSize, 70
	local shape, fixture
	for x=1, width do
		for y=1, height do
--			local object = require("code.classes.Entity.Test1"):newObject({x = startX+(x*step), y = startY+(y*step)})
			
			shape = love.physics.newRectangleShape((startX+(x*step))-70, (startY+(y*step))-70, 64, 64, 0)
			fixture = love.physics.newFixture(object.physics.body, shape, 1)
		end	
	end
	--]]
	
	object.shadows.directional.on = false
	
	return object
end



return ThisModule
