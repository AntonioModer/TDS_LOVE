--[[
version 0.0.1
@todo [
	@todo -+ инвентарь
	- кидать предметы
	- Item [
		-+ ложить в инвентарь
			+- алгоритм
				+ "убирать предмет из мира"
					-? сменить "маску" колизии, чтобы предмет вообще не сталкивался ни с чем
					-? сделать его статическим
					-? сделать сенсором
					+?YES body:setActive(false)
					-?NO переместить энтити в другое определенное место
				+ переместить предмет в инвентарь
				+?YES не удалять и не спавнить предмет
					* т.к. будут ошибки на ссылки предметов
				- сменить состояние предмета
			@todo -+ использовать item (ложить в руки), это не тоже самое, что "брать в руки"
				@todo + "пустые руки"
					-?YES список в инвентаре
					-? отдельная кнопка
				-?YES как в Teleglitch, с помощью UI List
					- действие с предметов в выделенной строчке
				-? состояние предмета
					-? "in hands in humanoid"
						-? или "taken" (взятый)
						-? или "используется"
						-? или "вид сверху"
						@todo +YES state machine изменит item (колизию, ...), присоединить joint-ом к игроку
						+?NO отрисовка, если он в другом месте
							+?NO игрок рисует его, т.к. энтити больше не рисуется самостоятельно
								+ используя его метод отрисовки
									+ новые аргументы: x, y
							+ другой спрайт рисовать
								+?YES в методе предмета определять какой рисовать
							+? другие координаты для рисования, т.к. он в другом месте
							+ угол как определить
								+?YES параметры добавить в метод отрисовки предмета
								-?NO или в методе определять как рисовать
			@todo -+ UI List
				+- смотри Class UI List
				+ один лист в игроке
				+- управление выделенным item в UI
					-?NO кнопками
					-? отдельный лист
						-?YES при нажатии 'enter' выскакивает новый UI List
							-?YES закрывать его после выбора действия над item
						-? новый UI List открывать из UI 'player inventory', как в worldEditor 'selected entity'
					+ выбросить
					- использовать
					- взять в руки
				- open/close button 'i'
		+ брать в руки
			+?NO если взял, то damping убирать, чтобы не влияло на движение игрока
		+- ложить на землю из инвентаря
	]
	@todo -+ таскание предметов, объектов [
		-+ с помощью рук
			-+ рефакторинг
			+?YES захват происходит в одной точке объекта двумя руками
			+ кнопка хватания
				+ player use: E
			-+ взятие объекта
				-+ проверка коллизии
			+ какой joint использовать?
				@todo -+ разобраться с помощью RUBE
				- лучше всего попробовать все виды joint
				-? Revolute
					-? for objects
					@help как-будто руками держит
						@help но тогда при повороте тела мышкой будет поворачиваться и объект
							@todo -? нужно тогда переделать поворот тела, он будет не заданием угла телу, а с помощью силы applyTorque() по направлению к вектору
							@todo -? или нельзя вращать тело
				-?NO Distance
					@help не совсем то, как будто палка с двух сторон привязана, и join имеет пружинные параметры, которые не нужны
						-? две руки = две палки = два joint
				-?NO Rope
				+?YES weld
					-? for objects
					-?YES for items
					@help по сравнению с Revolute: с weld-ом объектом легче манипулировать, легче поворачивать объект, более точно и не так бесит
			- как проверять колизию
				+NO точка хватания
				@todo - луч
				+ из положения мышки
		- как понять что начали таскать?
			-? рисовать протянутые руки
		- как понять в какой точке таскаем?
	]
	-+? перенести в модуль game
	-+ игрок - это единственная в мире сущность (типа душа), которая управляет энтити клавиатурой и мышкой
		-+ энтити должно существовать в мире отдельно
			-+ class Humanoid
		+ если в энтити есть move(), то игрок может передвигать ее
		+ если в энтити есть lookAt(), то игрок может смотреть ею
		- если в энтити есть rotate(angle, speed), то игрок может вращать ею
	+ camera attach mode
		+ если worldEditor отключен, то камера на игроке
	@todo -+ move
		-+?NO move: использовать вместо update() love.input; чтобы управление не зависело от update()
			@help сейчас не нужно, т.к. всеравно нужно в update() делать body:applyForce()
			@help но нужно для онлайн игры, т.к. оптимизируются нажатия на кнопки, т.е. не нужно каждый раз проверять нажатие кнопки	
	+ module or class
		+ в модуле создать ссылку на обьект класса
]
--]]

local thisModule = {}
thisModule.entity = false 																														-- require('code.classes.Entity.Humanoid'):newObject({x=1900, y=1400}) or false

--[[
version 0.0.1
@help 
	+ INPUT
@todo 
	- 
--]]
thisModule.input = {}

-- variables static public #########################################################################
thisModule.dragHands = {}
thisModule.dragHands.catchLenght = {}
thisModule.dragHands.catchLenght.max = 30
thisModule.dragHands.catchLenght.min = 15
thisModule.dragHands.joint = false
thisModule.dragHands.is = false                                                                                                              -- |readonly!!! out|
thisModule.dragHands.catchedFixture = false                                                                                                  -- <false> <love2d fixture>
thisModule.dragHands.filterNames = {                                                                                                         -- какие энтити можно таскать
"Entity.Item"
, "Entity.Test2"
, "Entity.Door.DoorWall"
, "Entity.Humanoid"
, "Entity.TestCircle"
, "Entity.Crate"
, "Entity.Barrel"
--, "Entity.BottleBig"
}

