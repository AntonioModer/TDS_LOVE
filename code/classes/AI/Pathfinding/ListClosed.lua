--[[
version 0.1.0
@help 
	+ 
--]]

local ClassParent = require('code.Class')																										-- reserved; you can change the string-name of import-module (parent Class) 
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
	object.list = {}
	
	return object																																-- be sure to return new object
end

function ThisModule:addNode(node)
	self.list[node] = true
end

-- return false if node no exist.
function ThisModule:findNode(node)
	return self.list[node] ~= nil
end

function ThisModule:delNode(node)
	self.list[node] = nil
end

function ThisModule:isEmpty() 
	for k, v in pairs(self.list) do
		return false
	end
	
	return true
end

function ThisModule:clear()
	self.list = {}
end

return ThisModule																																-- reserved
