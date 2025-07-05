--[[
version 0.0.4
@todo 
	@todo -+ параметры
		-+ скорострельность
			* https://ru.wikipedia.org/wiki/%D0%A1%D0%BA%D0%BE%D1%80%D0%BE%D1%81%D1%82%D1%80%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE%D1%81%D1%82%D1%8C
			+ выстрелов в
				+? мин
				-?NO сек
			* техническая (темп стрельбы)
			+? name = fireRate
			-? name = shootingRate
			-+ timer
				-+ hump.timer
				-+ если нажат курок, то каждые х сек стрелять оружием
				- точность, оптимизация
					-?NO чтобы точность была высокой, обновлять таймеры отдельно от Entity
		-+ отдача от стрельбы?
			+ name = recoil	
		- ...
	@todo -+ стрельба [
		@todo 2 - нельзя стрелять одиночными чаще чем ThisModule.fire.rate.timer.value
			* а то сейчас получается что стрелять одиночными можно быстрее чем очередью
			* т.е. это в оружии скорость движения боеприпаса из магазина в дуло плюс готовность к выстрелу
		+- прицеливание
		- смотри свой старый код
		- logic
		@todo -+ боеприпасы (ammo)
		@todo -+ магазины
			-+? магазин автоматически перезаряжается
			+ name = magazine
			-? как энтити
				+ пока нет, как Луа-таблица
		-+ тип стрельбы
			-+ режим стрельбы
				+ name = fire.mode
				+ смена режима кнопкой
				+ одиночный
				+ автоматический
			-?NO смена типа патронов
		+ отдача от стрельбы
		@todo -+ отнимать health
	]
	-+ reload
	-+ инфа в UI
	@todo - по типам
		- ружья
		- пулеметы
		- автоматы
		- пистолеты
		- пистолеты-пулемёты
	@todo 1 -+ переделать ThisModule:funcFire(), выстреливать Projectile
		@todo 1.1 -+ Projectile
		@todo 1.2 -+ выстреливать Projectile в ThisModule:funcFire()
			-+ толкать силой
				+ импульсом
					* летит как пуля или брошенное тело, не как ракета
					-+?NOYES не всегда подходит, т.к. импульсное ускорение зависит от ФПС, чем меньше ФПС тем медленнее скорость и на меньшее расстояние пролетит снаряд, т.е нельзя обеспечить гарантированный пролет снарядом фиксированной дистанции и фиксированную скорость
						* это не подходит, если object.physics.body:setLinearDamping(> 2); а если LinearDamping <= 2, то это не заметно (я это протестировал)
						@todo 1.2.1 +? конролировать длинну пролета, смотри Projectile class
				@todo - с постоянной силой
					* летит как ракета
					- обеспечить гарантированный пролет фиксированной дистанции
						-? таймер тут не применять, т.к. тормоза не влияют на таймер, и при высоких тормазах таймер закончится на половине пути траектории ракеты
						- постоянно обновлять счетчиком "топлива ракеты"
				-?NotNow с переменной силой во времени, для красивого эффекта: сначала вылетает ракета, а потом она летит в цель
		-+ в Ammo указывать тип боеприпасов, т.е. Ammo - это просто коробка с боеприпасами
			+ следовательно изменить ThisModule.magazine.ammo.type на ThisModule.projectileType
				- множество типов боеприпасов, не только один, нужно для арбалета и разных стрел
		-+ изменить параметры
--]]

local ClassParent = require('code.classes.Entity.Item.Weapon')
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
ThisModule.image = false--ThisModule._modGraph.images.items.weapons.test.onFloor
ThisModule.sprite = ThisModule._modGraph.sprites.items.weapons.test.onFloor

ThisModule._statesAllTable = {
	onFloor = {
--		, image = ThisModule._modGraph.images.items.weapons.test.onFloor
		sprite = ThisModule._modGraph.sprites.items.weapons.test.onFloor
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			ClassParent:getClassParent()._statesAllTable.onFloor.funcAction(selfState, selfObjectState, whoChangeMyState, other)
			
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.timer:clear()
--			print(os.clock(), 'state onFloor')
		end
	}
	, taken = {
--		, image = ThisModule._modGraph.images.items.weapons.test.taken
		sprite = ThisModule._modGraph.sprites.items.weapons.test.taken
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.image = selfState.image
			selfEnt.sprite = selfState.sprite
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.body:setActive(false)
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state taken')
			selfEnt.timer:clear()
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
		end
	}
	, aiming = {                                                                                                                                -- прицеливание
		sprite = ThisModule._modGraph.sprites.items.weapons.test.aiming
		, funcCondition = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			print(game.player.dragHands.is)
			if game.player.dragHands.is --[[or (not whoChangeMyState.throwItemInHands) and (not self._bodyPart.hands.entityIn) --]]then return false end
--			if whoChangeMyState.state and whoChangeMyState.state.ro_stateCurrentName ~= 'aiming' then return false end
			return true
		end
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.sprite = selfState.sprite
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state aiming')
			selfEnt.timer:clear()
		end
	}
	, reloading = {                                                                                                                                -- прицеливание
		sprite = ThisModule._modGraph.sprites.items.weapons.test.taken
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.sprite = selfState.sprite
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state reloading')
			
			selfEnt.timer:clear()
			selfEnt.fire.rate.timer.handle = selfEnt.timer:after(2, function() selfEnt:funcReload(other) end)
		end		
	}
	, throw = ClassParent:getClassParent()._statesAllTable.throw
	, dragged = ClassParent:getClassParent()._statesAllTable.dragged
}