-- visibility zone ---------------------------------------------------------------------------------------------
thisModule.visZone = {}
thisModule.visZone.canvas = {}
thisModule.visZone.canvas.screen = love.graphics.newCanvas(config.window.width/1, config.window.height/1, 'normal')
--thisModule.shadows.canvas.screen:setFilter('nearest', 'nearest')

thisModule.visZone.light = require("code.classes.Entity.Light"):newObject()
thisModule.visZone.on = config.controls.player.visZone

-- UI ===================================================================================================
--[[ @todo 
	- расположение
		+?NO справа на половину экрана
	- show item information
		+?YES new UI Text
			- всегда открыто
		-?YES при выделении в UIListInventory видна инфа
	
--]]
thisModule.pickupItemToInventory = {}
thisModule.pickupItemToInventory.UIListInventory = require("code.classes.UI.List"):newObject({name='player inventory', x=20, y=100, allowMoveItemsByHoldKey=true})--x=config.window.width-150, y=config.window.height-460})
thisModule.pickupItemToInventory.UIListInventory.itemsMaxLengthInSymbols = 20
thisModule.pickupItemToInventory.UIListInventory.showMaxItems = 30
thisModule.pickupItemToInventory.UIListInventory:insertItem({name="<empty hands>"})

function thisModule.pickupItemToInventory.UIListInventory:onItemInputSelectionChanged(beforeItemNumber, afterItemNumber)
--	print(os.clock(), "onItemInputSelectionChanged()", beforeItemNumber, afterItemNumber, thisModule.dragHands.is)
	
	if thisModule.dragHands.is then return false end
	
	local entityItem = thisModule.pickupItemToInventory.UIListInventory:getCurrentSelectedEntityItem()
	if entityItem then
		thisModule.entity._bodyPart.hands.entityIn = entityItem
	else
		thisModule.entity._bodyPart.hands.entityIn = false
	end
	
	if thisModule.entity._bodyPart.hands.entityIn then
		if thisModule.entity._bodyPart.hands.entityIn.useStop then
			thisModule.entity._bodyPart.hands.entityIn:useStop(2, thisModule.entity)
			thisModule.entity._bodyPart.hands.entityIn:useStop(4, thisModule.entity)
		end
	end
	
	thisModule.pickupItemToInventory.UIListItemInfo:clear()
	if thisModule.pickupItemToInventory.UIListInventory:getCurrentSelectedEntityItem() then
		for i, v in ipairs(thisModule.pickupItemToInventory.UIListInventory:getCurrentSelectedEntityItem().info) do
			thisModule.pickupItemToInventory.UIListItemInfo:insertItem({name=v()})
		end
	end
end
function thisModule.pickupItemToInventory.UIListInventory:onMoveItem(beforeItemNumber, afterItemNumber)
	-- переписываем порядок, источник UI List
	thisModule.entity.inventory.items = {}
	for i, v in ipairs(thisModule.pickupItemToInventory.UIListInventory.items) do
		if type(v.userData) == 'object' then
			thisModule.entity.inventory.items[i] = v.userData
		elseif v.name == '<empty hands>' then
			thisModule.entity.inventory.items[i] = '<empty hands>'
		end
	end
	
--			print(item.name, thisModule.pickupItemToInventory.UIListInventory:getItemSelectedNumber())
	-- UI, пересчитываем инвентарь
	thisModule.pickupItemToInventory.UIListInventory:clear()
	for i, v in ipairs(thisModule.entity.inventory.items) do
		if type(v) == 'object' then
			thisModule.pickupItemToInventory.UIListInventory:insertItem({name=v.entityName..' '..tostring(v), userData = v, func=thisModule.pickupItemToInventory.UIListInventory.funcInteractWithItem})
		elseif v == '<empty hands>' then
			thisModule.pickupItemToInventory.UIListInventory:insertItem({name="<empty hands>"})
		end
	end
	
--	print(os.clock(), "onMoveItem()")
end
function thisModule.pickupItemToInventory.UIListInventory.funcInteractWithItem(item)
	thisModule.pickupItemToInventory.UIListItemInteract:setActive()
end
function thisModule.pickupItemToInventory.UIListInventory:getCurrentSelectedEntityItem()
	local entity
	if self.items[self:getItemSelectedNumber()] then
		entity = self.items[self:getItemSelectedNumber()].userData
	end
	
	return entity or false
end

