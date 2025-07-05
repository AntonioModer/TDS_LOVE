--[[
version 0.0.1
@todo 
	-+ изменить родительские параметры
--]]

local ClassParent = require('code.classes.Entity.Item.Weapon.Ranged')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end

ThisModule.fire = {}
ThisModule.fire.rate = {}
ThisModule.fire.rate.value = 400                                                                                                                -- |readonly!!!|; скорострельность, технических выстрелов в мин (без учета перезарядки); -1, 1 ... ; default = 120; -1 = infinite; реальный max = 600, если больше, то не хватает точности из-за низкого обновления таймера, т.е. процессор не успевает так быстро обновить таймер
ThisModule.fire.mode = -1                                                                                                                       -- режим стрельбы (fire mode); -1, 1 ... ; int; 1 = 'single'; -1 = 'automatic'; 3 = '3 bullets'
ThisModule.fire.rate.timer = {}
ThisModule.fire.rate.timer.handle = {}
ThisModule.fire.rate.timer.value = 60/ThisModule.fire.rate.value
ThisModule.fire.draw = {}
ThisModule.fire.draw.on = true
ThisModule.fire.draw.tick = false
ThisModule.fire.draw.count = 5
ThisModule.fire.recoil = {}
ThisModule.fire.recoil.physics = {}
ThisModule.fire.recoil.physics.linear = {}
ThisModule.fire.recoil.physics.linear.is = false
ThisModule.fire.recoil.physics.linear.power = 100
ThisModule.fire.recoil.physics.angular = {}
ThisModule.fire.recoil.physics.angular.is = true
ThisModule.fire.recoil.physics.angular.power = 3000

ThisModule.projectile = {}
ThisModule.projectile.type = 'Test'

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
--	print(object.allowUpdate)
	
	object.state:setState('onFloor', object)
	
	return object
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
end

----[[
function ThisModule:funcFire()
	-- shooting
	if self.state.ro_stateCurrentName == 'shooting' and self.magazine.size.current > 0 then
		local x, y = self.state.ro_stateCurrent.whoChangeMyState.physics.body:getWorldPoint(32, 0)
		ThisModule.collision.worldRayCast.ray.line.point1.x = x--self.sprite.transform.position.x --camera.x
		ThisModule.collision.worldRayCast.ray.line.point1.y = y--self.sprite.transform.position.y --camera.y
		ThisModule.collision.worldRayCast.ray.line.point2.x, ThisModule.collision.worldRayCast.ray.line.point2.y = camera:toWorld(love.mouse.getPosition())
		
		-- @todo +- реальный прицельный вектор игрока
--		local vec = math.vector(math.dist(ThisModule.collision.worldRayCast.ray.line.point1.x, ThisModule.collision.worldRayCast.ray.line.point1.y, ThisModule.collision.worldRayCast.ray.line.point2.x, ThisModule.collision.worldRayCast.ray.line.point2.y), 0):rotateInplace(self.state.ro_stateCurrent.whoChangeMyState.physics.body:getAngle())       -- дальность стрельбы до мышки
		local vec = math.vector(1000, 0):rotateInplace(self.state.ro_stateCurrent.whoChangeMyState.physics.body:getAngle())                               -- дальность стрельбы на фиксированную длинну
		
		-- not work
--		local vec = math.vector(ThisModule.collision.worldRayCast.ray.line.point2.x - ThisModule.collision.worldRayCast.ray.line.point1.x, ThisModule.collision.worldRayCast.ray.line.point2.y - ThisModule.collision.worldRayCast.ray.line.point1.y):rotateInplace(self.physics.body:getAngle())
--		print(ThisModule.collision.worldRayCast.ray.line.point2.x - ThisModule.collision.worldRayCast.ray.line.point1.x, ThisModule.collision.worldRayCast.ray.line.point2.y - ThisModule.collision.worldRayCast.ray.line.point1.y)
--		print(vec.x, vec.y)
		
		ThisModule.collision.worldRayCast.ray.line.point2.x, ThisModule.collision.worldRayCast.ray.line.point2.y = ThisModule.collision.worldRayCast.ray.line.point1.x + vec.x, ThisModule.collision.worldRayCast.ray.line.point1.y + vec.y
		
	--	if self.ray.line.point1 == self.ray.line.point2 then
	--		self.ray.line.point2.x = self.ray.line.point2.x + 0.0001
	--	end
		
		ThisModule.collision.worldRayCast.ray.hitList = require("code.physics").collision.worldRayCast:cast(ThisModule.collision.worldRayCast.ray.line, nil, ThisModule.collision.worldRayCast._funcFilter, nil, false)
		
		local hit = ThisModule.collision.worldRayCast.ray.hitList.hitClosest
		if hit.fixture then
			ThisModule.collision.worldRayCast._funcDo(hit.fixture, hit.x, hit.y, hit.xn, hit.yn, hit.fraction, self)
		end
		
		self.fire.draw.tick = true
		
		-- отдача от стрельбы
		if ThisModule.fire.recoil.physics.linear.is then
			local force = math.vector(
				ThisModule.collision.worldRayCast.ray.line.point2.x - ThisModule.collision.worldRayCast.ray.line.point1.x,
				ThisModule.collision.worldRayCast.ray.line.point2.y - ThisModule.collision.worldRayCast.ray.line.point1.y
			):normalizeInplace() * ThisModule.fire.recoil.physics.linear.power
			local wx, wy = self.state.ro_stateCurrent.whoChangeMyState.physics.body:getWorldVector(0, 0)--32*2)                                                                                                    -- точка прикладывания силы, по середине тела или в плече
			self.state.ro_stateCurrent.whoChangeMyState.physics.body:applyLinearImpulse(-force.x, -force.y, self.state.ro_stateCurrent.whoChangeMyState:getX()+wx, self.state.ro_stateCurrent.whoChangeMyState:getY()+wy)             -- двигает и вращает того кто стреляет
--			print(os.clock(), -force.x, -force.y, wx, wy)		
		end
		if ThisModule.fire.recoil.physics.angular.is then
			self.state.ro_stateCurrent.whoChangeMyState.physics.body:applyAngularImpulse(ThisModule.fire.recoil.physics.angular.power)                                                                             -- вращает того кто стреляет
		end
		
		self.magazine.size.current = self.magazine.size.current - 1
		
		print(os.clock(), 'shoot', self.magazine.size.current)
	end
	
end
--]]

return ThisModule