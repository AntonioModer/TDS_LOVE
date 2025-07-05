--[[
version 0.0.1
@todo 
	
--]]

local ClassParent = require('code.classes.Entity')
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


-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	
	return object
end

-- test
function ThisModule:boom(r)
	local r = r or 50
	local count = r/2
	for i = 1, count do
		local angle = (2*math.pi)/count*i
--		print(angle)
		
		local posx = self:getX()+r*math.cos(angle)
		local posy = self:getY()+r*math.sin(angle)
		
		local projectile = require('code.classes.Entity.Item.Projectile.Explosion'):newObject({x=self:getX(), y=self:getY()})
		local force = math.vector(posx-self:getX(), posy-self:getY()):normalizeInplace() * 100
		projectile.physics.body:applyLinearImpulse(force.x, force.y)
		projectile:useStart(1, projectile)
		projectile.state:setState('onFloor', projectile)
		
		local projectile = require('code.classes.Entity.Item.Projectile.Explosion'):newObject({x=self:getX(), y=self:getY()})
		local force = math.vector(posx-self:getX(), posy-self:getY()):normalizeInplace() * 100
		projectile.physics.body:applyLinearImpulse(force.x, force.y)
		projectile:useStart(1, projectile)	
	end
	self:destroy()
end

return ThisModule