--[[ @todo 
	- расположение
		-? вылазит напротив UIList.item, чтобы было понятнее
		-? по середине экрана
		-? всегда открыто
--]]
thisModule.pickupItemToInventory.UIListItemInteract = require("code.classes.UI.List"):newObject({name='item interact', x=20, y=config.window.height-150})--x=config.window.width-150, y=config.window.height-460-63})
thisModule.pickupItemToInventory.UIListItemInteract.itemsMaxLengthInSymbols = 20
thisModule.pickupItemToInventory.UIListItemInteract.showMaxItems = 3
function thisModule.pickupItemToInventory.UIListItemInteract.funcInteractWithItem(item)
--	thisModule.pickupItemToInventory.UIListItemInteract:close()
	thisModule.pickupItemToInventory.UIListInventory:setActive()
	
	local entity
	if thisModule.pickupItemToInventory.UIListInventory.items[thisModule.pickupItemToInventory.UIListInventory:getItemSelectedNumber()] then
		entity = thisModule.pickupItemToInventory.UIListInventory.items[thisModule.pickupItemToInventory.UIListInventory:getItemSelectedNumber()].userData
	else
		return false
	end
	if item.name == '<drop>' then
		if #thisModule.entity.inventory.items > 0 then
			thisModule.entity.inventory:removeItem(entity)
			
			thisModule.entity._bodyPart.hands.entityIn = false
			entity.state:setState('onFloor', thisModule.entity)			
--			entity:setPosition(thisModule.entity:getPosition())
--			entity.physics.body:setActive(true)
			
--			print(item.name, thisModule.pickupItemToInventory.UIListInventory:getItemSelectedNumber())
			-- UI
			-- @todo 3 - вынести общий drop код в функцию 
			
			-- переписываем порядок, источник UI List
			thisModule.entity.inventory.items = {}
			for i, v in ipairs(thisModule.pickupItemToInventory.UIListInventory.items) do
				if type(v.userData) == 'object' then
					thisModule.entity.inventory.items[i] = v.userData
				elseif v.name == '<empty hands>' then
					thisModule.entity.inventory.items[i] = '<empty hands>'
				end
			end			
			
			thisModule.pickupItemToInventory.UIListInventory:clear()
			for i, v in ipairs(thisModule.entity.inventory.items) do
				if type(v) == 'object' then
					thisModule.pickupItemToInventory.UIListInventory:insertItem({name=v.entityName..' '..tostring(v), userData = v, func=thisModule.pickupItemToInventory.UIListInventory.funcInteractWithItem})
				elseif v == '<empty hands>' then
					thisModule.pickupItemToInventory.UIListInventory:insertItem({name="<empty hands>"})
				end
			end				
			
			if thisModule.entity.state.ro_stateCurrentName == 'aiming' then
				thisModule.entity.state:setState('idle', thisModule.entity, thisModule.entity)
			end
			
--			print('dropFromInventory', entity)
		end
	elseif item.name == '<use>' then
		
	end
	
end
thisModule.pickupItemToInventory.UIListItemInteract:insertItem({name='<use>', func=thisModule.pickupItemToInventory.UIListItemInteract.funcInteractWithItem})
thisModule.pickupItemToInventory.UIListItemInteract:insertItem({name='<drop>', func=thisModule.pickupItemToInventory.UIListItemInteract.funcInteractWithItem})
thisModule.pickupItemToInventory.UIListItemInteract:insertItem({name='<clear magazine>', func=thisModule.pickupItemToInventory.UIListItemInteract.funcInteractWithItem})      -- @todo - for Firearms
thisModule.pickupItemToInventory.UIListItemInteract:insertItem({name='<reload>', func=thisModule.pickupItemToInventory.UIListItemInteract.funcInteractWithItem})      -- @todo - for Firearms
--thisModule.pickupItemToInventory.UIListItemInteract:close()

thisModule.pickupItemToInventory.UIListItemInfo = require("code.classes.UI.List"):newObject({name='item info', x=20, y=config.window.height-85})--x=config.window.width-150, y=20})
thisModule.pickupItemToInventory.UIListItemInfo.itemsMaxLengthInSymbols = 20
thisModule.pickupItemToInventory.UIListItemInfo.showMaxItems = 5

-- methods static private ##########################################################################


-- methods static protected ########################################################################

function thisModule.dragHands._funcFilter(fixture)
	local pass = false
	local object = fixture:getBody():getUserData()
	if object and object._TABLETYPE == "object" and (not object.destroyed) and object ~= thisModule.entity and fixture:isSensor() == false then
		for i, v in ipairs(thisModule.dragHands.filterNames) do
			if string.find(object:getClassName(), v) then
				pass = true
			end
		end
	end
	
	return pass
end

function thisModule.dragHands._catch(fixturesList, takePoint)
	if fixturesList and not thisModule.entity._bodyPart.hands.entityIn then
		if not fixturesList[1]:getBody():isDestroyed() and not fixturesList[1]:isSensor() then
			local dragEntity = fixturesList[1]:getBody():getUserData()
			if dragEntity and (not dragEntity.destroyed) then
				local angleToPoint = {}
				angleToPoint.x = takePoint.x
				angleToPoint.y = takePoint.y
				if string.sub(dragEntity:getClassName(), 8, 11) == 'Item' then
					angleToPoint.x = dragEntity:getX()
					angleToPoint.y =  dragEntity:getY()
					
					local angleToItem = math.radToBDeg(math.angle(thisModule.entity:getX(), thisModule.entity:getY(), angleToPoint.x, angleToPoint.y))
--					local angleFromItem = math.radToBDeg(math.angle(angleToPoint.x, angleToPoint.y, thisModule.entity:getX(), thisModule.entity:getY()))
					
					thisModule.entity:setAngle(angleToItem)
					
					-- main
					-- @todo + переделать joint из-за изменений в LOVE 0.10.2
						-- @todo + проблема с referenceAngle, он сука меняется
