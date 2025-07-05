--[[
@version 0.0.1
@todo 
	@todo 1 -+ изображения
		-+ поза
			-+ держать оружие
				-+ руки отдельно от торса
				-? каждая рука отдельно
				+ отрисовка рук всегда ниже торса
				+ изображение торса не изменяется, торс просто повернут с использованием спрайта
					+ тогда нужно перерисовать текущий торс: убрать плечи
	- legs
		- like physics base of movement
		- покадровая анимация
	- анимация
		- ног
		-? использовать костную анимацию
			-? анимация с помощью physics joints
		- голова
			- при движении без прицеливания назад/вперед голова чуть назад/вперед отклоняется
--]]

local ClassParent = require('code.classes.Entity')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end


-- variables private ###############################################################################
-- ...

-- variables protected, only in Class
ThisModule._bodyPart = {}                                                                                                                       -- @todo -? rename to _bodyParts
ThisModule._bodyPart.head = {}
ThisModule._bodyPart.head.image = ThisModule._modGraph.images.humanoidHead
ThisModule._bodyPart.body = {}
ThisModule._bodyPart.body.image = ThisModule._modGraph.images.humanoidBody
ThisModule._bodyPart.body.back = {}
ThisModule._bodyPart.legs = {}
ThisModule._bodyPart.hands = {}
ThisModule._bodyPart.hands.entityIn = false
ThisModule._bodyPart.hands.right = {}
ThisModule._bodyPart.hands.right.inventory = {}
ThisModule._bodyPart.hands.left = {}
ThisModule._bodyPart.hands.left.inventory = {}
ThisModule.inventory = {}
ThisModule.inventory.items = ThisModule.newObjectsWeakTable()
ThisModule._damage.on = true

-- variables public ##################################################################################
ThisModule.z = 6
--ThisModule.image = ThisModule._modGraph.images.humanoid
ThisModule.moveSpeed = 1500                                                                                                                     -- |readonly!!!|

ThisModule._statesAllTable = {
	idle = {
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
--			print(os.clock(), 'state idle')
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt._bodyPart.body.image = ThisModule._modGraph.images.humanoidBody
			selfEnt._bodyPart.hands.image = ThisModule._modGraph.images.humanoid.hands.idle
			selfEnt._bodyMoveAnimation.angle = 0
			selfEnt._bodyMoveAnimation.pause = false
		end
	}
	, run = {
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
--			print(os.clock(), 'state run')
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt._bodyPart.body.image = ThisModule._modGraph.images.humanoidBody
			selfEnt._bodyPart.hands.image = ThisModule._modGraph.images.humanoid.hands.run
			selfEnt._bodyMoveAnimation.pause = false
		end
	}	
	, shooting = {                                                                                                                              -- стрельба
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
--			print(os.clock(), 'state shooting')
			local selfEnt = selfObjectState.userData.selfEnt
		end
	}
	, aiming = {                                                                                                                                -- прицеливание
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
--			print(os.clock(), 'state aiming')
			local selfEnt = selfObjectState.userData.selfEnt
			
			if other then
				if other.pose == 'weapon.oneInTwoHands' then
					selfEnt._bodyPart.body.image = ThisModule._modGraph.images.humanoid.body.weapon.oneInTwoHands
					selfEnt._bodyPart.hands.image = ThisModule._modGraph.images.humanoid.hands.weapon.oneInTwoHands
					selfEnt._bodyMoveAnimation.angle = 0.785398
				elseif other.pose == 'idle' then
					selfEnt._bodyPart.body.image = ThisModule._modGraph.images.humanoidBody
					selfEnt._bodyPart.hands.image = ThisModule._modGraph.images.humanoid.hands.idle
					selfEnt._bodyMoveAnimation.angle = 0					
				end
			end
			selfEnt._bodyMoveAnimation.pause = true
		end
	}
	, reloading = {                                                                                                                                -- прицеливание
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
--			print(os.clock(), 'state reloading')
			
		end		
	}
}

-- methods private ###################################################################################
-- ...

-- methods protected #################################################################################
-- ...

-- methods public ####################################################################################

