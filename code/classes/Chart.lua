--[[
version 0.11.1
@todo 
	+ переименовать в Chart
	- указывать значения 
		- минимум
		+ максимум
		- среднее
	- разноцветный, красный желтый зеленый в зависимости от уровня опасности
		- экономия места: можно совместить в один граф с линиями разного цвета
--]]
--[[
	MIT LICENSE

	Copyright (c) 2014 Phoenix C. Enero

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be included
	in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	
	https://github.com/icrawler/FPSGraph
	https://love2d.org/wiki/FPSGraph
	https://love2d.org/forums/viewtopic.php?f=5&t=77612
]]--

local ClassParent = require('code.Class')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end


-- variables private
-- ...

-- variables protected, only in Class
ThisModule._font = require("code.graphics").font.AntonioModerFont8pt_7x13pix_Ascent10Black.id -- require("code.graphics").mainFont.id  require("code.graphics").font.AntonioModerFont8pt_6x11pix_Ascent10BW.id love.graphics.newFont(8)  love.graphics.newFont([[resources/fonts/DejaVuSansMono.ttf]], 8)
--ThisModule._font:setFilter('nearest', 'nearest', 0)

ThisModule._dx = 0																											-- used for calculating the distance between the mouse and the pos
ThisModule._dy = 0																											-- as you are clicking the graph
ThisModule._isDown = false																									-- check if the graph is still down

-- variables public
ThisModule.x = 0
ThisModule.y = 0
ThisModule.width = 100
ThisModule.height = 50/2
ThisModule.delay = 0.25																										-- delay until the next update
ThisModule.draggable = false																								-- whether it is draggable or not
ThisModule.vmax = 0																											-- the maximum value of the graph
ThisModule.curTime = 0																										-- the current time of the graph
ThisModule.label = "chart"																									-- the label of the graph (changes when called by an update function)
ThisModule.on = true


-- methods private
-- ...

-- methods protected
-- ...

-- methods public

-- newObject({x, y, width, height, delay, draggable})
function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	object.x = arg.x
	object.y = arg.y
	object.width = arg.width
	object.height = arg.height
	object.delay = arg.delay
	object.draggable = arg.draggable
	object.vals = {}																										-- values
	
	-- create a value table such that the distance between two points is atleast 2 pixels
	for i=1, math.floor(object.width/2) do
		table.insert(object.vals, 0)
	end	
	
	return object
end

function ThisModule:update(val, label, dt)
	if self.destroyed then self:destroyedError() end
	
	if not self.on then return false end
	
	self.curTime = self.curTime + dt

	local mouseX, mouseY = love.mouse.getPosition()

	if self.draggable then
		if (mouseX < self.width+self.x and mouseX > self.x and
			mouseY < self.height+self.y and mouseY > self.y) or self._isDown then
			if love.mouse.isDown(1) then
				self._isDown = true
				self.x = mouseX - self._dx
				self.y = mouseY - self._dy
			else
				self._isDown = false
				self._dx = mouseX - self.x
				self._dy = mouseY - self.y
			end
		end
	end
	
	while self.curTime >= self.delay do
		self.curTime = self.curTime - self.delay
		table.remove(self.vals, 1)
		table.insert(self.vals, val)

		-- get the new max variable
		local max = 0
		for i=1, #self.vals do
			local v = self.vals[i]
			if v > max then
				max = v
			end
		end
		
		self.vmax = max
		self.label = label
	end

end

function ThisModule:updateFPS(dt)
	if self.destroyed then self:destroyedError() end
	
	local fps = 0.75*1/dt + 0.25*love.timer.getFPS()

	self:update(fps, "FPS: " .. math.floor(fps*10)/10, dt)
end

function ThisModule:updateMem(dt)
	if self.destroyed then self:destroyedError() end
	
	local mem = collectgarbage("count")

	self:update(mem, "Lua memory KB: " .. math.floor(mem*10)/10, dt)
end

--[[
@help 
	+ "тяжелый"
--]]
--local love, lg, lgl = love, love.graphics, love.graphics.line    -- влияние на скорость не замечено
local maxVal, len, step = 0, 0, 0
function ThisModule:draw()
	if self.destroyed then self:destroyedError() end
	
	if self.on then
		local fontBefore = love.graphics.getFont()
		love.graphics.setFont(self._font)
		
		-- round values
		maxVal = math.ceil(self.vmax/10)*10+20
		len = #self.vals
		step = self.width/len
		local labelMax = "max = "..string.format('%.3f', self.vmax)
		
		love.graphics.setColor(20, 20, 20)
		love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
--		love.graphics.rectangle('fill', self.x, self.height+self.y, (#self.label*6)+1, 11)
--		love.graphics.rectangle('fill', self.x, self.height+self.y, (#labelMax*6)+1, 12+8)
		
		love.graphics.setColor(180, 180, 180)
		love.graphics.setLineStyle('smooth')
		love.graphics.setLineWidth(1)
--		love.graphics.setLineJoin('miter')		
		for i=2, len do
			love.graphics.line(step*(i-2)+self.x, self.height*(-self.vals[i-1]/maxVal+1)+self.y,
				step*(i-1)+self.x, self.height*(-self.vals[i]/maxVal+1)+self.y)
		end
		
--		love.graphics.print(self.label, self.x, self.height+self.y+2)
--		love.graphics.print(labelMax, self.x, self.height+self.y+2+8)
		
--		love.graphics.printf(self.label, self.x, self.height+self.y+2, 200, 'left', 0, 1.0)
--		love.graphics.printf(labelMax, self.x, self.height+self.y+2+8, 200, 'left', 0, 1.0)
		
		love.graphics.print(self.label, self.x, self.height+self.y)
		love.graphics.print(labelMax, self.x, self.height+self.y+12)		
		
		love.graphics.setFont(fontBefore)
	end
end

return ThisModule
