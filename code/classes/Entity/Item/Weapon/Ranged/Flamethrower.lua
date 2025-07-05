--[[
version 0.0.4
@todo 
	
--]]

local ClassParent = require('code.classes.Entity.Item.Weapon.Ranged')
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
ThisModule.image = false--ThisModule._modGraph.images.items.weapons.rocketLauncher.onFloor
ThisModule.sprite = ThisModule._modGraph.sprites.items.weapons.rocketLauncher.onFloor

ThisModule.fire = {}
ThisModule.fire.rate = {}
ThisModule.fire.rate.value = 600                                                                                                                -- |readonly!!!|; скорострельность, технических выстрелов в мин (без учета перезарядки); -1, 1 ... ; default = 120; -1 = infinite; реальный max = 600, если больше, то не хватает точности из-за низкого обновления таймера, т.е. процессор не успевает так быстро обновить таймер
ThisModule.fire.mode = -1                                                                                                                       -- режим стрельбы (fire mode); -1, 1 ... ; int; 1 = 'single'; -1 = 'automatic'; 3 = '3 bullets'
ThisModule.fire.rate.timer = {}
ThisModule.fire.rate.timer.handle = {}
ThisModule.fire.rate.timer.value = 60/ThisModule.fire.rate.value
ThisModule.fire.draw = {}
ThisModule.fire.draw.on = false
ThisModule.fire.draw.tick = false
ThisModule.fire.draw.count = 5
ThisModule.fire.recoil = {}
ThisModule.fire.recoil.physics = {}
ThisModule.fire.recoil.physics.linear = {}
ThisModule.fire.recoil.physics.linear.is = false
ThisModule.fire.recoil.physics.linear.power = 100
ThisModule.fire.recoil.physics.angular = {}
ThisModule.fire.recoil.physics.angular.is = false
ThisModule.fire.recoil.physics.angular.power = 3000
ThisModule.fire.force = 15

ThisModule.damage = {}
ThisModule.damage.physically = 20                                                                                                               -- за один выстрел, удар; 0 ... ;
ThisModule.damage.physicallyForce = 200                                                                                                          -- сила отталкивания при уроне
ThisModule.damage.thermal = 0
ThisModule.damage.chemical = 0
ThisModule.damage.electric = 0

ThisModule.magazine = {}
ThisModule.magazine.size = {}
ThisModule.magazine.size.max = 3000
ThisModule.magazine.size.current = 3000

ThisModule.projectile = {}
ThisModule.projectile.type = 'Fire'                                                                                                       -- @todo + учитывать при перезарядке

ThisModule._statesAllTable = {
	onFloor = {
--		, image = ThisModule._modGraph.images.items.weapons.test.onFloor
		sprite = ThisModule._modGraph.sprites.items.weapons.rocketLauncher.onFloor
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			ClassParent._statesAllTable.onFloor.funcAction(selfState, selfObjectState, whoChangeMyState, other)
			
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt._light.on = false
		end
	}
	, taken = {
--		, image = ThisModule._modGraph.images.items.weapons.test.taken
		sprite = ThisModule._modGraph.sprites.items.weapons.rocketLauncher.taken
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.image = selfState.image
			selfEnt.sprite = selfState.sprite
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.body:setActive(false)
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state taken')
			selfEnt.timer:clear()
			
			selfEnt._light.on = false
		end
	}
	, shooting = {                                                                                                                              -- стрельба                                                                                                                       -- @todo -? rename to "firing"
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state shooting')
			
			-- test
			selfEnt:funcFire()
			if selfEnt.fire.mode == -1 then
				selfEnt.fire.rate.timer.handle = selfEnt.timer:every(selfEnt.fire.rate.timer.value, function() selfEnt:funcFire() end)
			end
			
			selfEnt._light.on = true
		end
	}
	, aiming = {                                                                                                                                -- прицеливание
		sprite = ThisModule._modGraph.sprites.items.weapons.rocketLauncher.aiming
		, funcCondition = ClassParent._statesAllTable.aiming.funcCondition
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.sprite = selfState.sprite
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state aiming')
			selfEnt.timer:clear()
			
			selfEnt._light.on = false
		end
	}
	, reloading = {                                                                                                                                -- прицеливание
		sprite = ThisModule._modGraph.sprites.items.weapons.rocketLauncher.taken
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.sprite = selfState.sprite
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state reloading')
			
			selfEnt.timer:clear()
			selfEnt.fire.rate.timer.handle = selfEnt.timer:after(2, function() selfEnt:funcReload(other) end)
			
			selfEnt._light.on = false
		end		
	}
	, throw = ClassParent._statesAllTable.throw
	, dragged = ClassParent._statesAllTable.dragged
}

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	object.timer = require('code.timer').new()
	
	object.fire = {}
	object.fire.rate = {}
	object.fire.rate.value = self.fire.rate.value
	object.fire.mode = self.fire.mode
	object.fire.rate.timer = {}
	object.fire.rate.timer.handle = {}
	object.fire.rate.timer.value = self.fire.rate.timer.value
	object.fire.draw = {}
	object.fire.draw.on = ThisModule.fire.draw.on
	object.fire.draw.tick = ThisModule.fire.draw.tick
	object.fire.draw.count = self.fire.draw.count
	object.fire.recoil = {}
	object.fire.recoil.physics = {}
	object.fire.recoil.physics.linear = {}
	object.fire.recoil.physics.linear.is = ThisModule.fire.recoil.physics.linear.is
	object.fire.recoil.physics.linear.power = ThisModule.fire.recoil.physics.linear.power
	object.fire.recoil.physics.angular = {}
	object.fire.recoil.physics.angular.is = ThisModule.fire.recoil.physics.angular.is
	object.fire.recoil.physics.angular.power = ThisModule.fire.recoil.physics.angular.power	
	object.fire.force = ThisModule.fire.force
	
	object.magazine = {}
	object.magazine.size = {}
	object.magazine.size.max = ThisModule.magazine.size.max
	object.magazine.size.current = ThisModule.magazine.size.current
	object.magazine.isFull = ThisModule.magazine.isFull
	
	object.info = {}
	object.info[1] = function () return 'magazine size = ' .. object.magazine.size.current end
	
	object._light = require("code.classes.Entity.Light"):newObject({x = object:getX(), y = object:getY()})
	object._light.shadows.mobility = 'dynamic'
	object._light.on = false
	object._light.allowToSave = false
	object._light.image = false
	object._light.dontSelectInWorldEditor = true
	
	object.state:setState('onFloor', object)
	
	return object
