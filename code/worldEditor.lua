--[[
version 0.1.10
@todo 
	- physics editor [
		-?NO нужен полный редактор физики на LOVE2d
			@help нужен не полный		
		-?NO сторонний редактор	
			-? Box2D Helper (https://love2d.org/forums/viewtopic.php?f=5&t=81976)
			-? RUBE https://www.iforce2d.net/rube/
				@help https://www.iforce2d.net/rube/?panel=features
			-? Inkscape как shape editor
			@help плюсы	
				- не нужно кодить велосипеды
			@help минусы	
				- нельзя видеть как это будет в игре
				- нельзя редактировать во время игры
		- object physics editor 
			@help плюсы
				- многообразие
				- удобно
			@help минусы
				- сложно делать			
			-? отдельная от игры программа на LOVE2d
			- body
			- fixture
				- add
				- remove
				- move
				- types
					- circle
					- rectangle	
					- polygon
						- vertices
							- add
							- remove
							- move
	]
	-? при выключении режима редакторав игре, не закрывать листы, чтобы были видно параметры выделенного объекта в реальном времени
	-? перенести модуль в world
	- справка
	-+ список(UI List) Entity, которые в мире: List of entities in world [
		- сортировка по имени
			- код писать в Class UI-List
		+ строчка в UI-меню WorldEditor для переключения нового меню
		+ ...
			+ при создании entity, добавлять в UI-список
			+ при удалении entity, удалять из UI-списка
				+ как определить удаляемую строчку?
					-?NO по названию ссылки таблицы энтити в названии строчки
						@help нужно перебирать каждую строчку, это не есть хорошо
					-+?NO внести новую переменную для строчки: userData
						@help нужно перебирать каждую строчку, это не есть хорошо
					+?YES хранить номер NOстроки(YESили ссылка на таблицу строки) в энтити
						+ при удалении индексы строчек меняются, поэтому нужно менять код в List Class
						@help не нужно перебирать строки
						@help зависимость энтити от UI-List, это не есть хорошо
			@help чтобы создать entity сначала нужно создать worldEditor.ui, иначе ни-как
		+ как показывать имя?
			+ и индивидуальное имя для каждой entity в ней: entity.entityName = 'my name'
				+ стардартное имя - это название класса
				TODO1.3 + при смене имени энтити, сменить имя строки в данном UI-List
			+ и в скобках показывать имя ссылки на таблицу entity (для удобства дебага)
				- убрать текст "table: ", т.к. это мешает
		+ выделять при нажатии кнопкой в списке
		+ тестирование
	]
	- блокировка объекта на:
		- передвижение
		- вращение
	-? перетаскивать из проводника Энтити в игру
		- Энтити - это .lua файл
		+ функции перетаскивания файлов есть в LOVE 0.10.0
	-+ выделение объектов [
		+ режимы (modes)
			+ move
			+ rotate
			+ переключение
				+ клавиатурой (удобнее)
				-? через меню
		+ одного объекта
			+ меню изменения параметров выделеной энтити
		- выделение объектов в области (множественное выделение)
		+ если редактор включен, то выделяем мышкой
		+ изменение координат entity
			+ перемещение с помощью мышки
				+ как в Unity3d
				@todo 1 - физическое таскание мышкой с помошью MouseJoint
					- менять вид перемешения мышкой
		-+ удаление выделенных объектов
			+ одного энтити
	]
	@todo 2 - копирование объектов: Ctrl + C
	- втавка объектов: Ctrl + V
		- по координатам мышки
	-? дублирование объектов: Ctrl + D
	+ grid
		+ draw
		+ On/Off
		+ привязка к grid
		@todo -? https://github.com/bakpakin/Editgrid
--]]

local thisModule = {}
local on = config.gameEditor.on
local List = require("code.classes.UI.List")
local world = require("code.world")
thisModule.ui = require("code.Class"):newObjectsWeakTable()																							-- list of ui-objects

thisModule.images = {}
thisModule.images.light = {}
thisModule.images.light.point = love.graphics.newImage([[resources/images/editor/light.png]])

--[[ 
@todo 
	-? отдельное меню для энтити
	+ заменить на list:insertItem() (или self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}), вместо self.ui.mainMenu.items[1] = {}
--]]
function thisModule:createMainMenu()
	-- mainMenu
	self.ui.mainMenu = List:newObject({name='WorldEditor main menu', x=110, y=400, showMaxItems=16})
	self.ui.mainMenu.itemsMaxLengthInSymbols = 20
	if not on then
		self.ui.mainMenu:close()
	end
	
	-- load world
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[------- world ------]]	
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[load world]]
	self.ui.menuLoadWorld = List:newObject({name='Choice world', x=self.ui.mainMenu.x+170, y=self.ui.mainMenu.y, showMaxItems=10})
	self.ui.menuLoadWorld.itemsMaxLengthInSymbols = 20
	for k, v in ipairs(world:getAllMapsNames()) do
		self.ui.menuLoadWorld:insertItem({name=v, func = function()	
			self.ui.selectedEntity:clear()
			world:load(v)
		end})
	end
	if not on then
		self.ui.menuLoadWorld:close()
	end
	self.ui.mainMenu.items[#self.ui.mainMenu.items].func = function()
		if not self.ui.menuLoadWorld:isOpen() then
			self.ui.menuLoadWorld:open()
			self.ui.menuLoadWorld:setActive()
		else
			self.ui.menuLoadWorld:close()
		end		
	end
	
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[save world]]
	self.ui.mainMenu.items[#self.ui.mainMenu.items].func = function()
		world:save(true)
	end
	
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[clear world]]	
	self.ui.mainMenu.items[#self.ui.mainMenu.items].func = function()
		world:clear()
	end
	
	-- entity ------------------------------------------------
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[------- entity -----]]
	
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[entities in world]]
	self.ui.entitiesInWorld = List:newObject({name='Entities in world', x=self.ui.mainMenu.x+170, y=self.ui.mainMenu.y, showMaxItems=10})
	self.ui.entitiesInWorld.itemsMaxLengthInSymbols = 20
	if not on then
		self.ui.entitiesInWorld:close()
	end
	self.ui.mainMenu.items[#self.ui.mainMenu.items].func = function()
		if not self.ui.entitiesInWorld:isOpen() then
			self.ui.entitiesInWorld:open()
			self.ui.entitiesInWorld:setActive()
		else
			self.ui.entitiesInWorld:close()
		end		
	end	
	
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[create entity]]
	-- createEntity
	self.ui.createEntity = List:newObject({name='Сreate entity', x=self.ui.mainMenu.x+170, y=self.ui.mainMenu.y, showMaxItems=10})
	self.ui.createEntity.itemsMaxLengthInSymbols = 20
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Test1"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Test1"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Test2"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Test2"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Light"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Light"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Door"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Door"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.TestSound"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.TestSound"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Item"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Ammo.Test"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Item.Ammo.Test"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Weapon.Ranged.Firearm"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Weapon.Ranged.Firearm"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Weapon.Ranged"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Weapon.Ranged"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Weapon.Ranged.GrenadeLauncher"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Weapon.Ranged.GrenadeLauncher"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Weapon.Ranged.Crossbow"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Weapon.Ranged.Crossbow"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Weapon.Ranged.RocketLauncher"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Weapon.Ranged.RocketLauncher"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Weapon.Ranged.Flamethrower"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Weapon.Ranged.Flamethrower"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Projectile.Test"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Projectile.Test"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Projectile.Arrow"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Projectile.Arrow"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.Projectile.Rocket"):getClassName(), func = function()	
		local wx, wy = camera:toWorld(love.mouse.getPosition())
		if self.grid.on then
			wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
		end
		local entity = require("code.classes.Entity.Item.Projectile.Rocket"):newObject({x = math.floor(wx), y = math.floor(wy)})
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.TestRectangle"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.TestRectangle"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Middle"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Middle"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Tree"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Tree"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Crate"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Crate"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.WoodPlank"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Item.WoodPlank"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Barrel"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Barrel"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Item.BottleBig"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Item.BottleBig"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	self.ui.createEntity:insertItem({name=require("code.classes.Entity.Radiosity"):getClassName(), func = function()	
		for i=1, 1 do
			local wx, wy = camera:toWorld(love.mouse.getPosition())
			if self.grid.on then
				wx, wy = math.nSA(wx, 64)+32, math.nSA(wy, 64)+32
			end
			local entity = require("code.classes.Entity.Radiosity"):newObject({x = math.floor(wx), y = math.floor(wy)})
		end
	end})
	if not on then
		self.ui.createEntity:close()
	end
	self.ui.mainMenu.items[#self.ui.mainMenu.items].func = function()
		if not self.ui.createEntity:isOpen() then
			self.ui.createEntity:open()
			self.ui.createEntity:setActive()
		else
			self.ui.createEntity:close()
		end		
	end
	
	-- @todo - при смене значения переменной в UI копировать текущее ее значение, чтобы легче было исправлять мелькие недочеты
	function thisModule:setItemListEditEntityFunc(list, entity, var, varName, setVarFunc)
		--[[
		для перезаписи при наследовании в Классе:
			если item с таким именем уже есть,
			то перезаписываем её
		--]]
		local find = false
		local currentItemNumber
		for i, item in ipairs(list.items) do
			if string.find(item.name, "\""..varName.."\"") then
				find = true
				currentItemNumber = i
				break
			end
		end
		if not find then
			list.items[#list.items+1] = {}
			currentItemNumber = #list.items
		else
--			print('rewrite')
			-- страхуемся, если нету item, то создаем
			if not list.items[currentItemNumber] then
				list.items[#list.items+1] = {}
				currentItemNumber = #list.items
			end
		end
		
		-- @todo - писать везде без [""], т.к. это лишнее, усложняет читабельность
		local setVarFuncReturn
		if type(var) == 'number' or type(var) == 'string' then		
			
			if type(var) == 'number' then
				list.items[currentItemNumber].name = [[["]]..tostring(varName)..[["] = ]]..tostring(var) -- tostring(varName) .. " = " .. tostring(var) 
			elseif type(var) == 'string' then
				list.items[currentItemNumber].name = [[["]]..tostring(varName)..[["] = ]]..[["]]..tostring(var)..[["]]
			end
			
			list.items[currentItemNumber].func = function()																													-- !!! сохраняется жесткая ссылка на таблицы
				local uiTextInput = require("code.classes.UI.TextInput"):newObject({
						x=(config.window.width/2)-105,
						y=config.window.height/2,
						name="Change value("..tostring(type(var))..") to …"
				})
				uiTextInput.itemsMaxLengthInSymbols = 30
				uiTextInput:setActive()
				
				-- INFO: self -> This is List
				uiTextInput.onPushEnter = function()																														-- !!! сохраняется жесткая ссылка на таблицы
					if type(var) == 'number' then
						if tonumber(uiTextInput:getText()) then
							if setVarFunc then setVarFuncReturn = setVarFunc(tonumber(uiTextInput:getText())) end
--							entity[varName] = tonumber(uiTextInput:getText())																								-- присвоение происходит в setVarFunc()
							list.items[currentItemNumber].name = [[["]]..tostring(varName)..[["] = ]]..tostring(setVarFuncReturn or uiTextInput:getText())					-- обновляем список для отображения изменённого значения
						end
					elseif type(var) == 'string' then
						if setVarFunc then setVarFuncReturn = setVarFunc(uiTextInput:getText()) end
--						entity[varName] = uiTextInput:getText()																												-- присвоение происходит в setVarFunc()
						list.items[currentItemNumber].name = [[["]]..tostring(varName)..[["] = ]]..[["]]..tostring(setVarFuncReturn or uiTextInput:getText())..[["]]		-- обновляем список для отображения изменённого значения
					end
					
					-- @todo при обновлении выделять измененную строчку
					
					list:setActive()
					uiTextInput:destroy()
				end
				uiTextInput.onPushEscape = function()																							-- !!! сохраняется жесткая ссылка на таблицы
					list:setActive()
					uiTextInput:destroy()				
				end
			end
		elseif type(var) == 'boolean' then
			list.items[currentItemNumber].name = [[["]]..tostring(varName)..[["] = ]]..tostring(var)
			
			list.items[currentItemNumber].func = function()																							-- !!! сохраняется жесткая ссылка на таблицы
				if setVarFuncReturn ~= nil then
					if setVarFunc then setVarFuncReturn = setVarFunc(not setVarFuncReturn) end
				else
					if setVarFunc then setVarFuncReturn = setVarFunc(not var) end
				end
				list.items[currentItemNumber].name = [[["]]..tostring(varName)..[["] = ]]..tostring(setVarFuncReturn or (not var))												-- обновляем список для отображения изменённого значения
				-- @todo при обновлении выделять измененную строчку
			end
		end
	end
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[selected entity]]	
	self.ui.selectedEntity = List:newObject({name='Selected entity', x=self.ui.mainMenu.x+170, y=self.ui.mainMenu.y, showMaxItems=10})
	self.ui.selectedEntity.itemsMaxLengthInSymbols = 20
	if not on then
		self.ui.selectedEntity:close()
	end
	self.ui.mainMenu.items[#self.ui.mainMenu.items].func = function()
		if not self.ui.selectedEntity:isOpen() then
			self.ui.selectedEntity:open()
			self.ui.selectedEntity:setActive()
		else
			self.ui.selectedEntity:close()
		end		
	end	
	
	self.ui.mainMenu:insertItem({name=[[destroy all entitys]], func=function()
		world:deleteAllEntitys()
	end})
	
	-- light ----------------------------------------------
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[------- light ------]]	
	local itemCount = #self.ui.mainMenu.items
	self.ui.mainMenu:insertItem({name=[[light.sun.brightness = ]]..require("code.graphics").light.sun.brightness, 
		func=function()																															-- !!! сохраняется жесткая ссылка на энтити
			local uiTextInput = require("code.classes.UI.TextInput"):newObject({
					x=(config.window.width/2)-105,
					y=config.window.height/2,
					name="Change value("..'number'..") to …"
			})
			uiTextInput.itemsMaxLengthInSymbols = 30
			uiTextInput:setActive()
			
			uiTextInput.onPushEnter = function()
				if tonumber(uiTextInput:getText()) then
					require("code.graphics").light.sun.brightness = tonumber(uiTextInput:getText())
					self.ui.mainMenu.items[itemCount+1].name = [[light.sun.brightness = ]]..require("code.graphics").light.sun.brightness							-- обновляем список для отображения изменённого значения
				end
				
				-- @todo при обновлении выделять измененную строчку
				
				self.ui.mainMenu:setActive()
				uiTextInput:destroy()
			end
			uiTextInput.onPushEscape = function()
				self.ui.mainMenu:setActive()
				uiTextInput:destroy()				
			end
		end
	})
	
	self.ui.mainMenu:insertItem({name=[[compile all lights shadows]], func=function()
		require("code.graphics").light.shadows:compileAllLights()
	end})
	self.ui.mainMenu:insertItem({name=[[save all compiled lights shadows]], func=function()
		require("code.graphics").light.shadows:saveCompiledShadowsAllLights()
	end})
	
	-- other ------------------------------------------------------------
	self.ui.mainMenu.items[#self.ui.mainMenu.items+1] = {}
	self.ui.mainMenu.items[#self.ui.mainMenu.items].name = [[------- other ------]]
	
	self.ui.mainMenu:insertItem({name=[[toggle grid]], func=function()
		self.grid.on = not self.grid.on
	end})
	self.ui.mainMenu:insertItem({name=[[reload world background]], func=function()
		require("code.world"):reloadBackground()
	end})
end

function thisModule:toggle()
	on = not on
	if on then
		self:on()
	else
		self:off()
	end
end

function thisModule:isOn()
	return on
end

function thisModule:off()
	on = false
	if self.ui.mainMenu then self.ui.mainMenu:close() end
	if self.ui.createEntity then self.ui.createEntity:close() end
	if self.ui.menuLoadWorld then self.ui.menuLoadWorld:close() end
	if self.ui.selectedEntity then self.ui.selectedEntity:close() end
	if self.ui.entitiesInWorld then self.ui.entitiesInWorld:close() end
	self.grid.on = false

	camera:setAttachMode('player')
end

function thisModule:on()
	on = true
	if self.ui.mainMenu then self.ui.mainMenu:open() end
	camera:setAttachMode('free')
end

--[[
Class=<class>, startX=<number>, startY=<number>, width=<number>, height=<number>, step=<number>, funcForObj=<function>
@help 
	+ exmple: require("code.worldEditor"):createEntityMatrix(require("code.classes.Entity.Test1"), 0, 0, 10, 10, 70)
--]]
function thisModule:createEntityMatrix(Class, startX, startY, width, height, step, funcForObj)
	for x=1, width do
		for y=1, height do
			local object = Class:newObject({x = startX+(x*step), y = startY+(y*step)})
			if type(funcForObj) == 'function' then
				funcForObj(object)
			end
		end	
	end
end

-------------------------------------------------------------------------------------------------------------------------------
--[[
version 0.1.0
@help 
	+ draw grid with image
--]]

thisModule.grid = {}
thisModule.grid.on = config.gameEditor.grid.on
thisModule.grid.image = love.graphics.newImage([[resources/images/other/grid.dds]])
thisModule.grid.imageDDS = love.graphics.newImage(love.image.newCompressedData([[resources/images/other/grid.dds]]), {mipmaps=true})								-- @todo - шаг штриховки линии больше, чтобы при увеличении было лучше видно
thisModule.grid.imageDDS:setMipmapFilter("linear", 0)
thisModule.grid.imageSize = thisModule.grid.image:getWidth()

local sBSizeX = math.ceil((config.window.width/thisModule.grid.imageSize)/0.5)																	-- 0.5 - maximum camera.scale when grid draw
local sBSizeY = math.ceil((config.window.height/thisModule.grid.imageSize)/0.5)
local sBSize = (sBSizeX*sBSizeY)+(sBSizeX+sBSizeY)*2
--print(sBSize)																																	-- debug
thisModule.grid.spriteBatch = love.graphics.newSpriteBatch(thisModule.grid.image, sBSize, "dynamic")
local _count = 0
--[[
drawMethod: 1=image, 2=spriteBatch
--]]
function thisModule.grid:draw(drawMethod)
	if not thisModule.grid.on or camera.scale < 0.5 then return false end
	
	love.graphics.setColor(255,255,255,255)
	local floor, ceil, camera = math.floor, math.ceil, camera
--	local Xlast, Ylast, count = 0, 0, 0																											-- debug
	if drawMethod == 2 then
		self.spriteBatch:clear()
	end
	for x = floor((camera.x-((config.window.width/camera.scale)/2)+0)/self.imageSize), ceil((camera.x+((config.window.width/camera.scale)/2)-0)/self.imageSize) do
		for y = floor((camera.y-((config.window.height/camera.scale)/2)+0)/self.imageSize), ceil((camera.y+((config.window.height/camera.scale)/2)-0)/self.imageSize) do
			if drawMethod == 1 then
				love.graphics.draw(self.image, x*self.imageSize, y*self.imageSize)
			elseif drawMethod == 2 then
				self.spriteBatch:add(x*self.imageSize, y*self.imageSize)
			end
--			Xlast, Ylast =  x*backgr.imageSize, y*backgr.imageSize																				-- debug
--			count = count+1
		end
	end
	if drawMethod == 2 then
		love.graphics.draw(self.spriteBatch, 0, 0)
	end
--	print(count)																																-- debug
end

------------------------------------------------------------------------------------------------------------
--[[
	version 0.1.0
	* select, transformTool of entitys
	@todo 
		@todo - move как в "RUBE editor"
			- если зажали кнопку, то движением мышки передвигаем объект
		+ при передвижении изменять координаты в меню, в реальном времени
		-PR сделать видео, где передвигается свет, и выложить в интернет
		- to module
		- если в одной точке много объектов, то нужно сделать выбор объекта:
			- нажатием кнопки мыши, каждый раз другой объект
				- составляем список объектов в точке Х; если при следующем выборе объекта, объект тот-же, то выбираем другой
			-? как в RimWorld: кнопка переключения объектов (неудобно)
--]]

thisModule.select = {}
thisModule.select.mouseIsPressed = false
thisModule.select.selectedEntity = false
thisModule.select.transformTool = {}
thisModule.select.transformTool.mode = 'move' or 'rotate'																						-- TODO + rename to thisModule.select.transformTool.mode
thisModule.select.transformTool.move = {}
thisModule.select.transformTool.move.drag = {}
thisModule.select.transformTool.move.drag.mode = ''
thisModule.select.transformTool.move.drag.relativePosition = {}
thisModule.select.transformTool.move.drag.relativePosition.x = 0
thisModule.select.transformTool.move.drag.relativePosition.y = 0
thisModule.select.transformTool.rotate = {}
thisModule.select.transformTool.rotate.drag = {}
thisModule.select.transformTool.rotate.drag.is = false

function thisModule.select:update()
	if not on then return false end	
	if self.selectedEntity == false or self.selectedEntity.destroyed or self.mouseIsPressed == false then return false end	
	
	self.selectedEntity.physics.body:setAwake(true)																							-- чтобы dynamic body не дергался set to false
	local wmx, wmy = camera:toWorld(love.mouse.getPosition())
	
	if self.transformTool.mode == 'move' then
		if self.transformTool.move.drag.mode == 'x' then
			if self.selectedEntity.setPosition then
				self.selectedEntity:setPosition(wmx-self.transformTool.move.drag.relativePosition.x)
			else
				self.selectedEntity.physics.body:setX(wmx-self.transformTool.move.drag.relativePosition.x)
			end
		elseif self.transformTool.move.drag.mode == 'y' then
			if self.selectedEntity.setPosition then
				self.selectedEntity:setPosition(nil, wmy-self.transformTool.move.drag.relativePosition.y)
			else
				self.selectedEntity.physics.body:setY(wmy-self.transformTool.move.drag.relativePosition.y)
			end
		elseif self.transformTool.move.drag.mode == 'xy' then
			if self.selectedEntity.setPosition then
				self.selectedEntity:setPosition(wmx-self.transformTool.move.drag.relativePosition.x, wmy-self.transformTool.move.drag.relativePosition.y)
			else
				self.selectedEntity.physics.body:setPosition(wmx-self.transformTool.move.drag.relativePosition.x, wmy-self.transformTool.move.drag.relativePosition.y)
			end
		end
	elseif self.transformTool.mode == 'rotate' then
		if self.transformTool.rotate.drag.is then
			self.selectedEntity.physics.body:setAngle(math.angle(self.selectedEntity.physics.body:getX(), self.selectedEntity.physics.body:getY(), wmx, wmy))
		end
	end
	-- перезаписываем x, y, angle
	for i, item in ipairs(thisModule.ui.selectedEntity.items) do
		if string.find(item.name, "\"".."x".."\"") then
			item.name = [[["x"] = ]]..self.selectedEntity:getX()
		elseif string.find(item.name, "\"".."y".."\"") then
			item.name = [[["y"] = ]]..self.selectedEntity:getY()	
		elseif string.find(item.name, "\"".."angle".."\"") then
			item.name = [[["angle"] = ]]..self.selectedEntity:getAngle()			
		end
	end		
end

function thisModule.select:mouseReleased(x, y, button)
	if not on then return false end
	if not (button == 1) then return false end
	
	self.mouseIsPressed = false
	self.transformTool.move.drag.mode = ''
	self.transformTool.rotate.drag.is = false
end

function thisModule.select:mousePressed(x, y, button)
	if not on then return false end
	if not (button == 1) then return false end
	
	self.mouseIsPressed = true
	
	-- + проверять колизию с transformTool
	-- + если есть колизия с transformTool, то использовать его, иначе колизия с объектами
	
	-- + нужно +thisModule.update() или love.mousemoved()(-NO), чтобы измерять передвижение мышки
	-- + если кнопку мышки нажали, то передвигаем объект, отжали - перестаем передвигать
	local passCheckCollEntity = true
	
	local wmx, wmy = camera:toWorld(x, y)
	if self.selectedEntity ~= false and (not self.selectedEntity.destroyed) then
		local cx, cy = self.selectedEntity.physics.body:getPosition()
		if self.transformTool.mode == 'move' then
			if math.boundingBox({{x=cx, y=cy}, {x=cx+32, y=cy+32}}, wmx, wmy) then
	--			print('transformTool mode move xy')
				passCheckCollEntity = false
				self.transformTool.move.drag.mode = 'xy'
				self.transformTool.move.drag.relativePosition.x = wmx - cx
				self.transformTool.move.drag.relativePosition.y = wmy - cy
			elseif math.boundingBox({{x=cx-10, y=cy}, {x=cx+10, y=cy+64}}, wmx, wmy) then
	--			print('transformTool mode move y')
				passCheckCollEntity = false
				self.transformTool.move.drag.mode = 'y'
				self.transformTool.move.drag.relativePosition.y = wmy - cy
			elseif math.boundingBox({{x=cx, y=cy-10}, {x=cx+64, y=cy+10}}, wmx, wmy) then
	--			print('transformTool mode move x')
				passCheckCollEntity = false
				self.transformTool.move.drag.mode = 'x'
				self.transformTool.move.drag.relativePosition.x = wmx - cx
			end
		elseif self.transformTool.mode == 'rotate' then
			if math.pointIncircle(wmx,wmy, cx,cy, 32) then
--				print('transformTool mode rotate')
				self.transformTool.rotate.drag.is = true
			end
		end
	end
	
	if passCheckCollEntity then
		local coll = require("code.physics").collision.rectangle(wmx, wmy, wmx, wmy)
		local entity = false
		if coll then
			for i=1, #coll do
				entity = coll[i]:getBody():getUserData()
				if entity and entity._TABLETYPE == "object" and (not entity.destroyed) and string.find(entity:getClassName(), "Entity") and (not entity.dontSelectInWorldEditor) then
					if coll[i]:getUserData() and coll[i]:getUserData().selectedInWorldEditor == false then    -- TODO +? 
	--				if string.find(entity:getClassName(), "Light") then
						local cx, cy = entity.physics.body:getPosition()
						local box = {{x=cx-32, y=cy-32}, {x=cx+32, y=cy+32}}
						if math.boundingBox(box, wmx, wmy) then
							-- @todo - привести к единой функции, чтобы не писать 2 раза одно и тоже
							self.selectedEntity = entity
							thisModule.ui.selectedEntity:clear()
							thisModule.ui.selectedEntity:insertItem({name='destroy', func=function() self.selectedEntity:destroy(); self.selectedEntity = false; thisModule.ui.selectedEntity:clear() end})
							thisModule.ui.selectedEntity:insertItem({name=[[class name = ]]..self.selectedEntity:getClassName()})
							entity:editInUIList(thisModule.ui.selectedEntity)
							thisModule.ui.selectedEntity:correctItemSelected()																		-- + BUG менюшка выбранного объекта при смене объекта полоса прокрутки слишком длинная и строки не верно отображает
							entity.physics.body:setAwake(true)
							break
						end
					else
						self.selectedEntity = entity
						thisModule.ui.selectedEntity:clear()
						thisModule.ui.selectedEntity:insertItem({name='destroy', func=function() self.selectedEntity:destroy(); self.selectedEntity = false; thisModule.ui.selectedEntity:clear() end})
						thisModule.ui.selectedEntity:insertItem({name=[[class name = ]]..self.selectedEntity:getClassName()})
						entity:editInUIList(thisModule.ui.selectedEntity)
						thisModule.ui.selectedEntity:correctItemSelected()																			-- + BUG менюшка выбранного объекта при смене объекта полоса прокрутки слишком длинная и строки не верно отображает
						entity.physics.body:setAwake(true)
						break				
					end
				end
			end
		end
	end
	
end

function thisModule.select:selectEntity(entity)
	local sx, sy = camera:toScreen(entity:getX(), entity:getY())
	self:mousePressed(sx, sy, 1)
	self:mouseReleased(0, 0, 1)
	camera:setPosition(entity:getX(), entity:getY())
end

function thisModule.select:keyPressed(key)
	if on == false then return false end
	if key == config.controls.transformTool.move then
		self.transformTool.mode = 'move'
	elseif key == config.controls.transformTool.rotate then
		self.transformTool.mode = 'rotate'
	end
end

function thisModule.select:draw()
	if self.selectedEntity == false or self.selectedEntity.destroyed then return false end
	
	local x, y = self.selectedEntity:getPosition()
	
	-- @todo - рисовать текстурой
	if self.transformTool.mode == 'move' then
		love.graphics.setColor(0, 255, 0, 255)
		love.graphics.rectangle("line", x, y, 32, 32)		
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.line(x, y, x, y+64)
		love.graphics.setColor(0, 0, 255, 255)
		love.graphics.line(x, y, x+64, y)
	elseif self.transformTool.mode == 'rotate' then
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.circle("line", x, y, 32)
		love.graphics.line(x-32, y, x+32, y)
		love.graphics.line(x, y-32, x, y+32)		
	end
end
---------------------------------------------------------------------------------------------------------------------------

--[[
version 0.0.1
@help 
	+ INPUT
@todo 
	- 
--]]
thisModule.input = {}

function thisModule.input:keyPressed(key)
	thisModule.select:keyPressed(key)
end

function thisModule.input:mousePressed(x, y, button)
	thisModule.select:mousePressed(x, y, button)
end

function thisModule.input:mouseReleased(x, y, button)
	thisModule.select:mouseReleased(x, y, button)
end
-----------------------------------------------------------------------------------------

function thisModule:update(dt)
	self.select:update()
end

function thisModule:draw()
	if not on then return false end
	self.select:draw()
	self.grid:draw(2)
end

if on then
	thisModule:on()
else
	thisModule:off()
end

return thisModule