--[[
version 0.2.0
@help 
	+ оптимизация рисования множества nodes
		+YES Node is like Entity
			-NO новый класс Node pathfinding, чтобы тут не описывать новый класс в components
				@help не получится, т.к. Entity и Node тесно связаны
			+ координаты Node привязаны к координатам Entity
			-?NO нужно множественное наследие
				@help категорически против, получится слишком запутанный код
					+ как в жизни: у ребенка(объекта) может быть только 2 родителя: мама(Класс) и папа(родительский Класс)
				@help памяти много будет жрать и немного скажется на производительности, также слишком запутанный код получится, который сложно будет отлаживать (смотри: PIL 3-е издание, глава 16.3)
			-?NO можно ввести новый класс GameObject, который только рисуется и не имеет колизии(сенсор), и он родитель Entity
			-+?YES вместо этого можно использовать Node в components как в Unity3d
				-+?NO вручную перенести всё нужное из Class Entity
					@help достоинства: нагляднее
					@help недостатки: медленно в написании кода и могут быть несовпадения, если забыть уровнять код(человеческий фактор)
					@help в комментариях нужно помечать откуда переписан метод, переменная, чтобы не было ошибок				
				@help недостатки: 
					- но тогда это уже будет Entity, а не Node
				+ рисуем только энтити, Node и Graph не рисуются
				+ если энтити не рисуется, то стрелочки тоже не рисуются, нужно рисовать стрелочки для таблицы connectedNodesClearMemory
		-YES сделать как в Light Class, с помощью Box2d, body is "sensor"
			-?NO Graph как объект, при попадании в камеру он рисуется
			- оптимизация
				- назначить маску колизий, чтобы сенсор ноды не срабатывал с ненужными телами
			- достоинства
				- быстрее, чем на Lua
				- можно прикрепить нод к физическому телу и не обновлять положение ноды каждый раз
			- недостатки
		-NO сделать свою систему AABB, благо готовые решения есть
			- достоинства
			- недостатки
				- медленнее чем на Box2d
@todo 
	- 
--]]

local ClassParent = require('code.classes.Entity')																								-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private
-- ...

-- variables static protected, only in Class
ThisModule._componentClass = ThisModule:newObjectsWeakTable()
ThisModule._componentClass['Graph.Node'] = require('code.classes.Graph.Node')

-- variables static public
-- ...

-- methods static private

-- example: setPosition(nil, y)
local function setPosition(self, x, y)
	if self.destroyed then self:destroyedError() end
	
	if type(x) == 'number' then self.componentParent.physics.body:setX(x); --[[self.x = x--]] end
	if type(y) == 'number' then self.componentParent.physics.body:setY(y); --[[self.y = y--]] end
end

local function getPosition(self)
	if self.destroyed then self:destroyedError() end
	
	return self.componentParent.physics.body:getPosition()
end

local function getX(self)
	if self.destroyed then self:destroyedError() end
	
	return self.componentParent.physics.body:getX()
end

local function getY(self)
	if self.destroyed then self:destroyedError() end
	
	return self.componentParent.physics.body:getY()
end

-- arg.drawMode = 'connections' or 'point' or 'normal'
-- arg.pathfinding = <boolean>
-- arg.drawModeConnections = 'arrow'(медленнее рисуется) or 'line'(быстрее рисуется)
function draw(self, arg)
	if self.component['Graph.Node'].destroyed then return nil end																				-- reserved; тут не нужен вызов ошибки
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	if not (arg.debug and debug:isOn() and debug.draw:isOn()) then return nil end
	
	arg.drawMode = arg.drawMode or 'normal'
	arg.drawModeConnections = arg.drawModeConnections or 'line'
	if arg.pathfinding == nil then arg.pathfinding = true end
	
	if arg.drawMode == 'connections' or arg.drawMode == 'normal' then 
		love.graphics.setColor(0, 255, 0, 255)
		love.graphics.setLineStyle('smooth')
		love.graphics.setLineWidth(1)
