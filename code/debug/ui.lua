--[[
version 0.1.2
TOOD:
	- в debug lua memory отображать путь отображаемой таблицы или название текущей таблицы, пример: _G.test
--]]


debug.ui = require("code.Class"):newObjectsWeakTable()																	-- list of UI-objects

debug.ui.main = require("code.classes.UI.List"):newObject({name='Debug MainMenu', x=180, y=50})
debug.ui.main.itemsMaxLengthInSymbols = 20
debug.ui.main.showMaxItems = 7

debug.ui.luaMemory = require("code.classes.UI.List"):newObject({name='Lua memory', x=280, y=150})
debug.ui.luaMemory.itemsMaxLengthInSymbols = 20
debug.ui.luaMemory.showMaxItems = 30
debug.ui.luaMemory:tableExplore(_G, true)

--------------------------------------------------------------------------------------------------------
debug.ui.watchList = require("code.classes.UI.List"):newObject({name='Watch list', x=830, y=150})
debug.ui.watchList.itemsMaxLengthInSymbols = 60
debug.ui.watchList.showMaxItems = 30
if not config.debug.watchList.on then
	debug.ui.watchList:close()
end

local foo = function()
	local x, y = camera:toWorld(love.mouse.getPosition())
	return "mouse in world x = "..x																									-- string
end
debug.ui.watchList:insertItem({name="mouse in world x = ...", func = foo})

local foo = function()
	local x, y = camera:toWorld(love.mouse.getPosition())
	return "mouse in world y = "..y																									-- string
end
debug.ui.watchList:insertItem({name="mouse in world y = ...", func = foo})

--local foo = function()
--	local x, y = camera:toScreen(camera:toWorld(love.mouse.getPosition()))
--	return "mouse world in camera x = "..x																									-- string
--end
--debug.ui.watchList:insertItem({name="mouse world in camera x = ...", func = foo})

--local foo = function()
--	local x, y = camera:toScreen(camera:toWorld(love.mouse.getPosition()))
--	return "mouse world in camera y = "..y																									-- string
--end
--debug.ui.watchList:insertItem({name="mouse world in camera y = ...", func = foo})

local foo = function()
	return "mouse window x = "..love.mouse.getX()																										-- string
end
debug.ui.watchList:insertItem({name="mouse window x = ...", func = foo})

local foo = function()
	return "mouse window y = "..love.mouse.getY()																										-- string
end
debug.ui.watchList:insertItem({name="mouse window y = ...", func = foo})

local foo = function()
	return "camera.scale = "..camera.scale																										-- string
end
debug.ui.watchList:insertItem({name="camera.scale = ...", func = foo})

debug.ui.watchList:insertItem({name="-------------------------------------"})

if false then
	local foo = function()
		return "physics.debugTimer.result = "..tostring(math.nSA(require("code.physics").debugTimer.result, 0.0001))														-- string
	end
	debug.ui.watchList:insertItem({name="physics.debugTimer.result = ...", func = foo})

	local foo = function()
		return "zDBEL.debug.draw.count = "..tostring(require("code.graphics").zDBEL.debug.draw.count)														-- string
	end
	debug.ui.watchList:insertItem({name="zDBEL.debug.draw.count = ...", func = foo})

	local foo = function()
		return "zDBEL.debug.draw.timer.result = "..tostring(require("code.graphics").zDBEL.debug.draw.timer.result)														-- string
	end
	debug.ui.watchList:insertItem({name="zDBEL.debug.draw.timer.result = ...", func = foo})

	local foo = function()
		return "zDBEL.debug.update.countAdd = "..tostring(require("code.graphics").zDBEL.debug.update.countAdd)														-- string
	end
	debug.ui.watchList:insertItem({name="zDBEL.debug.update.countAdd = ...", func = foo})

	local foo = function()
		return "db.debug.update.timer.result = "..tostring(require("code.graphics").db.debug.update.timer.result)														-- string
	end
	debug.ui.watchList:insertItem({name="db.debug.update.timer.result = ...", func = foo})

	debug.ui.watchList:insertItem({name="-------------------------------------"})
end

