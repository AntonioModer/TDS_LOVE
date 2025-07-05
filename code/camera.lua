--[[
version 0.0.4
@todo 
	-+ modes
		+ free
			+ только если WorldEditor=true
		-+ to object
			- плавный переход к объекту
--]]

--local thisModule = require("code.hump.camera")(config.window.width/2, config.window.height/2, 1, 0)
local thisModule = require("code.gamera").new(-math.huge, -math.huge, math.huge, math.huge)

thisModule.mode = {}
thisModule.mode.attach = {}
thisModule.mode.attach.type = 'free'																												-- object, free, player
thisModule.mode.attach.object = false
thisModule.moveSpeed = 500*2

-- object, free
function thisModule:setAttachMode(mode, object)
	if mode == 'free' then
		self.mode.attach.type = mode
		self.mode.attach.object = false
	elseif mode == 'object' then
		self.mode.attach.type = mode
		self.mode.attach.object = object
	elseif mode == 'player' then
		self.mode.attach.type = mode	
	end
end

function thisModule:update(dt)
	if self.mode.attach.type == 'free' then
		if love.keyboard.isDown("w") then
			self:move(0, -self.moveSpeed*dt)
		elseif love.keyboard.isDown("s") then
			self:move(0, self.moveSpeed*dt)
		elseif love.keyboard.isDown("a") then
			self:move(-self.moveSpeed*dt, 0)
		elseif love.keyboard.isDown("d") then
			self:move(self.moveSpeed*dt, 0)
		end
	elseif self.mode.attach.type == 'object' then
		self:setPosition(self.mode.attach.object:getX(), self.mode.attach.object:getY())
	elseif self.mode.attach.type == 'player' then
		if game.player and game.player.entity then
			self:setPosition(game.player.entity:getX(), game.player.entity:getY())
		end
	end
end

--[[
version 0.0.1
@help 
	+ INPUT
@todo 
	- 
--]]
thisModule.input = {}
thisModule.input.allowZoomByWheelMove = true

function thisModule.input:wheelMoved(x, y)
	if not thisModule.input.allowZoomByWheelMove then return false end
	if not love.keyboard.isDown(config.controls.camera.zoomHoldConrol) then return false end
	
	if y > 0 then
		if thisModule.scale == 1 then
			thisModule.scale = 2
		elseif thisModule.scale == 0.5 then
			thisModule.scale = 1		
		elseif thisModule.scale == 0.1 then
			thisModule.scale = 0.5		
		end
--		thisModule.scale = thisModule.scale+1
	elseif y < 0 then
		if thisModule.scale == 0.5 then
			thisModule.scale = 0.1		
		elseif thisModule.scale == 1 then
			thisModule.scale = 0.5
		elseif thisModule.scale == 2 then
			thisModule.scale = 1		
		end
--		thisModule.scale = thisModule.scale-1
	end
end

return thisModule