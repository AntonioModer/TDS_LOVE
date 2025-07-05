--[[
version 0.0.3
--]]

local ManagerFilesystem = {}

local success;
if not love.filesystem.exists('save') then
	success = love.filesystem.createDirectory('save')
end
if not love.filesystem.exists('save/worlds') then
	success = love.filesystem.createDirectory('save/worlds')
end

-- -------------------------- tests
--print([[argLL]], table.concat(argLL, ', '))
--print([[love.filesystem.getSourceBaseDirectory():]])                            -- +- нету полного пути в .exe
--	print([[]], love.filesystem.getSourceBaseDirectory())
--print([[love.filesystem.getSource():]])                                         -- @todo - test in .love
--	print([[]], love.filesystem.getSource())	
--print([[love.filesystem.getWorkingDirectory():]])                             -- +
--	print([[]], love.filesystem.getWorkingDirectory())
--print([[love.filesystem.getAppdataDirectory():]])
--	print([[]], love.filesystem.getAppdataDirectory())
--print([[love.filesystem.getIdentity():]])
--	print([[]], love.filesystem.getIdentity())
--print([[love.filesystem.getSaveDirectory():]])
--	print([[]], love.filesystem.getSaveDirectory())                             -- + если используется love.filesystem
--print([[love.filesystem.getUserDirectory():]])
--	print([[]], love.filesystem.getUserDirectory())


return ManagerFilesystem