if false then
	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "angle()                            = "..tostring(math.angle(camera.x, camera.y, x, y))														-- string
	end
	debug.ui.watchList:insertItem({name="math.deglb(math.deg(math.angle())) = ...", func = foo})

	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "deg(angle())                       = "..tostring(math.deg(math.angle(camera.x, camera.y, x, y)))														-- string
	end
	debug.ui.watchList:insertItem({name="math.deglb(math.deg(math.angle())) = ...", func = foo})

	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "degToBDeg(deg(angle()))            =  "..tostring(math.degToBDeg(math.deg(math.angle(camera.x, camera.y, x, y))))														-- string
	end
	debug.ui.watchList:insertItem({name="math.deglb(math.deg(math.angle())) = ...", func = foo})

	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "radToBDeg(angle())                 =  "..tostring(math.radToBDeg(math.angle(camera.x, camera.y, x, y)))														-- string
	end
	debug.ui.watchList:insertItem({name="math.deglb(math.deg(math.angle())) = ...", func = foo})

	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "bDegToDeg(radToBDeg(angle()))      = "..tostring(math.bDegToDeg(math.radToBDeg(math.angle(camera.x, camera.y, x, y))))														-- string
	end
	debug.ui.watchList:insertItem({name="math.deglb(math.deg(math.angle())) = ...", func = foo})

	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "rad(bDegToDeg(radToBDeg(angle()))) = "..tostring(math.rad(math.bDegToDeg(math.radToBDeg(math.angle(camera.x, camera.y, x, y)))))														-- string
	end
	debug.ui.watchList:insertItem({name="math.deglb(math.deg(math.angle())) = ...", func = foo})

	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "bDegToRad(radToBDeg(angle()))      = "..tostring(math.bDegToRad(math.radToBDeg(math.angle(camera.x, camera.y, x, y))))														-- string
	end
	debug.ui.watchList:insertItem({name="math.deglb(math.deg(math.angle())) = ...", func = foo})

	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "angle()/0.017...                   = "..tostring(math.angle(camera.x, camera.y, x, y)/0.01745329251994329576923690768489)														-- string
	end
	debug.ui.watchList:insertItem({name="math.angle()/0.0174... = ...", func = foo})

	local foo = function()
		local x, y = camera:toWorld(love.mouse.getPosition())
		return "angle()*57.295...                  = "..tostring(math.angle(camera.x, camera.y, x, y)*57.295779513082320876798154814105)														-- string
	end
	debug.ui.watchList:insertItem({name="math.angle()*57.295... = ...", func = foo})

	debug.ui.watchList:insertItem({name="-------------------------------------"})
end

--local foo = function()
--	local wx, wy = camera:toWorld(love.mouse.getPosition())
--	local coll = require("code.physics").collision.rectangle(wx, wy, wx, wy)[1]
--	if tostring(coll) == "Fixture" then
--		return "collision.rectangle isAwake = "..tostring(coll:getBody():isAwake()--[[:getUserData():getClassName()--]])										-- string
--	else
--		return "collision.rectangle = ..."
--	end
--end
--debug.ui.watchList:insertItem({name="collision.rectangle = ...", func = foo})

local foo = function()
	return "love.system.getClipboardText = "..love.system.getClipboardText()
end
debug.ui.watchList:insertItem({name="love.system.getClipboardText = ...", func = foo})

debug.ui.watchList:insertItem({name="-------------------------------------"})

-- ui
if false then
	--[[
	local foo = function()
		return "worldEditor.ui.selectedEntity:getItemSelectedNumber() = " .. tostring(require("code.worldEditor").ui.selectedEntity:getItemSelectedNumber())
	end
	debug.ui.watchList:insertItem({name="worldEditor.ui.selectedEntity:getItemSelectedNumber() = ...", func = foo})
	--]]
	
	local foo = function()
		return "code.ui.currentActiveObject:getItemSelectedNumber() = " .. tostring(require("code.ui").currentActiveObject:getItemSelectedNumber())
	end
	debug.ui.watchList:insertItem({name="code.ui.currentActiveObject:getItemSelectedNumber() = ...", func = foo})
	
	local foo = function()
		return "code.ui.currentActiveObject._drawItemStart = " .. tostring(require("code.ui").currentActiveObject._drawItemStart)
	end
	debug.ui.watchList:insertItem({name="code.ui.currentActiveObject._drawItemStart = ...", func = foo})	
		
	local foo = function()
		return "code.ui.currentActiveObject._drawItemSelected = " .. tostring(require("code.ui").currentActiveObject._drawItemSelected)
	end
	debug.ui.watchList:insertItem({name="code.ui.currentActiveObject._drawItemSelected = ...", func = foo})	