--					thisModule.dragHands.joint = love.physics.newWeldJoint( thisModule.entity.physics.body, dragEntity.physics.body, angleToPoint.x, angleToPoint.y, false)     -- 0.10.1
					
--					local angleBefore = math.radToBDeg(dragEntity.physics.body:getAngle())
--					print(dragEntity.physics.body:getAngle())
					-- @todo -+ @bug arg x1, x2 not local ошибка в документации в вики, 
						-- @todo + рассказать разработчикам
						-- @todo + исправить тут с помощью костыля Body:getWorldPoint()
					local localX1, localY1 = dragEntity.physics.body:getLocalPoint(dragEntity:getX(), dragEntity:getY())
					localX1, localY1 = dragEntity.physics.body:getWorldPoint(localX1, localY1)                                                 -- bugCrutch; костыль под правильный API, пока не исправлен @bug; после исправления @bug, убрать эту строчку
					thisModule.dragHands.joint = love.physics.newWeldJoint(thisModule.entity.physics.body, dragEntity.physics.body
						, localX1, localY1
						, localX1, localY1
						, false
						, dragEntity.physics.body:getAngle() - thisModule.entity.physics.body:getAngle()--[[math.bDegToRad(angleBefore)--]])    -- 0.10.2
					thisModule.dragHands.is = true
					thisModule.entity._bodyPart.hands.entityIn = dragEntity
--					print(thisModule.dragHands.joint:getAnchors())
--					dragEntity.physics.body:setAngle(angleBefore)
--					print(dragEntity.physics.body:getAngle(), thisModule.dragHands.joint:getReferenceAngle(), angleToItem)
					
--					thisModule.dragHands.joint:setDampingRatio(1000)
--					thisModule.dragHands.joint:setFrequency(1)
--					print(thisModule.dragHands.joint:getDampingRatio())
					
					--[[ test
					local ax, ay = thisModule.entity.physics.body:getWorldVector(1, 0)
					thisModule.dragHands.joint = love.physics.newPrismaticJoint(thisModule.entity.physics.body, dragEntity.physics.body, takePoint.x, takePoint.y, ax, ay, false )
					thisModule.dragHands.joint:setLimits(-10, 10)
					thisModule.dragHands.joint:setLimitsEnabled(true)
					thisModule.dragHands.joint:setMaxMotorForce(200)
					thisModule.dragHands.joint:setMotorSpeed(500)
					thisModule.dragHands.joint:setMotorEnabled(true)
					dragEntity.physics.body:setLinearDamping(0)
					dragEntity.physics.body:setAngularDamping(0)						
					--]]
					
					--[[ test
					thisModule.dragHands.joint = love.physics.newMotorJoint(thisModule.entity.physics.body, dragEntity.physics.body)
					--]]
					
					thisModule.dragHands.catchedFixture = fixturesList[1]
--					thisModule.dragHands.catchedFixture:setCategory(2)
--					thisModule.dragHands.catchedFixture:setMask(4)
--					dragEntity.z = 5
--					dragEntity.shadows.directional.z = 2
					
					dragEntity.state:setState('dragged', thisModule.entity)
				elseif dragEntity:getClassName() == "Entity.Door.DoorWall" then
					-- @todo + для дверей другой Joint, не Weld, чтобы можно было легко закрывать двери
					-- @todo -? переделать joint из-за изменений в LOVE 0.10.2
					thisModule.dragHands.joint = love.physics.newRopeJoint( thisModule.entity.physics.body, dragEntity.physics.body, thisModule.entity:getX(), thisModule.entity:getY(), angleToPoint.x, angleToPoint.y, 40, true )
					thisModule.dragHands.is = true
					thisModule.entity._bodyPart.hands.entityIn = dragEntity
				else
					-- @todo + переделать joint из-за изменений в LOVE 0.10.2
--					thisModule.dragHands.joint = love.physics.newWeldJoint( thisModule.entity.physics.body, dragEntity.physics.body, angleToPoint.x, angleToPoint.y, true )
					
					-- @todo + исправить тут с помощью костыля Body:getWorldPoint()
					local localX1, localY1 = dragEntity.physics.body:getLocalPoint(dragEntity:getX(), dragEntity:getY())
					localX1, localY1 = dragEntity.physics.body:getWorldPoint(localX1, localY1)                                                 -- bugCrutch; костыль под правильный API, пока не исправлен @bug; после исправления @bug, убрать эту строчку
					thisModule.dragHands.joint = love.physics.newWeldJoint(thisModule.entity.physics.body, dragEntity.physics.body
						, localX1, localY1
						, localX1, localY1
						, false
						, dragEntity.physics.body:getAngle() - thisModule.entity.physics.body:getAngle()--[[math.bDegToRad(angleBefore)--]])    -- 0.10.2
					thisModule.dragHands.is = true
					thisModule.entity._bodyPart.hands.entityIn = dragEntity
				end
				
--				print('take')
			end
		end
	end	
end

-- @todo - если item уже в dragHands
function thisModule.pickupItemToInventory._pickup(fixturesList)
	if fixturesList then
		if not fixturesList[1]:getBody():isDestroyed() then
			local item = fixturesList[1]:getBody():getUserData()
			if item and (not item.destroyed)then