--[[
	* inherited method
	* @arg arg <table> <nil> (default <nil>) = [ 
		* @arg arg.x <number> <nil> (default 0)
		* @arg arg.y <number> <nil> (default 0)
		* @arg arg.angle <number> <nil> = 0 ... 360 (babylons-degrees) (default 0)
		* @arg arg.entityName <string> <nil> (default className)
	]
	* @return <object>
--]]
function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	arg.mobility = "dynamic"
	local object = ClassParent.newObject(self, arg)
	
	do -- variables protected
		object._moveForceDir = math.vector(1,0)                                                                                                 -- для move(), направление прикладываемой силы
		object._moveForceLocalPosition = math.vector(20, 0)
		object._moveForceLocalPositionCurrent = object._moveForceLocalPosition                                                                  -- для смены move() coordinatesSystem global, local
		object._moveSpeedCurrent = self.moveSpeed
		
		object._turnToForceDir = math.vector(1,0)
		object._setMoveforceLocalPositionCurrentAtCenter = false                                                                                -- точку толкания в moveUpdate() ставить в центр тела
		object._moveWithoutControllerRotation = false
		
		math.pendulumInit(object, 'bodyMoveAnimation', 1, true)
		object._bodyMoveAnimation = {}
		object._bodyMoveAnimation.angle = 0
		object._bodyMoveAnimation.pause = false
	end
	
	do -- physics
	--	object.physics.body:setMassData(0, 0, 1, 1)
		object.physics.body:setMass(80)
--		object.physics.body:setInertia(1000000)
--		print(object.physics.body:getInertia())
		object.physics.body:setLinearDamping(10)
		object.physics.body:setAngularDamping(10)	
--		object.physics.body:setBullet(true)
--		print(object.physics.body:isBullet())
--		object.physics.body:setSleepingAllowed(false)
		object.physics.body:setAwake(true)
	--	object.physics.body:setFixedRotation(true)
		
		local shape
		if self.image then
			shape = love.physics.newCircleShape(0, 0, (math.max(self.image:getWidth(), self.image:getHeight())-16)/2)
		else
			shape = love.physics.newCircleShape(0, 0, 24)
		end
		local fixture = love.physics.newFixture(object.physics.body, shape, 1)                                                                  -- shape копируется при создании fixture
		
--		fixture:setRestitution()
--		fixture:setFriction(0)
--		print(fixture:getFriction())
--		print(fixture:getRestitution())
--		print(fixture:getDensity())
		
		fixture:setCategory(2)
--		fixture:setMask(3)
--		fixture:setGroupIndex(2)
	end

	do -- draw
		-- drawBuffer shape
		local shape
		if self.image then
			shape = love.physics.newRectangleShape(0, 0, self.image:getWidth(), self.image:getHeight(), 0)
		else
			shape = love.physics.newRectangleShape(0, 0, 64, 64, 0)
		end		
		local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
		fixture:setSensor(true)
		fixture:setUserData({typeDraw = true})
		
		object.shadows.on = false
		object.shadows.directional.z = 2
	end
	
	object.inventory = {}
	object.inventory.addItem = ThisModule.inventory.addItem
	object.inventory.removeItem = ThisModule.inventory.removeItem
	object.inventory.items = ThisModule.newObjectsWeakTable()
	object.inventory.items[1] = '<empty hands>'
	
	object._bodyPart = {}                                                                                                                       -- @todo -? rename to _bodyParts
	object._bodyPart.head = {}
	object._bodyPart.head.image = ThisModule._modGraph.images.humanoidHead
	object._bodyPart.body = {}
	object._bodyPart.body.image = ThisModule._modGraph.images.humanoidBody
	object._bodyPart.body.back = {}
	object._bodyPart.legs = {}
	object._bodyPart.hands = {}
	object._bodyPart.hands.image = ThisModule._modGraph.images.humanoid.hands.idle
	object._bodyPart.hands.entityIn = false
	object._bodyPart.hands.right = {}
	object._bodyPart.hands.right.inventory = {}
	object._bodyPart.hands.left = {}
	object._bodyPart.hands.left.inventory = {}
	
	object.state = require('code.logic.state').new()
	object.state.userData = {selfEnt=object}
	object.state:initStates(self._statesAllTable)
	object.state:setState('idle', object)
	
	return object