end


if false then
	local foo = function()
		return "game.player.entity._moveSpeedCurrent = " .. tostring(game.player.entity._moveSpeedCurrent)														-- string
	end
	debug.ui.watchList:insertItem({name="game.player.entity._moveSpeedCurrent = ...", func = foo})	
	
	local foo = function()
		local sx, sy = game.player.entity.physics.body:getLinearVelocity()
		return "player:getLinearVelocity() lenght = " .. tostring(math.dist(0,0, sx, sy))														-- string
	end
	debug.ui.watchList:insertItem({name="player:getLinearVelocity() lenght = ...", func = foo})
	
	local foo = function()
		local sx, sy = game.player.entity.physics.body:getLinearVelocity()
		return "player:getLinearVelocity() x = " .. tostring(sx)														-- string
	end
	debug.ui.watchList:insertItem({name="player:getLinearVelocity() x = ...", func = foo})
	
	local foo = function()
		local sx, sy = game.player.entity.physics.body:getLinearVelocity()
		return "player:getLinearVelocity() y = " .. tostring(sy)														-- string
	end
	debug.ui.watchList:insertItem({name="player:getLinearVelocity() y = ...", func = foo})

	------------------------------------------------------
	
	local foo = function()
		local sx, sy = test.humanoid.physics.body:getLinearVelocity()
		return "test.humanoid:getLinearVelocity() lenght = " .. tostring(math.dist(0,0, sx, sy))														-- string
	end
	debug.ui.watchList:insertItem({name="test.humanoid:getLinearVelocity() lenght = ...", func = foo})
	
	local foo = function()
		local sx, sy = test.humanoid.physics.body:getLinearVelocity()
		return "test.humanoid:getLinearVelocity() x = " .. tostring(sx)														-- string
	end
	debug.ui.watchList:insertItem({name="test.humanoid:getLinearVelocity() x = ...", func = foo})	

end

