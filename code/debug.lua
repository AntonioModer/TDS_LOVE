--[[
version 0.2.15
@help 
	+ debug.traceback() помогает определить где выполняется данная строка кода
@todo 
	-?NO собственный debug.drawCalls()
	- profiling
		- love.draw() delay Chart
	-+ get Lua memory
		-+ применить UIList
	-+ draw graph	
	-+ save «.log»	
	-+ game debug console		
--]]

--[[
@help 
	+ меньше мусора(скачков памяти), больше задержка(меньше FPS)
	+ использовать gcFast, если память не оптимизирована
		+ если же память оптимизирована, то gcFast лучше не использовать
--]]
local gcFast = true
if gcFast then
	-- чтобы память в Lua не захломлялась (уменьшили паузу между шагами сборки мусора, если < 100 - значит паузы нету)(помагает уменьшить мусор)
	-- если "setpause" < 100 и "setstepmul" = 200, то грузит процессор и уменьшаются FPS !!!
	-- BEST:  "setpause" = 100, "setstepmul" = 200
	collectgarbage("setpause", 100)
	-- увеличили скорость работы сборщика мусора по сравнению с процессом выделения памяти (помагает уменьшить мусор) (def=200)
	collectgarbage("setstepmul", 200)
end

--jit.off()
if arg[#arg] == "-debug" then require("mobdebug").start() end																							-- ZeroBraneStudio debuger


local on = config.debug.on
local draw = {}
draw.on = config.debug.draw.on

debug.draw = {}
function debug.draw:isOn()
	return draw.on
end

function debug.draw:setOn(on)
	draw.on = true
end

function debug:isOn()
	return on
end

require("code.debug.log")
debug.consoleG = require("code.console")
require("code.debug.charts")
require("code.debug.ui")

function debug:off()
	on = false
	self.ui.main:close()
	self.ui.luaMemory:close()
	self.ui.watchList:close()
	debug.ui.main.physics:off()
end

function debug:on()
	on = true
	self.ui.main:open()
end

function debug:toggle()
	on = not on
	if on then
		self:on()
	else
		self:off()
	end
end

if not on then
	debug:off()
end

function debug:update(dt)
	-- update items in watchList
	if debug.ui.watchList:isOpen() then
		for i=1, #debug.ui.watchList.items do
			if debug.ui.watchList.items[i].func then
				debug.ui.watchList.items[i].name = debug.ui.watchList.items[i].func()
			end
		end
	end
	
	debug.charts.update(dt)
end

function debug.draw.func()
	debug.charts.draw()
end