end

function ThisModule:throwItemInHands(power)
	if self.destroyed then self:destroyedError() end
	if (not game.player.dragHands.is) or (not self._bodyPart.hands.entityIn) then return false end
	
	-- @todo 1 -? переместить dragHands из player в Humanoid
	local thisModule = game.player
	thisModule.dragHands.joint:destroy()
	thisModule.dragHands.joint = false
	thisModule.dragHands.is = false
--	thisModule.entity._bodyPart.hands.entityIn = false
	if thisModule.dragHands.catchedFixture and (not thisModule.dragHands.catchedFixture:isDestroyed()) and (not thisModule.dragHands.catchedFixture:getBody():isDestroyed())
	  and thisModule.dragHands.catchedFixture:getBody():getUserData() then
		local dragEntity = thisModule.dragHands.catchedFixture:getBody():getUserData()
		if (not dragEntity.destroyed) and string.sub(dragEntity:getClassName(), 8, 11) == 'Item' then
--			thisModule.dragHands.catchedFixture:setCategory(3)
--			thisModule.dragHands.catchedFixture:setMask(2)
			
--			thisModule.dragHands.catchedFixture:getBody():getUserData().z = 0
--			thisModule.dragHands.catchedFixture:getBody():getUserData().shadows.directional.z = 0
			thisModule.dragHands.catchedFixture = false
		end
	end
	
	-- Projectile test
	-- NO v1, удобно кидать в стороны быстро мышкой
--	local x, y = self.physics.body:getWorldPoint(32, 0)
--	local x2, y2 = camera:toWorld(love.mouse.getPosition())
--	local vec = math.vector(math.dist(x, y, x2, y2), 0):rotateInplace(math.angle(x, y, x2, y2))
	
	-- v2, кидать строго прямо
	local x, y = self.physics.body:getPosition()
	local x2, y2 = camera:toWorld(love.mouse.getPosition())	
	local vec = math.vector(math.dist(x, y, x2, y2), 0):rotateInplace(self.physics.body:getAngle())
	
	local x, y = self.physics.body:getWorldPoint(32+5, 0)
	local projectile = self._bodyPart.hands.entityIn
	
--	local force = vec:normalizeInplace() * 200                             -- v1, stable force
	
	-- v2, force to mouse
	local force = vec/2
	if force:len() > 200 then
		force = force:normalizeInplace() * 200
		print('max')
	end
	
	projectile.physics.body:applyLinearImpulse(force.x, force.y)		

	
--	ThisModule.inventory:removeItem(self._bodyPart.hands.entityIn)
	self._bodyPart.hands.entityIn = false
	
	--[[ отдача от стрельбы
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
	--]]
end

function ThisModule:damage(value)
	if ClassParent.damage(self, value) then self:destroy() end
end

function ThisModule.inventory:addItem(item)
	if self.destroyed then self:destroyedError() end
	
	table.insert(self.items, item)
	
--	print('humanoid.inventory:addItem()', item)
end

function ThisModule.inventory:removeItem(item)
	if self.destroyed then self:destroyedError() end
	
	for i, v in ipairs(self.items) do
		if v == item then
			table.remove(self.items, i)
			break
		end
	end
end

function ThisModule:lookAt(x, y)
	if self.destroyed then self:destroyedError() end
	
	
end
--[[
	* плавный физический поворот тела к точке
	* @arg x, y <number> (global coordinates)
	@todo 
		@todo -?NO с помощью physics Joint
			* joint будет поворачивать тело к себе, точка крепления не по середине тела, не нужно обновлять
			* не подходит, т.к. joint будет менять координаты тела, а это недопустимо
			-? love.physics.newMouseJoint
--]]
function ThisModule:setTurnTo(x, y)
	
end

