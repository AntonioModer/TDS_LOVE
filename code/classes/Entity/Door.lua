--[[
version 0.0.2
@todo 
	+ draw
	+ удаление
	-+ load with angle
	+ поменять местами Door, DoorBase
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
ThisModule._width = 16
ThisModule._height = 16

-- variables public
ThisModule.z = 9
--ThisModule.image = ThisModule._modGraph.images.testDDS

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
--	object.physics.body:setAwake(false)
--	object.physics.body:setMass(1)
--	object.physics.body:setMassData(0, 0, 1, 1)
--	object.physics.body:setInertia(1000000)	
--	object.physics.body:setLinearDamping(100)
	
	-- base
	local shape = love.physics.newRectangleShape(0, 0, object._width, object._height, 0)
	object.physics._fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
	
	-- drawBuffer shape
	local shape = love.physics.newRectangleShape(0, 0, object._width, object._height, 0)
	local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
	fixture:setSensor(true)
	fixture:setUserData({typeDraw = true})
	
	local doorWallC = math.vector()
	doorWallC.x, doorWallC.y = object.physics.body:getWorldPoint((object._width/2)+(require('code.classes.Entity.Door.DoorWall')._width/2), 0)
	local doorJointC = math.vector()
	doorJointC.x, doorJointC.y = object.physics.body:getWorldPoint(object._width/2, 0)	
	
	-- TODO -+? save, load wall with joint angle (загружать открытые двери в таком же положении в каком сохранились)
--	object.doorWall = require('code.classes.Entity.Door.DoorWall'):newObject({x=arg.doorWallX or doorWallC.x, y=arg.doorWallY or doorWallC.y, angle=arg.doorWallAngle or object:getAngle()})
	object.doorWall = require('code.classes.Entity.Door.DoorWall'):newObject({x=doorWallC.x, y=doorWallC.y, angle=object:getAngle()})
	object.joint = love.physics.newRevoluteJoint(object.physics.body, object.doorWall.physics.body, doorJointC.x, doorJointC.y)
	-- @todo -? save, load wall correct joint limit
	object.joint:setLimits(math.rad(-90), math.rad(90))
	object.joint:setLimitsEnabled(true)
	
	return object
end

function ThisModule:draw(arg)
	if self.destroyed then self:destroyedError() end
	
	ClassParent.draw(self, arg)
	
	if not arg.debug then
		local shape = self.physics._fixture:getShape()
		love.graphics.setColor(255, 255, 255)
		love.graphics.polygon("fill", self.physics.body:getWorldPoints(shape:getPoints()))
		
		-- direction
		local dx, dy = self.physics.body:getWorldPoint(10, 0)
		love.graphics.setColor(200, 0, 0, 255)
		love.graphics.circle("fill", self.physics.body:getX(), self.physics.body:getY(), 2)
		love.graphics.line(self.physics.body:getX(), self.physics.body:getY(), dx, dy)		
	end
end

function ThisModule:destroy()
	if self.destroyed then return false end
	
	if type(self) == 'object' then
		if not self.joint:isDestroyed() then
			self.joint:destroy()
		end
		self.doorWall:destroy()
	end
	
	ClassParent.destroy(self)
end

--[=[
function ThisModule:getSavedLuaCode()
	if self.destroyed then self:destroyedError() end
	
	-- одна строка = один entity
	local saveString = ClassParent.getSavedLuaCode(self)	
	
	saveString = saveString..", "..[[doorWallX = ]]..tostring(self.doorWall:getX())
	saveString = saveString..", "..[[doorWallY = ]]..tostring(self.doorWall:getY())
	saveString = saveString..", "..[[doorWallAngle = ]]..tostring(self.doorWall:getAngle())

	return saveString
end
--]=]

return ThisModule
