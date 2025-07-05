--[[
version 0.2.8
@help 
	+ менеджер UI элементов
	+ смотри code.classes.UI
@todo 
	- в строке листа текстовые стрелочки показывающие наличие дочерних листов
		- > ...текст   когда дочернее окно закрыто
		- < ...текст   когда дочернее окно открыто
	-? ClassUIFrame
	-? ClassUIButton
	-? взаимодествие с помощью мыши
	-+?NO разобраться с wxLua
		@help лучше иметь прямой доступ к памяти Lua в UI, чем мучаться с биндами
	-? luapower.com winapi
	-? GTK Lua -> lgob, LuaGtk
		+ INFO https://ru.wikipedia.org/wiki/GTK%2B
	-? tag "desktop environment" in http://luaforge.net/tags/
		- tekui
	-? ImGUI
		- FFI ImGUI C port
		- http://love2d.org/forums/viewtopic.php?f=5&t=82467
	-!!!? luigi https://github.com/airstruck/luigi
	@todo -!!! slider https://love2d.org/forums/viewtopic.php?f=5&t=80711
	-?NO LOVE-Frames
		@help библиотека больше не поддерживается автором
	-? SUIT https://github.com/vrld/SUIT
	@help не забывать о love.graphics.setScissor()
	@todo - выбор значения параметра в List
		- при взаимодействии со строчкой создавать лист с параметрами, в котором выбрать параметр
		@help удобно менять значения, чтобы каждый раз не писать вручную параметр с типом <string>
	-? "GUI Editor mtasa" https://forum.mtasa.com/viewtopic.php?f=108&t=22831
	-? для наглядного представления таблицы
		- записывать в файл как исходник (tableToTXT.lua)
		-? делать html страницу с "html table" для просмотра содержания Lua таблиц
--]]

-- variables private
local thisModule = {}
local queueUIObjects = require("code.Class"):newObjectsWeakTable()																				-- create table with weak references to objects		-- table index type = number


-- variables protected
-- ...

-- variables public


-- !!! WARNING; в этой переменной хранится жесткая ссылка на объект; при удалении активного UI-объекта необходимо очистить эту ссылку, чтобы UI-объект был окончательно удален из памяти
thisModule.currentActiveObject = nil


-- methods publics

-- @todo - убрать ...
-- thisModule:insert(object=<UIObject>, position=<number>)
function thisModule:insert(...)
	local object, position = ...
	if object then
		if type(object) == 'object' then
			if not object._managerUINumber then
				table.insert(queueUIObjects, position or (#queueUIObjects)+1, object)
				object._managerUINumber = position or #queueUIObjects
			end
		else
			error([[table must be 'object' type, not ']]..type(object)..[[' type]])
		end
	else
		error([[need argument in method 'insert']])
	end
end

-- thisModule:remove(object=<object>)
function thisModule:remove(object)
    if type(object) ~= 'object' then
		error([[table must be 'object' type, not ']]..type(object)..[[' type]])
	end
	if not object._managerUINumber then
		return false
	end
	
	-- смотри пояснение к thisModule.currentActiveObject
	if object:isActive() then																													
		thisModule.currentActiveObject = nil
	end
	
	table.remove(queueUIObjects, object._managerUINumber)
	object._managerUINumber = nil
	for i, o in ipairs(queueUIObjects) do																										-- переназначение своего "номера в таблице" после изменения таблицы
		o._managerUINumber = i
	end

	return true		
end

-- switching between UI-objects
function thisModule:switchingUIObjects()
	if debug.consoleG:isOn() then
		return
	end

	if #queueUIObjects == 0 then 
		return false
	end
	if self.currentActiveObject then
		if self.currentActiveObject._managerUINumber == #queueUIObjects then
			queueUIObjects[1]:setActive()
		else
			queueUIObjects[self.currentActiveObject._managerUINumber+1]:setActive()
		end
	else
		queueUIObjects[1]:setActive()
	end

end

--[[
version 0.0.1
@help 
	+ INPUT
@todo 
	-
--]]
thisModule.input = {}
thisModule.input.blockEsc = false																												-- чтобы не срабатывало game.ui.mainMenu:toggle(true)
function thisModule.input:inputNotCharacterKeys(mode, key)
	self.blockEsc = false																														-- чтобы не срабатывало game.ui.mainMenu:toggle(true)
	if thisModule.currentActiveObject then
		thisModule.currentActiveObject:inputNotCharacterKeys(mode, key)			
	end
	
	if key == 'escape' and not self.blockEsc then
		game.ui.mainMenu:toggle(true)
	end
	
	if (love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt')) and love.keyboard.isDown('f1') then
		debug.consoleG:toggle()
	end			
	if debug.consoleG:isOn() then
		return nil																						-- !!!
	end
	
	if key == config.controls.ui.switch then
		thisModule:switchingUIObjects()
	end	
end

function thisModule.input:textInput(text)
	if thisModule.currentActiveObject and thisModule.currentActiveObject.inputCharacterKeys then
		thisModule.currentActiveObject:inputCharacterKeys(text)
	end
end

function thisModule:draw()
	
	-- не активные
	for i=1, #queueUIObjects do	
		if queueUIObjects[i] ~= self.currentActiveObject then
			queueUIObjects[i]:draw()
		end
	end
	if self.currentActiveObject then
		self.currentActiveObject:draw()
	end
	
end

function thisModule:test()
	--[[ стресс-тест с огромным количеством UI-объектов ==================

	local OWT = require("code.Class"):newObjectsWeakTable()
	local UIList = require("code.classes.UI.List")

	OWT["0"] = {x=0}
	for i=1, 300 do
		local id = tostring(i)
		OWT[id] = UIList:newObject({x=OWT[tostring(i-1)].x+5, y=400})
		
		for i1=1, i do
			OWT[id].items[i1] = {}
			OWT[id].items[i1].name = tostring(i1)
		end
	--	if i%7 == 0 then OWT[id]:delete() end
	end
	-- ================================================================== ]]
	self.test = {}
	
	self.test.OWT = require("code.Class"):newObjectsWeakTable()
	local UIList = require("code.classes.UI.List")
	
	function self.test.removeItem(item)
		require("code.ui").test.OWT[1]:removeItem(item.position)
	end
	self.test.OWT[1] = UIList:newObject({name = 'Test List', x=500, y=100})
	for i=1, 10 do
		self.test.OWT[1]:insertItem({func = self.test.removeItem})
	end
	
--	require("code.ui").test.OWT[1]:removeItem(7)
	require("code.ui").test.OWT[1]:setItemSelected(10)
	require("code.ui").test.OWT[1]:setItemSelected(0)
end











return thisModule