--[[
	* плавный физический поворот тела к точке
	* @arg x, y <number> (global coordinates)
	@todo 
		@todo 1 - рефакторинг, справка
			- зависимость от ФПС, если низкий ФПС, то начинается дерганье очень сильное, недопустимо
		-? вынести параметры и применять методы, как в moveUpdate()
--]]
function ThisModule:turnToUpdate(x, y)
	if self.destroyed then self:destroyedError() end
	
	----[[ with physics applyTorque()
	
	local v1 = math.vector(1,0):rotated(self.physics.body:getAngle())                   -- теперешнее направление
	local v2 = math.vector(1,0):rotated(math.angle(self:getX(), self:getY(), x, y))     -- направление конечного вектора
	v2:normalizeInplace()
	
	local diffA = math.radToBDeg(v1:angleTo(v2))
--	print(diffA)

	--[=[
		+ дерганье по сторонам; возникает погрешность в точности поворота
			+ чем ближе к конечному углу (зависит от разности), тем меньше сила поворота
		* при ходьбе, если точка толкания не по середине тела, то тело поворачивается и этот алгоритм не может повернуть тело на конкретный угол, т.к. силы действуют друг на друга
			+ точку толкания ставить в центр тела, когда это алгоритм работает
		* если на тело идет посторонняя сила, то этот алгоритм не может повернуть тело на конкретный угол
	--]=]
	
	-- для moveUpdate()
	self._setMoveforceLocalPositionCurrentAtCenter = true                                                           -- точку толкания в moveUpdate() ставить в центр тела
	self._moveWithoutControllerRotation = true
	

	local force
	local forceArg = (100*1)--/(love.timer.getDelta()*100)
--	print(forceArg)
	if forceArg > 1000--/(love.timer.getDelta()*100) 
	  then
		self.physics.body:setAngle(v2:angleTo())
		
		return nil
	end
	----[[
	-- с одной стороны	
	if diffA > 0 and diffA < 180 then
		force = self.physics.body:getAngularDamping()*forceArg*diffA
--		if diffA < 5 and force > 20 then force = 20 end
		self.physics.body:applyTorque(force)
--		print('+', force)
	elseif diffA > 180 and diffA < 360 then
		-- с другой стороны
		diffA = 360-diffA
		force = self.physics.body:getAngularDamping()*forceArg*diffA
--		if diffA > -5 and force < -20 then force = -20 end
		self.physics.body:applyTorque(-force)
--		print('-', force)
	end
	--]]
	
	-- NO
--	if math.abs(self.physics.body:getAngularVelocity()) > 1 then
--		self.physics.body:setAngularVelocity(1*math.sign(self.physics.body:getAngularVelocity()))
--	end
	
--	print(self.physics.body:getAngularVelocity())
--	print(self.physics.body:getAngle())
	
--	if diffA == 0 or diffA == 180 then
--		self.physics.body:setAngularVelocity(0)
--	end
	--]]
	
	-- simple, without physics applyTorque()
--	self:setAngle(math.radToBDeg(math.angle(self:getX(),self:getY(), x, y)))
end