end


function ThisModule:funcFire()
	----[[ shooting
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
		
		--[[ hit
		ThisModule.collision.worldRayCast.ray.hitList = require("code.physics").collision.worldRayCast:cast(ThisModule.collision.worldRayCast.ray.line, nil, ThisModule.collision.worldRayCast._funcFilter, nil, false)
		local hit = ThisModule.collision.worldRayCast.ray.hitList.hitClosest
		if hit.fixture then
			ThisModule.collision.worldRayCast._funcDo(hit.fixture, hit.x, hit.y, hit.xn, hit.yn, hit.fraction, self)
		end
		--]]
		
		-- Projectile test
		local x, y = self.state.ro_stateCurrent.whoChangeMyState.physics.body:getWorldPoint(32+5, 0)
		local projectile
		local force
		
--		local random = math.random(-50, 50)/100
----		print(random)
--		local force = math.vector(
--			ThisModule.collision.worldRayCast.ray.line.point2.x - ThisModule.collision.worldRayCast.ray.line.point1.x,
--			ThisModule.collision.worldRayCast.ray.line.point2.y - ThisModule.collision.worldRayCast.ray.line.point1.y
--		):normalizeInplace():rotateInplace(random) * self.fire.force
		
		for i=-3, 3, 1 do
			-- @todo - плавная яркость появления и затухания света, чтобы небыло резких вспышок света при его спавне и удалении
--			local lightOn
--			if i == 0 and self.magazine.size.current/math.nSA(self.magazine.size.current, 10) == 1 then lightOn = true end
--			print(self.magazine.size.current/math.nSA(self.magazine.size.current, 30))
--			print(math.randomFloat(0, 100))

			projectile = require('code.classes.Entity.Item.Projectile.' .. self.projectile.type):newObject({lightOn=lightOn, x=x, y=y, angle=math.radToBDeg(vec:angleTo())})
			local random = math.random(-5, 5)/100
			force = math.vector(
				ThisModule.collision.worldRayCast.ray.line.point2.x - ThisModule.collision.worldRayCast.ray.line.point1.x,
				ThisModule.collision.worldRayCast.ray.line.point2.y - ThisModule.collision.worldRayCast.ray.line.point1.y
			):normalizeInplace():rotateInplace((i/10)+random) * self.fire.force
			projectile.physics.body:applyLinearImpulse(force.x, force.y)		
			projectile:useStart(1, self)	
		end
		
--		self.fire.draw.tick = true
		
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
	--]]
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
	self._light:setPosition(self.sprite.transform.position.x, self.sprite.transform.position.y)
end

return ThisModule