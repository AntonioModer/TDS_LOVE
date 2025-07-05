
local ClassParent = require('code.classes.Entity.TestRectangle')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end


-- variables private
-- ...

-- variables protected, only in Class
-- ...

-- variables public
ThisModule.z = 1

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	arg.color = {125, 125, 125, 255}
	local object = ClassParent.newObject(self, arg)
	
	object.shadows.on = false
	object.shadows.directional.on = true
	object.shadows.directional.z = 2
	
	object.physics.fixture:setCategory(4)
--	object.physics.fixture:setMask(3)
--	object.physics.fixture:setGroupIndex(2)
	
	object.physics.fixture:setUserData({typeDraw = true, itemCanRestOnMe = true})
	
	return object
end

return ThisModule