--[[
@help [
	* @arg arg <table> = [
		* @arg coordinatesSystem <string> = 'global', 'local' (global 'default')
		* @arg direction <math.vector> <string> = 'north' or 'south' or 'west' or 'east' (coordinatesSystem == 'global'); or 'left' or 'right' or 'forward' or 'backward' (coordinatesSystem == 'local')
		* @arg withoutControllerRotation <boolean> <nil>
			* только для coordinatesSystem == 'global'
			* контроллер нужен в случае, если применение силы к телу не по его середине, то появляется проблема: если применять силу ровно противоположную повоту тела, то тело не разворачивается; контроллер конролирует это
			* попроще: если сила применяется в лоб НПС, то этот контроллер поворачивает НПС, чтобы он не шел задом
	]
	* @example self.entity:move({coordinatesSystem='global', direction=math.vector(1,0)})
	* @example self.entity:move({coordinatesSystem='local', direction='forward'})
	* скорость в любом направлении одинакова и зависит от object.moveSpeed
	* сила применяется в coordinatesSystem
		* global: не по середине тела, а по _moveForceLocalPosition, чтобы изменение угла движения было сглаженым с заносами, а не резким
		* local: по середине тела
]
@todo [
	-? двигаться к точке
	-?NO новый метод moveAlways:start(), один раз его вызвали и тело движется постоянно
	@todo 1.1 -+?NO вынести в таблицу move
		+?NO ThisModule.move:update()
			@help проблема с self, нельзя получить ссылку объекта
		-? как вызывать функцию?
			-?YES move._call = function; -> move()
				@help плюсы: удобный АПИ
				@help минусы: страдает оптимизация
					@help не критично, можно пренебреч
			-?NO move:func()
			-?NO move:move()
	-? вид движения: физическое, по навмешу
	-? новый метод moveUpdate()
	@todo 1.2 - direction
		-? _moveForceDir вынести из move(), сделать переменной, которая постоянно указывает направление движения
			-? arg.direction не обязательный аргумент
			-? новый метод setMoveDirection()
		-? случай, когда arg.direction вводится неверно
	@todo 1 -+ рефакторинг, справка
	-? ввести вид ходьбы: "стрэйф" и "ходьба вперед"
	@todo -+ разобраться с body:getWorldPoint(), body:getWorldVector(), body:getLocalPoint(), body:getLocalVector()
		-+ рисовать эти точки
	+INFO!!! зависимость от require("code.physics").skip.skipMax
		@todo 3 -+ изучить как влияет
			@help если skipMax > 0, то сложно определить максимальную getLinearDamping() для её конроля
				-? возможно здесь влияет также dt
				+INFO!!! require("code.physics").skip.skipMax = 0, эту оптимизацию отключаем; сейчас нужно работать с кодом с таким значением
	@todo -+ изучить тригонометрию, векторы
]
--]]
function ThisModule:moveUpdate(arg)
	if self.destroyed then self:destroyedError() end
	
	if (not arg.coordinatesSystem) or arg.coordinatesSystem == 'global' then
		----[[ version5 работает, лучшее, но не доконца верно
		-- прямое диагональное (45 градусов) изменение верно
		-- но непрямая диагональная (>45> градусов) скорость падает, проверял на догоняющем НПС и он меня догонял
		-- потому что если ввод с помощью love.keyboard.isDown(), то задержка dt тормозит ввод и applyForce() применяется меньше?
		-- нет, не поэтому, а потому что если вектор ввода будет всегда только 8-направленный, хоть и нормализованный, то диагональная скорость будет применяться 0.7, а не 1 ?
		-- НПС догонял при петлянии, т.к. он двигался по более прямой линии, т.е. он находится на более короткой дистации и он меньше тормозил, а я более извилисто шел, короче этот способ идеальный
		-- а дебужное кольцо скорости изменяется в радиусе при поворотах
		-- -?NO изменить applyForce() в исходниках Box2d
		-- -? посмотреть applyForce() в исходниках Box2d
		-- -+? http://www.iforce2d.net/b2dtut/constant-speed
		
		
		if self._setMoveforceLocalPositionCurrentAtCenter then
			self._moveForceLocalPositionCurrent = math.vector()
		else
			self._moveForceLocalPositionCurrent = self._moveForceLocalPosition
		end
		
		if arg.direction then
			if type(arg.direction) == 'string' then
				if arg.direction == 'west' then
					self._moveForceDir.x = -1
					self._moveForceDir.y = 0
				elseif arg.direction == 'east' then
					self._moveForceDir.x = 1
					self._moveForceDir.y = 0
				elseif arg.direction == 'north' then
					self._moveForceDir.x = 0
					self._moveForceDir.y = -1
				elseif arg.direction == 'south' then
					self._moveForceDir.x = 0
					self._moveForceDir.y = 1
				end
			elseif type(arg.direction) == 'vector' then
				self._moveForceDir.x = arg.direction.x
				self._moveForceDir.y = arg.direction.y
			end
		end
		
		----[=[ Controller rotation in 180
		-- + если вектор текущего движения противоположен вектору текущего направления тела
		--  +YES то нужно пемного повернуть тело с applyTorque()
		
		if (not arg.withoutControllerRotation) and not self._moveWithoutControllerRotation then
--			print("with ControllerRotation")
			
			local v1 = math.vector(1,0):rotated(self.physics.body:getAngle())
			
			-- если на тело идет посторонняя сила, то возможны ошибки при большом корректирующем повороте, при малом я не заметил
			-- проверять, действует ли посторонняя сила, нет, т.к. ошибка также будет: нельзя будет развернуться при постронней силе
			-- вообще такая ситуация не влияет на что-либо, она не критическая
			local v2 = math.vector()
			v2.x, v2.y = self.physics.body:getLinearVelocity()
			v2:normalizeInplace()
			
			-- так нету погрешности, но тогда нужно переделать изменение _moveForceDir если используется direction как строка(west, east, ...), только хер знает как, вроде не получается
			-- либо убрать direction как строка(west, east, ...) и применять только входящий вектор, не поможет т.к. вектор разный будет полюбому
--			v2 = self._moveForceDir
			
--			local v3
			-- v1 - это направление игрока
			-- v2 - это направление чего?
			-- v3 - это направление applyForce()
		--	print(math.radToBDeg(v1:angleTo(v2)))
			local diffA = math.radToBDeg(v1:angleTo(v2))
			
			
			-- с одной стороны
			if diffA > 180-1 and diffA < 180 then
--				print('+', diffA)
				self.physics.body:applyTorque(self.physics.body:getAngularDamping()*1000)  -- корректирующий поворот
			end
			-- с другой стороны
			if diffA < 180+1 and diffA >= 180 then
--				print('-', diffA)
				self.physics.body:applyTorque(self.physics.body:getAngularDamping()*-1000)  -- корректирующий поворот
			end
		else
--			print("without ControllerRotation")
		end
		--]=]
		
		self._moveForceDir:normalizeInplace()
		local force = self._moveForceDir * self._moveSpeedCurrent
		local fpx, fpy =  self.physics.body:getWorldPoint(self._moveForceLocalPositionCurrent:unpack())
		self.physics.body:applyForce(force.x, force.y, fpx, fpy)
--		print(force.x, force.y)
		if self.state.ro_stateCurrentName ~= 'aiming' then
			if self._moveSpeedCurrent > self.moveSpeed then
				if self.state.ro_stateCurrentName ~= 'run' then
					self.state:setState('run', self)
				end
			else
				if self.state.ro_stateCurrentName ~= 'idle' then
					self.state:setState('idle', self)
				end
			end
		end
		--]]
	elseif arg.coordinatesSystem == 'local' then
		-- @help тут не нужен "Controller rotation in 180", т.к. он нужен только для глобальных координат
		
		self._moveForceLocalPositionCurrent = math.vector(0, 0)
		
		if type(arg.direction) == 'string' then
			if arg.direction == 'left' then
				self._moveForceDir.x, self._moveForceDir.y = self.physics.body:getWorldVector(0, -1)
			elseif arg.direction == 'right' then
				self._moveForceDir.x, self._moveForceDir.y = self.physics.body:getWorldVector(0, 1)
			elseif arg.direction == 'forward' then
				self._moveForceDir.x, self._moveForceDir.y = self.physics.body:getWorldVector(1, 0)
			elseif arg.direction == 'backward' then
				self._moveForceDir.x, self._moveForceDir.y = self.physics.body:getWorldVector(-1, 0)
			end
		elseif type(arg.direction) == 'vector' then
			self._moveForceDir.x, self._moveForceDir.y = self.physics.body:getWorldVector(arg.direction.x, arg.direction.y)
		end
		
		self._moveForceDir:normalizeInplace()
		local force = self._moveForceDir * self._moveSpeedCurrent
		local fpx, fpy =  self.physics.body:getWorldPoint(self._moveForceLocalPositionCurrent:unpack())
		self.physics.body:applyForce(force.x, force.y, fpx, fpy)
	
	end
	
	
	if self._bodyMoveAnimation.pause == false then
		-- @todo + зависимость от self.physics.body:getLinearVelocity()
		local v2 = math.vector()
		v2.x, v2.y = self.physics.body:getLinearVelocity()