ThisModule.collision = {}
ThisModule.collision.worldRayCast = {}
ThisModule.collision.worldRayCast.ray = {}
ThisModule.collision.worldRayCast.ray.line = math.line()
ThisModule.collision.worldRayCast.ray.hitList = {}
ThisModule.collision.worldRayCast.ray.hitList.hitClosest = {}
ThisModule.collision.worldRayCast.ray.hitList.hitClosest.fraction = math.huge
ThisModule.collision.worldRayCast.filterNames = {
"Entity.Test1"
, "Entity.Test2"
, "Entity.TestRectangle"
, "Entity.Door"
, "Entity.Door.DoorWall"
, "Entity.Humanoid"
}
function ThisModule.collision.worldRayCast._funcFilter(fixture, x, y, xn, yn, fraction)
	local pass = false
	local object = fixture:getBody():getUserData()
	if object._TABLETYPE == "object" and (not object.destroyed) and fixture:isSensor() == false then
		for i, v in ipairs(ThisModule.collision.worldRayCast.filterNames) do
			if object:getClassName() == v then
				pass = true
			end
		end
	end
	
	return pass
end
function ThisModule.collision.worldRayCast._funcDo(fixture, x, y, xn, yn, fraction, selfEnt)
	local entity = fixture:getBody():getUserData()
	if entity._TABLETYPE == "object" and (not entity.destroyed) then
		local force = math.vector(
			ThisModule.collision.worldRayCast.ray.line.point2.x - ThisModule.collision.worldRayCast.ray.line.point1.x,
			ThisModule.collision.worldRayCast.ray.line.point2.y - ThisModule.collision.worldRayCast.ray.line.point1.y
		):normalizeInplace() * selfEnt.damage.physicallyForce
		entity.physics.body:applyLinearImpulse(force.x, force.y, x, y)
--		entity.physics.body:applyForce(force.x, force.y, x, y)
		
--		print(os.clock(), force.x, force.y, x, y)

		entity:damage(selfEnt.damage.physically)
	end
end

ThisModule.fire = {}
ThisModule.fire.rate = {}
ThisModule.fire.rate.value = 60                                                                                                                -- |readonly!!!|; скорострельность, технических выстрелов в мин (без учета перезарядки); -1, 1 ... ; default = 120; -1 = infinite; реальный max = 600, если больше, то не хватает точности из-за низкого обновления таймера, т.е. процессор не успевает так быстро обновить таймер
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
ThisModule.fire.force = 50

ThisModule.damage = {}
ThisModule.damage.physically = 20                                                                                                               -- за один выстрел, удар; 0 ... ;
ThisModule.damage.physicallyForce = 200                                                                                                          -- сила отталкивания при уроне
ThisModule.damage.thermal = 0
ThisModule.damage.chemical = 0
ThisModule.damage.electric = 0

ThisModule.magazine = {}
ThisModule.magazine.size = {}
ThisModule.magazine.size.max = 30
ThisModule.magazine.size.current = 30

ThisModule.projectile = {}
ThisModule.projectile.type = 'Rocket'                                                                                                       -- @todo + учитывать при перезарядке

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
	object.magazine.size.max = 30
	object.magazine.size.current = 30
	object.magazine.isFull = ThisModule.magazine.isFull
	
	object.info = {}
	object.info[1] = function () return 'magazine size = ' .. object.magazine.size.current end
	
	return object
end

--[[
	* @arg mode <number> <nil> = 1 ... (default 1)
	* @arg whoUsedMe <entity>
	* @arg other <any>
--]]
function ThisModule:useStart(mode, whoUsedMe, other)
	if mode == nil then return false end
	
--	print(os.clock(), 'start use', self.entityName, mode, whoUsedMe.entityName)
	
--	if game.player.dragHands.is == true then
--		if mode == 1 then
--			self.state:setState('throw', whoUsedMe)
--		end
--	else
		if mode == 1 then
			self.state:setState('throw', whoUsedMe)
			if self.state.ro_stateCurrent == self._statesAllTable.aiming then
				self.state:setState('shooting', whoUsedMe)
			end		
		elseif mode == 2 then
			self.state:setState('aiming', whoUsedMe)
		elseif mode == 3 then
			if self.fire.mode == -1 then
				self.fire.mode = 1
			elseif self.fire.mode == 1 then
				self.fire.mode = -1
			end
		elseif mode == 4 then
			self.state:setState('reloading', whoUsedMe, other)
		end