--				fixturesList[1]:setGroupIndex(-1)
--				fixturesList[1]:setSensor(true)
--				fixturesList[1]:getBody():setType('static')
				item.state:setState('taken', thisModule.entity)
				
				thisModule.entity.inventory:addItem(item)
				
				-- UI				
				thisModule.pickupItemToInventory.UIListInventory:clear()
				for i, v in ipairs(thisModule.entity.inventory.items) do
					if type(v) == 'object' then
						thisModule.pickupItemToInventory.UIListInventory:insertItem({name=v.entityName..' '..tostring(v), userData = v, func=thisModule.pickupItemToInventory.UIListInventory.funcInteractWithItem})
					elseif v == '<empty hands>' then
						thisModule.pickupItemToInventory.UIListInventory:insertItem({name="<empty hands>"})
					end
				end
				
--				print('pickupItemToInventory', item)
			end
		end
	end
	
end

function thisModule.pickupItemToInventory._funcFilter(fixture)
	local pass = false
	local object = fixture:getBody():getUserData()
	if object._TABLETYPE == "object" and (not object.destroyed) and object ~= thisModule.entity and fixture:isSensor() == false and string.sub(object:getClassName(), 8, 11) == 'Item' then
		pass = true
	end
	
	return pass
end

-- methods static public ##################################################################################

thisModule.dragHands.input = {}
function thisModule.dragHands.input:keyPressed(key)
	if key == config.controls.player.use then
		-- таскание предметов
		--[[ 
			@todo 
				@todo -? вынести в метод dragHands:update
				@todo 2 - вынести в Humanoid class
				+ фильт колизии расширить, не только для "Entity.Test2"
					@todo -?NO с помощью параметра в Entity.draggable.byHands = <boolean>
						@help это не корректно, т.к. энтити не должна знать что должен делать игрок
		--]]
		--[[
			body:getWorldPoint(), body:getWorldVector(), body:getLocalPoint(), body:getLocalVector()
			@todo -? ограничить угол хватания, чтобы только перед лицом, а не сзади или сбоку
				@help не очень удобно, лучше не делать
			@todo -+?YES хватать(закреплять) Item только в руки(в определенной точке), а не в любой точке
				@help это упрощает действия, можно сразу кинуть предмет в кого-то или куда-то
				- проблема: если перемещать предмет большой в маленьком пространстве, то может быть неадекватное поведение физики и он может "прыгнуть"
					+ нужно повернуться к предмету и уже тогда брать его в руки
						+? к центру предмета
						+? к точке хватания предмета
				-+ хватать
					-+Item
						+?NO в точке хватания
							@help так легче его передвигать
						-?YES по ценрту предмета
							@help так легче его кидать
					-+ other Entity
						+YES в точке хватания
							@help так легче его передвигать
					@todo + разное хватание
						+ для Item
						+ для других Entity
			если хотябы одна рука не занята
				если дистанция от центра игрока до мышки меньше максимальной и больше минимальной и если есть предмет под мышкой, то
					хватаем его в руки
				иначе
					есть колизия с лучом, то
						хватаем его в руки
			иначе
				отпускаем предмет
		--]]
		if not thisModule.dragHands.joint then
			local takePoint = math.vector(camera:toWorld(love.mouse.getPosition()))  -- mouse point
			local fixturesList = require("code.physics").collision.circle(takePoint.x, takePoint.y, 1, false, thisModule.dragHands._funcFilter, false)
			local dist = math.dist(thisModule.entity:getX(), thisModule.entity:getY(), takePoint.x, takePoint.y)
			if dist <= thisModule.dragHands.catchLenght.max and dist >= thisModule.dragHands.catchLenght.min then
				thisModule.dragHands._catch(fixturesList, takePoint)
			else
				takePoint.x, takePoint.y = thisModule.entity.physics.body:getWorldPoint(thisModule.dragHands.catchLenght.max, 0)   -- simple
				fixturesList = require("code.physics").collision.circle(takePoint.x, takePoint.y, 1, false, thisModule.dragHands._funcFilter, false)  -- @todo - вместо круга луч
				thisModule.dragHands._catch(fixturesList, takePoint)
			end
		else
--			print('drop')
			thisModule.dragHands.joint:destroy()
			thisModule.dragHands.joint = false
			thisModule.dragHands.is = false
			thisModule.entity._bodyPart.hands.entityIn = false
			if thisModule.dragHands.catchedFixture and (not thisModule.dragHands.catchedFixture:isDestroyed()) and (not thisModule.dragHands.catchedFixture:getBody():isDestroyed())
			  and thisModule.dragHands.catchedFixture:getBody():getUserData() then
				local dragEntity = thisModule.dragHands.catchedFixture:getBody():getUserData()
				if (not dragEntity.destroyed) and string.sub(dragEntity:getClassName(), 8, 11) == 'Item' then
--					thisModule.dragHands.catchedFixture:setCategory(3)
--					thisModule.dragHands.catchedFixture:setMask(2)
--					thisModule.dragHands.catchedFixture:getBody():getUserData().z = 0
--					thisModule.dragHands.catchedFixture:getBody():getUserData().shadows.directional.z = 0
					
					dragEntity.state:setState('onFloor', thisModule.entity, {position = {dragEntity:getPosition()}})
					
					thisModule.dragHands.catchedFixture = false
				end
			end
		end
	end