--		print(v2:len())
		self._bodyMoveAnimation.angle = math.rad(math.pendulumStep(self, 'bodyMoveAnimation', 0, 45, 100*love.timer.getDelta()*(v2:len()/2)))
		
	end
end

--[[
@help [
	+ not done !!!
	+ arguments table:
		+ coordinatesSystem = <string> (global(default), local)
		+ direction = <vector> or <string> (global: north, south, west, east; local: left, right, forward, backward)
]
@todo [
	- 
]
--]]
function ThisModule:setMoveDirection()
	
end

--[[
@help [
	+ for test
]
@todo [
	- 
]
--]]
function ThisModule:update()
	if self.destroyed then self:destroyedError() end
	
--	print('test')
end


function ThisModule:draw(arg)
	if self.destroyed then self:destroyedError() end
	
	do
		local beforeDrawable = self.drawable                      -- не рисуем лишний раз image
		self.drawable = false
		
		ClassParent.draw(self, arg)
		
		self.drawable = beforeDrawable
	end
	
	if (not arg.debug) and self.drawable then
		
		local shadowsDirectionalCoordsAdd  = {}                                                                                                                                       -- simpleShadowCoords additional
		shadowsDirectionalCoordsAdd.x, shadowsDirectionalCoordsAdd.y = 0, 0
		if arg.likeShadow then
			love.graphics.setColor(0, 0, 0, 255)
		elseif arg.shadowsDirectional and self.shadows.directional.on then                                                                                                            -- not done !!!
			love.graphics.setColor(0, 0, 0, 100)
			shadowsDirectionalCoordsAdd.x, shadowsDirectionalCoordsAdd.y = 3+(self.shadows.directional.z*2), 3+(self.shadows.directional.z*2)
		else
			love.graphics.setColor(255, 255, 255, 255)
		end
		
		-- hands
		love.graphics.draw(self._bodyPart.hands.image, 
		  self.physics.body:getX()+shadowsDirectionalCoordsAdd.x, self.physics.body:getY()+shadowsDirectionalCoordsAdd.y, 
		  self.physics.body:getAngle()+self._bodyMoveAnimation.angle, 
		  scale or 1, scale or 1, 
		  self._bodyPart.hands.image:getWidth()/2, self._bodyPart.hands.image:getHeight()/2)
		
		love.graphics.setColor(255, 255, 255, 255)
		
		----[[ item
		if (not game.player.dragHands.is) and self._bodyPart.hands.entityIn and not self._bodyPart.hands.entityIn.destroyed then
--			local fpx, fpy = self.physics.body:getWorldPoint(20, 0)
--			--print(fpx, fpy, self.physics.body:getAngle())
--			self._bodyPart.hands.entityIn:draw({x=fpx, y=fpy, angle=self.physics.body:getAngle()-0.1, originX = 0, originY = self._bodyPart.hands.entityIn.image:getHeight()/2, shadowsDirectional=arg.shadowsDirectional})
			
			local fpx, fpy
			if string.sub(self._bodyPart.hands.entityIn:getClassName(), 1, 18) == 'Entity.Item.Weapon' then                                                                          -- Entity.Item.Weapon
				-- поза "держать оружие"
				fpx, fpy = self.physics.body:getWorldPoint(0, 0)
				local angle = self._bodyPart.hands.entityIn.sprite.transform.angle
--				if self._bodyPart.hands.entityIn.state.ro_stateCurrentName == 'taken' then
					angle = angle + self._bodyMoveAnimation.angle
--				end
				self._bodyPart.hands.entityIn:draw({x=fpx, y=fpy, angle=self.physics.body:getAngle()+angle, shadowsDirectional=arg.shadowsDirectional})
			else
				-- поза "держать"
				fpx, fpy = self.physics.body:getWorldPoint(20, 0)
--				local angle = self._bodyPart.hands.entityIn.sprite.transform.angle
--				angle = angle + self._bodyMoveAnimation.angle
				self._bodyPart.hands.entityIn:draw({x=fpx, y=fpy, angle=self.physics.body:getAngle(), shadowsDirectional=arg.shadowsDirectional})
			end
		end
		--]]
		
		local shadowsDirectionalCoordsAdd  = {}                                                                                                                                       -- simpleShadowCoords additional
		shadowsDirectionalCoordsAdd.x, shadowsDirectionalCoordsAdd.y = 0, 0
		if arg.likeShadow then
			love.graphics.setColor(0, 0, 0, 255)
		elseif arg.shadowsDirectional and self.shadows.directional.on then                                                                                                            -- not done !!!
			love.graphics.setColor(0, 0, 0, 100)
			shadowsDirectionalCoordsAdd.x, shadowsDirectionalCoordsAdd.y = 3+(self.shadows.directional.z*2), 3+(self.shadows.directional.z*2)
		else
			love.graphics.setColor(255, 255, 255, 255)
		end
				
		-- body
		love.graphics.draw(self._bodyPart.body.image, 
		  self.physics.body:getX()+shadowsDirectionalCoordsAdd.x, self.physics.body:getY()+shadowsDirectionalCoordsAdd.y, 
		  self.physics.body:getAngle()+self._bodyMoveAnimation.angle, 
		  scale or 1, scale or 1, 
		  self._bodyPart.body.image:getWidth()/2, self._bodyPart.body.image:getHeight()/2)
		
