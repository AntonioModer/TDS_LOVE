--[[
version 0.1.0
--]]
local Chart = require("code.classes.Chart")
debug.charts = {}

	
debug.charts.graphMemory = Chart:newObject({x=0, y=0})
--	debug.charts.graphMemory.draggable = true

debug.charts.graphFPS = Chart:newObject({x=0, y=0+((Chart.height+15+8)*1)})
--	debug.charts.graphFPS.draggable = true	

debug.charts.delta = Chart:newObject({x=0, y=0+((Chart.height+15+8)*2)})	
local update = debug.charts.delta.update
function debug.charts.delta:update(dt)
	update(self, dt*10000, string.format('time delta sec: %.4f', dt), dt)
end		

-- =============================== love.graphics.getStats()
debug.stats = love.graphics.getStats()																										-- !!! new table

debug.charts.drawcalls = Chart:newObject({x=0, y=0+((Chart.height+15+8)*3)})	
local update = debug.charts.drawcalls.update
function debug.charts.drawcalls:update(val, dt)
	update(self, val, 'drawcalls: '..val, dt)
end

debug.charts.canvasSwitches = Chart:newObject({x=0, y=0+((Chart.height+15+8)*4)})	
local update = debug.charts.canvasSwitches.update
function debug.charts.canvasSwitches:update(val, dt)
	update(self, val, 'canvas switches: '..val, dt)
end

debug.charts.canvases = Chart:newObject({x=0, y=0+((Chart.height+15+8)*5)})
local update = debug.charts.canvases.update
function debug.charts.canvases:update(val, dt)
	update(self, val, 'canvases: '..val, dt)
end

debug.charts.images = Chart:newObject({x=0, y=0+((Chart.height+15+8)*6)})
local update = debug.charts.images.update
function debug.charts.images:update(val, dt)
	update(self, val, 'images: '..val, dt)
end	

debug.charts.texturememory = Chart:newObject({x=0, y=0+((Chart.height+15+8)*7)})	
local update = debug.charts.texturememory.update
function debug.charts.texturememory:update(val, dt)
	update(self, val/1024/1024, string.format("texture memory MB: %.2f", val/1024/1024), dt)
end

debug.charts.physicsBodyCount = Chart:newObject({x=0, y=0+((Chart.height+15+8)*8)})
local update = debug.charts.physicsBodyCount.update
function debug.charts.physicsBodyCount:update(dt)
	local count = 0
	if require("code.physics").world then
		count = require("code.physics").world:getBodyCount()
	end
	update(self, count, 'PhysicsBodyCount: '..count, dt)
end
debug.charts.physicsBodyCount.on = require("code.physics").debug:isOn()

debug.charts.entityCount = Chart:newObject({x=0, y=0+((Chart.height+15+8)*9)})
local update = debug.charts.entityCount.update
function debug.charts.entityCount:update(dt)
	local count = 0
	for name, Class in pairs(require("code.world").EntityClasses) do
		count = count + Class:getObjectsCount()
	end		
	update(self, count, 'EntityCount: '..count, dt)
end
	
	-- @todo - add this
--	debug.charts.averageDelta = Chart:newObject({x=0, y=70+65+65+65+65+65+65+65})
--	debug.charts.averageDelta.visible = true
--	debug.charts.averageDelta.willUpdate = true	
--	local update = debug.charts.averageDelta.update
--	function debug.charts.averageDelta:update(dt)
--		update(self, love.timer.getAverageDelta()*1000, string.format('time averageDelta sec: %.3f', love.timer.getAverageDelta()), dt)
--	end


function debug.charts.update(dt)
	if not debug:isOn() then return end
	local debug = debug

	
end
function debug.charts.draw()
	if not debug:isOn() then return end
	local debug = debug
	
	debug.stats = love.graphics.getStats()
	
	local dt = love.timer.getDelta()
	debug.charts.texturememory:update(debug.stats.texturememory, dt)
	debug.charts.images:update(debug.stats.images, dt)
	debug.charts.canvasSwitches:update(debug.stats.canvasswitches, dt)
	debug.charts.canvases:update(debug.stats.canvases, dt)
	debug.charts.physicsBodyCount:update(dt)
	debug.charts.entityCount:update(dt)
	debug.charts.graphFPS:updateFPS(dt)
	debug.charts.delta:update(dt)
--	debug.charts.averageDelta:update(dt)

	debug.charts.images:draw()
	debug.charts.texturememory:draw()
	debug.charts.canvasSwitches:draw()
	debug.charts.canvases:draw()
	debug.charts.physicsBodyCount:draw()
	debug.charts.entityCount:draw()
	debug.charts.graphFPS:draw()	
	debug.charts.delta:draw()
--	debug.charts.averageDelta:draw()

	debug.charts.graphMemory:updateMem(dt)
	debug.charts.graphMemory:draw()

	debug.stats = love.graphics.getStats()
	debug.charts.drawcalls:update(debug.stats.drawcalls, dt)												-- только в love.draw()
	debug.charts.drawcalls:draw()
	
end