--	end
end

--[[
	* @arg mode <number> <nil> = 1 ... (default 1)
	* @arg whoUsedMe <entity>
	* @arg other <any>
	@todo -? rename to useEnd()
--]]
function ThisModule:useStop(mode, whoUsedMe, other)
	if mode == nil then return false end
	
--	print(os.clock(), 'stop use', self.entityName, mode, whoUsedMe.entityName)
	
	if game.player.dragHands.is == true then return false end
	if mode == 1 and self.state.ro_stateCurrent == self._statesAllTable.shooting then
		self.state:setState('aiming', whoUsedMe)
	elseif (mode == 2 or mode == 4) and self.state.ro_stateCurrent ~= self._statesAllTable.taken then
		self.state:setState('taken', whoUsedMe)
	end
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
	if self.timer then
		self.timer:update(arg.dt)
		if self.destroyed then return false end
	end
	
	----[[ shooting
	if self.state.ro_stateCurrentName == 'shooting' then
		
	end
	--]]
	
--	print('update')
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
		local projectile = require('code.classes.Entity.Item.Projectile.' .. self.projectile.type):newObject({x=x, y=y, angle=math.radToBDeg(vec:angleTo())})
		local force = math.vector(
			ThisModule.collision.worldRayCast.ray.line.point2.x - ThisModule.collision.worldRayCast.ray.line.point1.x,
			ThisModule.collision.worldRayCast.ray.line.point2.y - ThisModule.collision.worldRayCast.ray.line.point1.y
		):normalizeInplace() * self.fire.force
		projectile.physics.body:applyLinearImpulse(force.x, force.y)		
		projectile:useStart(1, self)
		
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
	--]]
end

--[[
	* @arg arg.ammo <object Entity.Item.Ammo> <table>
	* @arg arg.ammoInThisUIList <object UIList>
	* @arg arg.ammoInThisEntityInventory <table> (see Humanoid.inventory)
	@todo 
		-+ not done
		- с помощью единичных снарядов в рюкзаке
--]]
function ThisModule:funcReload(arg)
	-- брать патроны из ammo и ложить в magazine
	
	----[[
	if type(arg.ammo) ~= 'table' then
		if arg.ammo:getProjectileType() == self.projectile.type then
			self.magazine.size.current = self.magazine.size.current + arg.ammo:take(self.magazine.size.max - self.magazine.size.current)
		end
	else
		for i, ammoEntity in ipairs(arg.ammo) do
			if ammoEntity and string.find(ammoEntity:getClassName(), '.Ammo') then
				if ammoEntity:getProjectileType() == self.projectile.type then
					self.magazine.size.current = self.magazine.size.current + ammoEntity:take(self.magazine.size.max - self.magazine.size.current)
				end
				if ammoEntity.count == 0 then
					-- удаляем
					if arg.ammoInThisUIList then
						for i=1, #arg.ammoInThisUIList.items do
							local ammoEntityInUIList = arg.ammoInThisUIList.items[i].userData
							if ammoEntityInUIList == ammoEntity then
								arg.ammoInThisUIList:removeItem(i)
								break
							end
						end
					end
					if arg.ammoInThisEntityInventory then
						arg.ammoInThisEntityInventory:removeItem(ammoEntity)
					end
					ammoEntity:destroy()
				end
				if self.magazine:isFull() then
					break
				end
			end
		end
	end
	--]]
	
	print(os.clock(), 'reload end')
	
	if (type(config.controls.player.itemUse[2]) == 'number' and love.mouse.isDown(config.controls.player.itemUse[2]))
	  or (type(config.controls.player.itemUse[2]) == 'string' and love.keyboard.isDown(config.controls.player.itemUse[2])) then
		self.state:setState('aiming', self.state.ro_stateCurrent.whoChangeMyState)
	else
		self.state:setState('taken', self.state.ro_stateCurrent.whoChangeMyState)
	end
end

function ThisModule.magazine:isFull()
	if self.size.current == self.size.max then
		return true
	else
		return false
	end
end

-- @todo - 
function ThisModule:draw(arg)
	ClassParent.draw(self, arg)
	
	-- shoot
	if self.fire.draw.on == true and self.fire.draw.tick == true then
		require("code.physics").collision.worldRayCast.test.draw(ThisModule.collision.worldRayCast)
		
		self.fire.draw.count = self.fire.draw.count - 1
		if self.fire.draw.count == 0 then
			self.fire.draw.tick = false
			self.fire.draw.count = ThisModule.fire.draw.count
		end
	end
end

return ThisModule