end

function thisModule.input:keyPressed(key)
	if not thisModule.entity then return false end
	if thisModule.entity and thisModule.entity.destroyed then return false end
	if require("code.worldEditor"):isOn() then return false end
	
--	print('keyPressed', key)
	thisModule.dragHands.input:keyPressed(key)
	
	------------------------------------------------
	if key == config.controls.player.inventory.dropItem then
		if thisModule.pickupItemToInventory.UIListInventory:isActive() then
			local entity
			if thisModule.pickupItemToInventory.UIListInventory.items[thisModule.pickupItemToInventory.UIListInventory:getItemSelectedNumber()] then
				entity = thisModule.pickupItemToInventory.UIListInventory.items[thisModule.pickupItemToInventory.UIListInventory:getItemSelectedNumber()].userData
			else
				return false
			end
			
			if entity then
				thisModule.entity.inventory:removeItem(entity)
				thisModule.pickupItemToInventory.UIListInventory:removeItem(thisModule.pickupItemToInventory.UIListInventory:getItemSelectedNumber())
				
				-- переписываем порядок, источник UI List
				thisModule.entity.inventory.items = {}
				for i, v in ipairs(thisModule.pickupItemToInventory.UIListInventory.items) do
					if type(v.userData) == 'object' then
						thisModule.entity.inventory.items[i] = v.userData
					elseif v.name == '<empty hands>' then
						thisModule.entity.inventory.items[i] = '<empty hands>'
					end
				end
				
	--			print(item.name, thisModule.pickupItemToInventory.UIListInventory:getItemSelectedNumber())
				-- UI, пересчитываем инвентарь
				thisModule.pickupItemToInventory.UIListInventory:clear()
				for i, v in ipairs(thisModule.entity.inventory.items) do
					if type(v) == 'object' then
						thisModule.pickupItemToInventory.UIListInventory:insertItem({name=v.entityName..' '..tostring(v), userData = v, func=thisModule.pickupItemToInventory.UIListInventory.funcInteractWithItem})
					elseif v == '<empty hands>' then
						thisModule.pickupItemToInventory.UIListInventory:insertItem({name="<empty hands>"})
					end
				end
				
				thisModule.entity._bodyPart.hands.entityIn = false
				entity.state:setState('onFloor', thisModule.entity)
--				entity:setPosition(thisModule.entity:getPosition())
--				entity.physics.body:setActive(true)
				
				if thisModule.entity.state.ro_stateCurrentName == 'aiming' then
					thisModule.entity.state:setState('idle', thisModule.entity, thisModule.entity)
				end
				
--				print('dropFromInventory', entity)
			end
		end
	elseif key == config.controls.player.inventory.pickupItem then
		local takePoint = math.vector(camera:toWorld(love.mouse.getPosition()))  -- mouse point
		local fixturesList = require("code.physics").collision.circle(takePoint.x, takePoint.y, 1, false, thisModule.pickupItemToInventory._funcFilter, false)
		local dist = math.dist(thisModule.entity:getX(), thisModule.entity:getY(), takePoint.x, takePoint.y)
		if dist <= thisModule.dragHands.catchLenght.max and dist >= thisModule.dragHands.catchLenght.min then
			thisModule.pickupItemToInventory._pickup(fixturesList)
		else
			--[[
			takePoint.x, takePoint.y = thisModule.entity.physics.body:getWorldPoint(thisModule.dragHands.catchLenght.max, 0)   -- simple
			fixturesList = require("code.physics").collision.circle(takePoint.x, takePoint.y, 1, false, thisModule.pickupItemToInventory._funcFilter, false)  -- @todo - вместо круга луч
			--]]
			
			-- big circle
			takePoint.x, takePoint.y = thisModule.entity:getPosition()
			fixturesList = require("code.physics").collision.circle(takePoint.x, takePoint.y, thisModule.dragHands.catchLenght.max, false, thisModule.pickupItemToInventory._funcFilter, false)
			thisModule.pickupItemToInventory._pickup(fixturesList)
		end
	elseif key == config.controls.player.itemUse[3] then
		if thisModule.entity._bodyPart.hands.entityIn then
			if thisModule.entity._bodyPart.hands.entityIn.useStart then
				thisModule.entity._bodyPart.hands.entityIn:useStart(3, thisModule.entity)
			end
		end
	elseif key == config.controls.player.itemUse[4] then
		if thisModule.entity._bodyPart.hands.entityIn then
			-- reloading
			-- @todo + move to Item:useStart()
			--[[ @todo 1 -+ во время перезарядки оружия
					-+ перезарядку прекратить 
						-?NO если выкинул (вроде и не нужно, т.к. при смене Итема в Листе прекращаем перезарядку)
							- оружие
							- ammo
						+ если выбрал другой Итем в инвентаре
						-? если тягаешь что-то
					-? нельзя стрелять из оружия
			--]]
			if thisModule.entity._bodyPart.hands.entityIn._statesAllTable.reloading and not thisModule.entity._bodyPart.hands.entityIn.magazine:isFull() then
				local ammoTab = {}
				for i=1, #thisModule.pickupItemToInventory.UIListInventory.items do
					local itemEntity = thisModule.pickupItemToInventory.UIListInventory.items[i].userData
					if itemEntity and string.find(itemEntity:getClassName(), '.Ammo') then
						table.insert(ammoTab, itemEntity)
					end
				end				
				thisModule.entity._bodyPart.hands.entityIn:useStart(4, thisModule.entity, {ammo=ammoTab, ammoInThisUIList=thisModule.pickupItemToInventory.UIListInventory, ammoInThisEntityInventory = thisModule.entity.inventory})
			end
		end
	elseif key == config.controls.player.move.forward then
		thisModule.movementVector.y = thisModule.movementVector.y-1
		if thisModule.movementVector.y > 1 or thisModule.movementVector.y < -1 then
			thisModule.movementVector.y = math.sign(thisModule.movementVector.y)
		end
	elseif key == config.controls.player.move.backward then
		thisModule.movementVector.y = thisModule.movementVector.y+1
		if thisModule.movementVector.y > 1 or thisModule.movementVector.y < -1 then
			thisModule.movementVector.y = math.sign(thisModule.movementVector.y)
		end
	elseif key == config.controls.player.move.left then
		thisModule.movementVector.x = thisModule.movementVector.x-1
		if thisModule.movementVector.x > 1 or thisModule.movementVector.x < -1 then
			thisModule.movementVector.x = math.sign(thisModule.movementVector.x)
		end
	elseif key == config.controls.player.move.right then
		thisModule.movementVector.x = thisModule.movementVector.x+1
		if thisModule.movementVector.x > 1 or thisModule.movementVector.x < -1 then
			thisModule.movementVector.x = math.sign(thisModule.movementVector.x)
		end
	end
