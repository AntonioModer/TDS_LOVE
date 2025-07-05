
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
ThisModule.image = ThisModule._modGraph.images.trees.test
ThisModule.z = 9

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	do -- draw
		-- drawBuffer shape
		local shape
		if self.image then
			shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)
		else
			shape = love.physics.newRectangleShape(0, 0, 64, 64, 0)
		end		
		local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
		fixture:setSensor(true)
		fixture:setUserData({typeDraw = true})
		
		object.shadows.on = false
		object.shadows.directional.z = 20
	end
	
	object.physics.body:setAwake(false)
	
	math.pendulumInit(object, 1, 0, false)
	math.pendulumInit(object, 2, 1, false)
	math.pendulumInit(object, 3, 0, false)
	
	object.scale = arg.scale or 1
	
	return object
end

function ThisModule:getSavedLuaCode()
	if self.destroyed then self:destroyedError() end
	
	-- одна строка = один entity
	local saveString = ClassParent.getSavedLuaCode(self)	
	if rawget(self, 'scale') ~= nil then
		saveString = saveString..", "..[[scale = ]]..tostring(self.scale)
	end	

	return saveString
end

function ThisModule:editInUIList(list)
	if self.destroyed then self:destroyedError() end
	
	ClassParent.editInUIList(self, list)
	
	local wE = require("code.worldEditor")
	
	wE:setItemListEditEntityFunc(list, self, self.scale, 'scale', function(var) self.scale = var; return self.scale end)
end

--function ThisModule:update(arg)
----	if self.destroyed then return false end
--	if self.destroyed then self:destroyedError() end
	
--end

function ThisModule:draw(arg)
	if self.destroyed then self:destroyedError() end
	
	do
		local beforeDrawable = self.drawable                      -- не рисуем лишний раз image
		self.drawable = false
		
		ClassParent.draw(self, arg)
		
		self.drawable = beforeDrawable
	end
	
	if (not arg.debug) and self.drawable then
		
		local shadowsDirectionalCoordsAdd  = {}                                                                                                                                       -- simpleShadowCoords additional
		shadowsDirectionalCoordsAdd.x, shadowsDirectionalCoordsAdd.y = 0, 0
		if arg.likeShadow then
			love.graphics.setColor(0, 0, 0, 255)
		elseif arg.shadowsDirectional and self.shadows.directional.on then                                                                                                            -- not done !!!
			love.graphics.setColor(0, 0, 0, 100)
			shadowsDirectionalCoordsAdd.x, shadowsDirectionalCoordsAdd.y = 3+(self.shadows.directional.z*2), 3+(self.shadows.directional.z*2)
		else
			love.graphics.setColor(255, 255, 255, 255)
		end
		
		-- math.pendulumStep(selfTab, id, angleStart, angleMax, speedRot)
		local dt = 100*love.timer.getDelta()
		-- 1
		local angle1 = math.rad(math.pendulumStep(self, 1, 0, 5, dt*2))
		love.graphics.draw(self.image, 
		  self.physics.body:getX()+shadowsDirectionalCoordsAdd.x, self.physics.body:getY()+shadowsDirectionalCoordsAdd.y, 
		  self.physics.body:getAngle()+angle1, 
		  scale or 1*self.scale, scale or 1*self.scale, 
		  self.image:getWidth()/2, self.image:getHeight()/2)
		
		if arg.shadowsDirectional then return nil end
		
		-- 2
		local angle2 = math.rad(math.pendulumStep(self, 2, 157, 10, dt*3))
		love.graphics.draw(self.image, 
		  self.physics.body:getX()+shadowsDirectionalCoordsAdd.x, self.physics.body:getY()+shadowsDirectionalCoordsAdd.y, 
		  self.physics.body:getAngle()+angle2, 
		  scale or 0.8*self.scale, scale or 0.8*self.scale, 
		  self.image:getWidth()/2, self.image:getHeight()/2)
		
		-- 3
		local angle3 = math.rad(math.pendulumStep(self, 3, 273, 20, dt*5))
		love.graphics.draw(self.image, 
		  self.physics.body:getX()+shadowsDirectionalCoordsAdd.x, self.physics.body:getY()+shadowsDirectionalCoordsAdd.y, 
		  self.physics.body:getAngle()+angle3, 
		  scale or 0.5*self.scale, scale or 0.5*self.scale, 
		  self.image:getWidth()/2, self.image:getHeight()/2)
				
	end
	
end

return ThisModule