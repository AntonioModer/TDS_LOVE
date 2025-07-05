--[[
@version 0.0.1
@help 
	* 
@todo 
	+ sprite
	-+ инфа в UI
--]]

local ClassParent = require('code.classes.Entity.Item.Ammo')																							-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private


-- variables static protected, only in Class
ThisModule._projectileType = 'Test'

-- variables static public

-- methods static private
-- methods static protected

-- methods static public
function ThisModule:newObject(arg)																												-- example; rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
--	print(ThisModule._projectileType)
	
	object.state:setState('onFloor', object)
	
	return object																																-- be sure to return new object
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
end

return ThisModule																																-- reserved