--		love.graphics.setLineJoin('none')
		
--		local i, i1 = 0, 0																										-- debug
		for k, node in pairs(self.component['Graph.Node'].connectedNodes) do
			if not node.destroyed then
				if arg.drawModeConnections == 'line' then love.graphics.line(self.component['Graph.Node']:getX(), self.component['Graph.Node']:getY(), node:getX(), node:getY()) end
				if arg.drawModeConnections == 'arrow' then self._modGraph:drawArrow(self.component['Graph.Node']:getX(), self.component['Graph.Node']:getY(), node:getX(), node:getY()) end
	--			i = i + 1																										-- debug
			end
		end
		for k, node in pairs(self.component['Graph.Node'].connectedNodesClearMemory) do
			if not node.destroyed then
				if arg.drawModeConnections == 'line' then love.graphics.line(node:getX(), node:getY(), self.component['Graph.Node']:getX(), self.component['Graph.Node']:getY()) end
				if arg.drawModeConnections == 'arrow' then self._modGraph:drawArrow(node:getX(), node:getY(), self.component['Graph.Node']:getX(), self.component['Graph.Node']:getY()) end
	--			i1 = i1 + 1																										-- debug
			end
		end		
		
		love.graphics.setLineWidth(1)
--		love.graphics.setLineJoin('miter')
	
--		print(i, i1)																										-- debug
	end

	if arg.drawMode == 'point' or arg.drawMode == 'normal' then 
		love.graphics.setColor(0, 255, 0, 255)
		if arg.pathfinding then
			if self.component['Graph.Node'].part then
				love.graphics.setColor(200, 150, 0, 255)																								-- коричневый
			end
--			if self.weakTable.parent then																												-- debug
--				love.graphics.setColor(200, 0, 0, 255)
--			end
			if self.component['Graph.Node'].debugPF.isConNode then
				love.graphics.setColor(0, 200, 200, 255)
			end
			if self.component['Graph.Node'].debugPF.isPopNode then
				love.graphics.setColor(0, 0, 200, 255)
			end		
		end
		love.graphics.circle('fill', self.component['Graph.Node']:getX(), self.component['Graph.Node']:getY(), 15, 10)
	end

end

-- methods static protected
-- ...

-- methods static public
function ThisModule:newObject(arg)																												-- rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- nonstatic variables, methods; init new variables from methods arguments
	local shape = love.physics.newCircleShape(0, 0, 15)
	local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
	fixture:setSensor(true)
	object.physics.body:setAwake(false)																											-- !!! обязательно, если bodyType="static"; это повышает производительность, т.к. тело само не "засыпает"
	object.shadows.on = false		

	------------------------------------------ components
	object.component = self:newObjectsWeakTable()
	object.component['Graph.Node'] = self._componentClass['Graph.Node']:newObject(arg)															-- read only!!!;
	object.component['Graph.Node'].componentParent = object																						-- read only!!!;
	
	local component = object.component['Graph.Node']

	component.g = 0
	component.h = 0
	component.f = 0
	component.weakTable = self:newObjectsWeakTable()
	component.weakTable.parent = false																											-- my parent node; for pathfinding
	
	component.part = false																														-- debug; participated in pathfinding	
	component.debugPF = {}																														-- обрабатывается в поиске пути
	component.debugPF.isPopNode = false
	component.debugPF.isConNode = false
	
	-- methods
	component.getPosition = getPosition
	component.getX = getX
	component.getY = getY
	component.setPosition = setPosition
	------------------------------------------
	
	return object																																-- be sure to return new object
end

function ThisModule:destroy()
	if self.destroyed then return false end
	
	self.component['Graph.Node']:destroy()
	ClassParent.destroy(self)
end

function ThisModule:draw(arg)
	if self.destroyed then return nil end																										-- reserved; тут не нужен вызов ошибки
	
	ClassParent.draw(self, arg)
	draw(self, arg)
end

return ThisModule																																-- reserved
