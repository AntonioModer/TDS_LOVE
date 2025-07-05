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
ThisModule.image = false--ThisModule._modGraph.images.items.weapons.crossbow.onFloor
ThisModule.sprite = ThisModule._modGraph.sprites.items.weapons.crossbow.onFloor

ThisModule.fire = {}
ThisModule.fire.rate = {}
ThisModule.fire.rate.value = 60                                                                                                                -- |readonly!!!|; скорострельность, технических выстрелов в мин (без учета перезарядки); -1, 1 ... ; default = 120; -1 = infinite; реальный max = 600, если больше, то не хватает точности из-за низкого обновления таймера, т.е. процессор не успевает так быстро обновить таймер
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
ThisModule.fire.recoil.physics.angular.is = true
ThisModule.fire.recoil.physics.angular.power = 3000
ThisModule.fire.force = 100

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
ThisModule.projectile.type = 'Arrow'                                                                                                       -- @todo + учитывать при перезарядке

ThisModule._statesAllTable = {
	onFloor = {
--		, image = ThisModule._modGraph.images.items.weapons.test.onFloor
		sprite = ThisModule._modGraph.sprites.items.weapons.crossbow.onFloor
		, funcAction = ClassParent._statesAllTable.onFloor.funcAction
	}
	, taken = {
--		, image = ThisModule._modGraph.images.items.weapons.test.taken
		sprite = ThisModule._modGraph.sprites.items.weapons.crossbow.taken
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
		sprite = ThisModule._modGraph.sprites.items.weapons.crossbow.aiming
		, funcCondition = ClassParent._statesAllTable.aiming.funcCondition
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.sprite = selfState.sprite
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state aiming')
			selfEnt.timer:clear()
		end
	}
	, reloading = {                                                                                                                                -- прицеливание
		sprite = ThisModule._modGraph.sprites.items.weapons.crossbow.taken
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.sprite = selfState.sprite
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			print(os.clock(), 'state reloading')
			
			selfEnt.timer:clear()
			selfEnt.fire.rate.timer.handle = selfEnt.timer:after(2, function() selfEnt:funcReload(other) end)
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
	object.magazine.size.max = 30
	object.magazine.size.current = 30
	object.magazine.isFull = ThisModule.magazine.isFull
	
	object.info = {}
	object.info[1] = function () return 'magazine size = ' .. object.magazine.size.current end
	
	object.state:setState('onFloor', object)
	
	return object
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
end

return ThisModule