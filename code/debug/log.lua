--[[
version 0.1.5
@help 
	+ файл записывается только в AppData
@todo 
	- last.log -> lastLog.lua; сохранять данные как Lua таблицы; это может пригодится для сбора данных
--]]

local file = require('code.file')
debug.log = {}
debug.log.takePrint = false																				-- если нужно писать в лог через print(), то true

local success, err
if not love.filesystem.exists('logs') then
	success = love.filesystem.createDirectory('logs')
end
if not love.filesystem.exists('temp') then
	success = love.filesystem.createDirectory('temp')
end
debug.log.f, err = love.filesystem.newFile([[/logs/last.log]], 'w')
if err then error(err) end

-- example
--print(arg[1])
--debug.log.f = io.open(love.filesystem.getWorkingDirectory()..[[/logs/log.log]], 'w')				-- lua
--if not debug.log.f then
--	success = os.execute("mkdir " .. [[logs]])														-- create new folder
--	debug.log.f = io.open(love.filesystem.getWorkingDirectory()..[[/logs/log.log]], 'w')
--end


-- --------------------------------------------- example
--success, err = debug.log.f:open('w')
--print(success, err)
--print(debug.log:isOpen())

--success, err = debug.log:write('test')
--print(success, err)

--success, err = debug.log:flush()
--print(success, err)

--success = debug.log:close()
--print(success)

--print()
-- --------------------------------------------- example end

function debug.log:write(string)
	local success, err = self.f:write(string)
	self.f:flush()
end

-- new line
function debug.log:writenl(string)
	local success, err = self.f:write('\n'..string)
	self.f:flush()
end

function debug.log:writeDate()
	debug.log.f:write('\n\n############[ '..os.date())
	self.f:flush()
end

-- rewrite function print()
local func = _G['print']
_G['print'] = function(...)
	local args = {...}
	local str = [[]]
	for k, v in ipairs(args) do
		str = str..tostring(v).."	"
	end	
	if debug.log.takePrint then
		debug.log.f:write('\n'..tostring(str))
		debug.log.f:flush()
	end
	return func(...)
end

function debug.log:setTakePrint(set)
	if type(set) == 'boolean' then
		self.takePrint = set
	else
		error([[argument must be 'bollean' type, not ']]..type(set)..[[' type]])
	end
end

-- rewrite love.errhand(msg), записываем ошибки в log
-- @todo - add love.window.getMode()
local func = _G.love.errhand
_G.love.errhand = function(...)
	debug.log:writeDate()
	debug.log.f:write('\n############[ Error: '..(...)..'\n'..debug.traceback()..'\n\n')
	debug.log:writenl("############[ finish block log")
	debug.log.f:flush()
	
--	require("file").copy(love.filesystem.getWorkingDirectory()..[[/logs/log.log]], love.filesystem.getWorkingDirectory()..[[/logs/error ]]..os.date("%Y.%m.%d-%H.%M.%S")..[[.log]])	-- lua
	
	success = love.filesystem.write([[/logs/error ]]..os.date("%Y.%m.%d-%H.%M.%S")..[[.log]], love.filesystem.read([[/logs/last.log]]))									-- love
	
	love.graphics.present()
    love.graphics.newScreenshot():encode('png', [[/logs/lastError.png]])
	
	return func(...)
end

-- info for debug
function debug.log:getInfo()
	debug.log:writeDate()
	debug.log:writenl(_VERSION..", "..jit.version.."("..jit.arch..")"..", LuaJIT on = "..tostring(jit.status()))
	
	local major, minor, revision, codename = love.getVersion()
	debug.log:writenl(string.format("LOVE2D version = %d.%d.%d (%s)", major, minor, revision, codename))
	
	debug.log:writenl("Game version = "..config.gameVersion)
	debug.log:writenl('OperationSystem = '..love.system.getOS())
	debug.log:writenl('ProcessorCount = '..love.system.getProcessorCount())
	
	local name, version, vendor, device = love.graphics.getRendererInfo()
	debug.log:writenl(string.format("RendererInfo: name = %s, version = %s, vendor = %s, device = %s", name, version, vendor, device))
	
	debug.log:writenl("Modes: ")
	debug.fullscreenModes = love.window.getFullscreenModes()																					-- !!! new public table
	table.sort(debug.fullscreenModes, function(a, b) return a.width*a.height < b.width*b.height end)											-- sort from smallest to largest
	for i, v in ipairs(debug.fullscreenModes) do
		debug.log:write(v.width ..":".. v.height ..", ")
	end
	
	debug.log:writenl("LOVE2D graphics is supported: ")
	local features = love.graphics.getSupported()
	for k, v in pairs(features) do
		debug.log:write(k.." = "..tostring(v)..", ")
	end
	
	debug.log:writenl("LOVE2D available compressed image formats: ")
	local formats = love.graphics.getCompressedImageFormats()
	for k, v in pairs(formats) do
		debug.log:write(k.." = "..tostring(v)..", ")
	end
	
	debug.log:writenl("LOVE2D available Canvas formats: ")
	local formats = love.graphics.getCanvasFormats()
	for k, v in pairs(formats) do
		debug.log:write(k.." = "..tostring(v)..", ")
	end
	
	debug.log:writenl("LOVE2D system limits: ")
	local limits = love.graphics.getSystemLimits()
	for k, v in pairs(limits) do
		debug.log:write(k.." = "..tostring(v)..", ")
	end
	debug.log:writenl("############[ finish block log")
end
debug.log:getInfo()