--		love.graphics.setColor(255, 255, 255, 100)
		-- head
		love.graphics.draw(self._bodyPart.head.image, self.physics.body:getX()+shadowsDirectionalCoordsAdd.x, self.physics.body:getY()+shadowsDirectionalCoordsAdd.y, self.physics.body:getAngle(), scale or 1, scale or 1, self._bodyPart.head.image:getWidth()/2, self._bodyPart.head.image:getHeight()/2)		
		
	end
	
	-- @todo -+ убрать это в AI debug draw
	if arg.debug and (not arg.likeShadow) and debug:isOn() and debug.draw:isOn() and self.modPhys.debug:isOn() and self.modPhys.debug.draw:isOn() and self.debug.on and self.debug.draw.on then
		-- debug
	--	local lx2, ly2 = self.physics.body:getWorldVector(10, 0)
	--	love.graphics.setColor(0, 200, 0, 255)
	--	love.graphics.line(self:getX(), self:getY(), self:getX()+lx2, self:getY()+ly2)
		
		----[[ LinearVelocity ------------------------------------------------------
		local lv = math.vector()
		lv.x, lv.y = self.physics.body:getLinearVelocity()
		local fpx, fpy = self.physics.body:getWorldPoint(self._moveForceLocalPositionCurrent:unpack())
		
		local v = self._moveForceDir * 50
		
		love.graphics.line(fpx, fpy, fpx+v.x, fpy+v.y)
		
		-- b2Body:getLinearVelocity()
	--	local limit = (self._moveSpeedCurrent/self.physics.body:getLinearDamping()/2)
	----	print(limit)
	--	if lv:len() > limit then
	--		love.graphics.setColor(200, 0, 0, 255)
	--	else
			love.graphics.setColor(0, 0, 200, 255)
	--	end
		love.graphics.line(fpx, fpy, fpx+lv.x, fpy+lv.y)
		-- если скорость всегда одинаковая, при любом направлении, то круг не будет изменяться в радиусе, это будет видно
	--	love.graphics.circle("line", fpx, fpy, lv:len())  -- draw like circle
		
		--]]-------------------------------------------------------------------
	end


	--[[ test
	love.graphics.setColor(200, 0, 0, 255)
	local v1 = math.vector(self.physics.body:getWorldPoint(100, 0))
	love.graphics.line(self:getX(), self:getY(), v1.x, v1.y)
	
--	love.graphics.setColor(200, 0, 0, 255)
	local v2 = math.vector(self.physics.body:getWorldVector(100, 0))
--	love.graphics.line(self:getX(), self:getY(), self:getX()+v2.x, self:getY()+v2.y)
	
	print(v1, v2)
	----------
--	love.graphics.setColor(0, 200, 0, 255)
	local v3 = math.vector(self.physics.body:getLocalPoint(v1.x, v1.y))
--	love.graphics.line(self:getX(), self:getY(), self:getX()+v3.x, self:getY()+v3.y)
--	print(v1, v3)
	
--	love.graphics.setColor(200, 0, 0, 255)
	local v4 = math.vector(self.physics.body:getLocalVector(v2.x, v2.y))
--	love.graphics.line(self:getX(), self:getY(), self:getX()+v4.x, self:getY()+v4.y)
	
--	print(v3, v4)	
	--]]
end

return ThisModule
