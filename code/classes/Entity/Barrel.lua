--[[
version 0.0.1
@todo 
	- зеркальное отражение по горизонтали и вертикали image в draw() для разнообразия
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
ThisModule._variation = 1
ThisModule.image = ThisModule._modGraph.images.barrels["_" .. tostring(ThisModule._variation)]

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
	
	if type(arg.variation) == 'number' and arg.variation ~= 1 and arg.variation ~= nil then
		object:setVariation(arg.variation)
	end
	
	-- tests
--	object.physics.body:setAwake(false)
--	object.physics.body:setMass(0)
--	object.physics.body:setMassData(0, 0, 0, 0)
--	object.physics.body:setInertia(10000000)	
--	object.physics.body:setLinearDamping(0)
--	object.physics.body:setAngularDamping(0)
	
	local shape = love.physics.newRectangleShape(0, 0, object.image:getWidth(), object.image:getHeight(), 0)  --love.physics.newCircleShape(0, 0, math.max(self.image:getWidth(), self.image:getHeight())/2)
	local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
	
	fixture:setCategory(4)
	
	-- drawBuffer shape
--	local shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)
--	local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
--	fixture:setSensor(true)
	
	fixture:setUserData({typeDraw = true})
	
--	object.physics.fixture = fixture
	

	object.shadows.directional.z = 2
	object.shadows.on = false
	
	return object
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
end

function ThisModule:setVariation(argNumber, variant)
	if self.destroyed then return false end
	
	if variant == 1 or variant == nil then
		-- variant1
		if type(argNumber) == 'number' then
			self._variation = argNumber
			self.image = ThisModule._modGraph.images.barrels["_" .. tostring(self._variation)]
		end
	elseif variant == 2 then
		-- variant2
		local x, y, angle = self:getX(), self:getY(), self:getAngle()
		ThisModule:newObject({x = x, y = y, angle = angle, variation = argNumber})
		self:destroy()
	end
end

function ThisModule:editInUIList(list)
	if self.destroyed then self:destroyedError() end
	
	ClassParent.editInUIList(self, list)
	
	local wE = require("code.worldEditor")
	
	wE:setItemListEditEntityFunc(list, self, self._variation, 'variation', function(var) self:setVariation(var, 2); return self._variation end)

end

function ThisModule:getSavedLuaCode()
	if self.destroyed then self:destroyedError() end
	
	-- одна строка = один entity
	local saveString = ClassParent.getSavedLuaCode(self)	

	if rawget(self, '_variation') ~= nil and type(self._variation) == 'number' then
		saveString = saveString..", "..[[variation = ]]..tostring(self._variation)
	end

	return saveString
end

return ThisModule