end

function thisModule.input:keyReleased(key)
	if not thisModule.entity then return end
	if thisModule.entity and thisModule.entity.destroyed then return false end
	if require("code.worldEditor"):isOn() then return false end
	
	if key == config.controls.player.move.forward 
	  or key == config.controls.player.move.backward
	  or key == config.controls.player.move.left
	  or key == config.controls.player.move.right
	  then
		if thisModule.entity.state.ro_stateCurrentName ~= 'aiming' then
			thisModule.entity.state:setState('idle', thisModule.entity, thisModule.entity)
		end
	end
	if key == config.controls.player.move.forward then
		thisModule.movementVector.y = thisModule.movementVector.y+1
		if thisModule.movementVector.y > 1 or thisModule.movementVector.y < -1 then
			thisModule.movementVector.y = math.sign(thisModule.movementVector.y)
		end
	elseif key == config.controls.player.move.backward then
		thisModule.movementVector.y = thisModule.movementVector.y-1
		if thisModule.movementVector.y > 1 or thisModule.movementVector.y < -1 then
			thisModule.movementVector.y = math.sign(thisModule.movementVector.y)
		end
	elseif key == config.controls.player.move.left then
		thisModule.movementVector.x = thisModule.movementVector.x+1
		if thisModule.movementVector.x > 1 or thisModule.movementVector.x < -1 then
			thisModule.movementVector.x = math.sign(thisModule.movementVector.x)
		end
	elseif key == config.controls.player.move.right then
		thisModule.movementVector.x = thisModule.movementVector.x-1
		if thisModule.movementVector.x > 1 or thisModule.movementVector.x < -1 then
			thisModule.movementVector.x = math.sign(thisModule.movementVector.x)
		end
	end
--	print('keyReleased', key == config.controls.player.move.backward)
end

function thisModule.input:mousePressed(x, y, button)
	if not thisModule.entity then return end
	
--	if button == 2 then
--		-- возврат угла тела в прямое положение
--		math.pendulumInit(thisModule.entity, 'bodyMoveAnimation', 1, true)
--		thisModule.entity._bodyMoveAnimation.angle = 0
		
--	end
	
	if button == config.controls.player.itemUse[2] then
		
		if game.player.dragHands.is == false then
			if thisModule.entity._bodyPart.hands.entityIn and string.find(thisModule.entity._bodyPart.hands.entityIn:getClassName(), 'Entity.Item.Weapon')then
				thisModule.entity.state:setState('aiming', thisModule.entity, {pose='weapon.oneInTwoHands'})
			else
				thisModule.entity.state:setState('aiming', thisModule.entity, {pose='idle'})
			end
		else
			thisModule.entity.state:setState('aiming', thisModule.entity, {pose='idle'})
		end
	end
	
	-- item start use
	for i, v in ipairs(config.controls.player.itemUse) do
		if type(v) == 'number' and button == v then
			if thisModule.entity._bodyPart.hands.entityIn then
				if thisModule.entity._bodyPart.hands.entityIn.useStart then
					thisModule.entity._bodyPart.hands.entityIn:useStart(i, thisModule.entity)
				end
			end
		end		
	end
end

function thisModule.input:mouseReleased(x, y, button)
	if not thisModule.entity then return end
	
	if button == config.controls.player.itemUse[2] --[[and game.player.dragHands.is == false--]] then
		thisModule.entity.state:setState('idle', thisModule.entity, thisModule.entity)
	end
	
	-- item stop use
	for i, v in ipairs(config.controls.player.itemUse) do
		if type(v) == 'number' and button == v then
			if thisModule.entity._bodyPart.hands.entityIn then
				if thisModule.entity._bodyPart.hands.entityIn.useStop then
					thisModule.entity._bodyPart.hands.entityIn:useStop(i, thisModule.entity)
				end
			end
		end		
	end	