if false then
	local foo = function()
		return "navMesh.clipper.result:size() = "..tostring(require("code.ai.pathfinding.navMesh").clipper.result:size())														-- string
	end
	debug.ui.watchList:insertItem({name="navMesh.clipper.result:size() = ...", func = foo})

	local foo = function()
		return "#navMesh.cell.polygons = "..tostring(#require("code.ai.pathfinding.navMesh").cell.polygons)														-- string
	end
	debug.ui.watchList:insertItem({name="#navMesh.cell.polygons = ...", func = foo})

	local foo = function()
		return "#navMesh.result.polygons = "..tostring(#require("code.ai.pathfinding.navMesh").result.polygons)														-- string
	end
	debug.ui.watchList:insertItem({name="#navMesh.result.polygons = ...", func = foo})

	--local foo = function()
	--	return "navMesh.poly2.polygonCut = "..tostring(require("code.ai.pathfinding.navMesh").poly2.polygonCut)														-- string
	--end
	--debug.ui.watchList:insertItem({name="navMesh.poly2.polygonCut = ...", func = foo})
end
if false then
	local foo = function()
		return "love.audio.getSourceCount() = "..tostring(love.audio.getSourceCount())														-- string
	end
	debug.ui.watchList:insertItem({name="love.audio.getSourceCount() = ...", func = foo})	
	
	--[[
	local foo = function()
		return "test.humanoid.isPlaying = "..tostring(test.humanoid.sound:isPlaying())														-- string
	end
	debug.ui.watchList:insertItem({name="test.humanoid.sound.isPlaying) = ...", func = foo})	
	
	local foo = function()
		return "test.humanoid.tell position in sec = "..tostring(test.humanoid.sound:tell())														-- string
	end
	debug.ui.watchList:insertItem({name="test.humanoid.sound.tell position in sec = ...", func = foo})		
	
	local foo = function()
		return "test.humanoid.getVolume = "..tostring(test.humanoid.sound:getVolume())														-- string
	end
	debug.ui.watchList:insertItem({name="test.humanoid.sound.getVolume) = ...", func = foo})	
		
	local foo = function()
		local x, y, z = test.humanoid.sound:getPosition()
		return "test.humanoid.sound.x = "..tostring(x)														-- string
	end
	debug.ui.watchList:insertItem({name="test.humanoid.sound.x) = ...", func = foo})

	local foo = function()
		local x, y, z = test.humanoid.sound:getPosition()
		return "test.humanoid.sound.y = "..tostring(y)														-- string
	end
	debug.ui.watchList:insertItem({name="test.humanoid.sound.y) = ...", func = foo})
	
	local foo = function()
		local sx, sy, sz = test.humanoid.sound:getPosition()
		local lx, ly, lz = love.audio.getPosition()
		return "test.humanoid.sound distance to listener in meters = "..tostring(math.dist(sx, sy, lx, ly)/require("code.world").meter)														-- string
	end
	debug.ui.watchList:insertItem({name="test.humanoid.sound.y) = ...", func = foo})	
	--]]
	
	local foo = function()
		return "code.sound.skip.skiped = "..tostring(require("code.sound").skip.skiped)														-- string
	end
	debug.ui.watchList:insertItem({name="code.sound.skip.skiped = ...", func = foo})	
end

if false then
	local foo = function()
		return "profiling light timer = "..require('code.graphics.light').debug.timer.result														-- string
	end
	debug.ui.watchList:insertItem({name=" = ...", func = foo})	
end	

if true then
	local foo = function()
		if require("code.physics").world then
			return "world.getContactCount() = "..require("code.physics").world:getContactCount()														-- string
		end
	end
	debug.ui.watchList:insertItem({name=" = ...", func = foo})	
end

------------------------------------------------------------------------------------------


local foo = function()
	debug.charts.graphMemory.on = not debug.charts.graphMemory.on
	debug.charts.graphFPS.on = not debug.charts.graphFPS.on
	debug.charts.delta.on = not debug.charts.delta.on
end
debug.ui.main:insertItem({name="main", func = foo})

local foo = function()
	debug.charts.drawcalls.on = not debug.charts.drawcalls.on
	debug.charts.canvasSwitches.on = not debug.charts.canvasSwitches.on
	debug.charts.canvases.on = not debug.charts.canvases.on
	debug.charts.images.on = not debug.charts.images.on
	debug.charts.texturememory.on = not debug.charts.texturememory.on
end
debug.ui.main:insertItem({name="graphics", func = foo})

local foo = function()
	
end
debug.ui.main:insertItem({name="UI", func = foo})

-- physics
debug.ui.main.physics = require("code.classes.UI.List"):newObject({name='Debug physics MainMenu', x=280, y=150})
debug.ui.main.physics.itemsMaxLengthInSymbols = 20
local foo = function()
	debug.ui.main.physics:toggle(true)
end
debug.ui.main:insertItem({name="physics", func = foo})
local foo = function()
	require("code.physics").debug:toggle()
	debug.charts.physicsBodyCount.on = require("code.physics").debug:isOn()
	debug.ui.main.physics.items[1].name = "on = "..tostring(require("code.physics").debug:isOn())
end
debug.ui.main.physics:insertItem({name="on = "..tostring(require("code.physics").debug:isOn()), func = foo})
local foo = function()
	if not require("code.physics").debug:isOn() then return false end
	debug.charts.physicsBodyCount.on = not debug.charts.physicsBodyCount.on
end
debug.ui.main.physics:insertItem({name="charts", func = foo})
local foo = function()
	require("code.physics").debug.draw:toggle()
end
debug.ui.main.physics:insertItem({name="draw", func = foo})
if on then
	require("code.physics").debug.draw:on()
end
function debug.ui.main.physics:off()
	require("code.physics").debug:off()
	debug.charts.physicsBodyCount.on = false
	debug.ui.main.physics.items[1].name = "on = "..tostring(require("code.physics").debug:isOn())
	debug.ui.main.physics:close()
end
-- end physics

local foo = function()
	debug.charts.entityCount.on = not debug.charts.entityCount.on
end
debug.ui.main:insertItem({name="other", func = foo})

local foo = function()
	debug.ui.luaMemory:toggle(true)
end
debug.ui.main:insertItem({name="lua memory explorer", func = foo})

local foo = function()
	debug.ui.watchList:toggle(true)
end
debug.ui.main:insertItem({name="watch list", func = foo})
