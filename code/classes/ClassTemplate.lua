--[[
@version 0.1.12
@help 
	* стандартный шаблон класса-потомка
--]]

local ClassParent = require('code.Class')																										-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private
local privateVar = ThisModule._myClassName .. '.privateVar'																						-- example

-- variables static protected, only in Class
ThisModule._protectedVar = ThisModule._myClassName .. '._protectedVar'																			-- example

-- variables static public
ThisModule.publicVar = ThisModule._myClassName .. '.publicVar'																					-- example
ThisModule.x = 0																																-- example
ThisModule.y = 0																																-- example

-- methods static private
local function methodPrivate()																													-- example
	
end

-- methods static protected
function ThisModule:_methodProtected()																											-- example
	
end

-- methods static public
function ThisModule:newObject(arg)																												-- example; rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- variables nonstatic protected
	object._protectedVar = 'object' .. ThisModule._myClassName .. '._protectedVar'
	
	-- nonstatic variables, methods; init new variables from methods arguments
	object.publicVar = 'object' .. ThisModule._myClassName .. '.publicVar'
	object.x = arg.x
	object.y = arg.y
	
	return object																																-- be sure to return new object
end

function ThisModule:draw()
	if self.destroyed then return nil end																										-- reserved; тут не нужен вызов ошибки
	
	-- ...
end

return ThisModule																																-- reserved
