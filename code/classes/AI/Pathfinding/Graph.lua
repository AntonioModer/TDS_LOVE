--[[
version 0.0.1
@help 
	+ 
@todo 

--]]

local ClassParent = require('code.classes.Graph.Graph')																										-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private
-- ...

-- variables static protected, only in Class
-- ...

-- variables static public
-- ...

-- methods static private
-- ...

-- methods static protected
-- ...

-- methods static public
function ThisModule:newObject(arg)																												-- rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- nonstatic variables, methods; init new variables from methods arguments
	object.nodes = self:newObjectsWeakTable()																									-- read only!!!; key and value is <table>; если node будет удален из-вне, то сборщик мусора удалит и из этой таблицы				
	object.nodesCount = 0																														-- read only!!!;
	
	return object																																-- be sure to return new object
end

function ThisModule:draw(pathfinding)
	if self.destroyed then return nil end																										-- reserved; тут не нужен вызов ошибки
	
	for k, node in pairs(self.nodes) do
		if node.draw then node:draw('connections', pathfinding) end
	end
	
	for k, node in pairs(self.nodes) do
		if node.draw then node:draw('point', pathfinding) end
	end		
end

return ThisModule																																-- reserved