end

-- movement ========================================================================================
thisModule.movement = require('code.player.movement')
thisModule.movementVector = math.vector()
--==================================================================================================

function thisModule:update(dt)
	if not self.entity then return false end
	if self.entity and self.entity.destroyed then return false end
	if require("code.worldEditor"):isOn() then return false end
	
	self.movement:update(self, 'teleglitch')
	
	love.audio.setPosition(self.entity:getX(), self.entity:getY(), 0)
	
	-- @todo +? не определять постоянно тут, а с помощью List:onItemSelected()
--	local entityItem = thisModule.pickupItemToInventory.UIListInventory:getCurrentSelectedEntityItem()
--	if entityItem then
--		self.entity._bodyPart.hands.entityIn = entityItem
--	else
--		self.entity._bodyPart.hands.entityIn = false
--	end
	
	thisModule.pickupItemToInventory.UIListItemInfo:clear()
	if thisModule.pickupItemToInventory.UIListInventory:getCurrentSelectedEntityItem() then
		for i, v in ipairs(thisModule.pickupItemToInventory.UIListInventory:getCurrentSelectedEntityItem().info) do
			thisModule.pickupItemToInventory.UIListItemInfo:insertItem({name=v()})
		end
	end
	
	--[[ tests -------------------------------------------------------------------
	local rayEnd = {}
	rayEnd.x, rayEnd.y = self.entity.physics.body:getWorldPoints(100,0)
	
	require("code.physics").collision.worldRayCast.ray.x1 = self.entity:getX()
	require("code.physics").collision.worldRayCast.ray.y1 = self.entity:getY()
	require("code.physics").collision.worldRayCast.ray.x2 = rayEnd.x
	require("code.physics").collision.worldRayCast.ray.y2 = rayEnd.y
	--]]
--	print(thisModule.entity.inventory.items[1])
end

function thisModule:draw()
	if not self.entity then return end
	
	-- tests
--	local lv = math.vector()
--	local mWX, mWY = camera:toWorld(love.mouse.getPosition())
--	local fpx, fpy = self.entity.physics.body:getWorldPoint(self.entity._moveForceLocalPosition:unpack())
--	lv.x = mWX - fpx
--	lv.y = mWY - fpy
--	love.graphics.setColor(200, 0, 0, 255)
--	love.graphics.line(fpx, fpy, fpx+lv.x, fpy+lv.y)
	
	-- thisModule.dragHands cath point
--	local px, py = self.entity.physics.body:getWorldPoint(thisModule.dragHands.catchLenght, 0)
--	love.graphics.setColor(255, 255, 255, 255)
--	love.graphics.circle('fill', px, py, 2)	
--	love.graphics.setColor(0, 0, 0, 255)
--	love.graphics.circle('fill', px, py, 1)

	-- visibility zone -------------------------------------------------------------------
	--[[
		@todo
			- размер текстуры "света" больше, чтобы без больших пикселей
			-? параметр in Entity allowVisibilityZone
	--]]
	if require("code.worldEditor"):isOn() or (not thisModule.visZone.on) then return false end
	
	love.graphics.setCanvas(thisModule.visZone.canvas.screen)
	love.graphics.clear(0, 0, 0, 255)
	love.graphics.setCanvas()
	
	if thisModule.visZone.light.destroyed then
		thisModule.visZone.light = require("code.classes.Entity.Light"):newObject()
		thisModule.visZone.light:setRadius(config.window.height)
		thisModule.visZone.light.on = false
		thisModule.visZone.light.shadows.mobility = 'dynamic'
		thisModule.visZone.light.imageLight = false
		thisModule.visZone.light.allowToSave = false
	end

	local light = thisModule.visZone.light
	
	if self.entity and (not self.entity.destroyed) then
		light:setPosition(self.entity:getPosition())
	end
	
	if (not light.destroyed) then
		local canvasResult = require('code.graphics.light').shadows:compute(light, true)
		local canvasShSize = require('code.graphics.light').shadows.canvas.main:getHeight()
		
		love.graphics.setCanvas(thisModule.visZone.canvas.screen)
		do camera:attach()
			love.graphics.setBlendMode('add')
			if canvasResult == false then
				light:draw({onlyRays = true, source = true})
			else
				love.graphics.setColor(light.color[1], light.color[2], light.color[3], light.brightness*(255/100))
				canvasResult:setFilter('linear', 'linear')
				love.graphics.draw(canvasResult, light:getX(), light:getY(), 0, light.radius/(canvasShSize/2), light.radius/(canvasShSize/2), canvasShSize/2, canvasShSize/2)
				canvasResult:setFilter('nearest', 'nearest')
			end
		camera:detach() end
		love.graphics.setCanvas()
		
		-- result
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setBlendMode('multiply')
	--	love.graphics.draw(self.canvas.screen, 0, 0, 0, 2, 2)
		love.graphics.draw(thisModule.visZone.canvas.screen)
		love.graphics.setBlendMode('alpha')		
	end
end

return thisModule