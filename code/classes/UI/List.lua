--[[
version 0.7.8
@help 
	+ see "gui_list_prototype.xcf"
	+ setActive(): всегда должен существовать один лист, чтобы переключаться между игровыми листами и консольным листом
	+ передвижение объекта	
@todo 
	@todo 0 -+ полностью переделать код, а то каша, пиздец
		-? сделать itemSelected
			* есть ThisModule:getItemSelectedNumber()
			-+ list:setItemSelected(number)
				-? заменить этим методом вместо itemSelectLast(), itemSelectFirst()
		+ переменные drawItemStart, drawItemSelected 
			+ убрать из public
			-? переместить в таблицу
				-?NO local draw
				-?NO ThisModule._draw
				* не получается в draw
					+ уже занята методом ThisModule:draw()
					+ т.к. в каждом объекте нужна своя такая таблица
		-+ для понятности кода, везде использовать ThisModule:getItemSelectedNumber()
		@todo 1.1 -+ help
		@todo 1.2 -? для избежания бага с "allowMoveItemsByHoldKey = true" везде применить insertItem() вместо ручного: items[...] = ...
			- worldEditor
	+ BUG если вдруг изменяется колличество строк, то нужно рисовать правильно "полосу прокрутки" и вообще правильно строки рисовать 
		* это баг из worldEditor.select; при смене выделенной энтити, если в энтити меньше строк, то появляется этот баг
	- текст с "\n" будет отображаться с новой строки и залазить на другие item, а это некрасиво
		- нужно чтобы не учитывалось "\n"
	-? при взаимодействии с item (нажали Enter), подсветку делать другим цветом, чтобы было видно наглядно, что мы совершили действие
	@todo 1 +-? onItemSelected(item)
		* для внешнего использования, чтобы выполнить код для выделенной строки
	@todo 2 - колесиком мышки изменять значение переменной <number>
--]]

local ClassParent = require('code.classes.UI')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end


-- variables private, only in this Class #############################################################


-- variables protected, only in Classes #############################################################
ThisModule._drawItemStart = 1																								-- 1...n; индекс первой item, от которой рисуется лист
ThisModule._drawItemSelected = 0																							-- 0...n; это номер строки начиная от _drawItemStart; 0 = не выделено


-- variables public #################################################################################
ThisModule.itemsMaxLengthInSymbols = 10																						-- длинна items в символах; def = 10
ThisModule.showMaxItems = 6																									-- максимальное отображаемое одновременно число item
ThisModule.name = 'UIList name'
ThisModule.func = nil
ThisModule.color = {r=255, g=125, b=0, a=255}
ThisModule.allowMoveItemsByHoldKey = false                                                                                  -- можно перемещать строки с помощью удержания кнопки config.controls.ui.holdToMoveItem

-- methods private ###################################################################################
-- ...

-- methods protected ##################################################################################
-- ...

-- methods public ###################################################################################

--[[
	* @arg arg <table> <nil> = 
		* @arg name <string> <nil>
		* @arg showMaxItems <number> <nil>
		* @arg itemsMaxLengthInSymbols <number> <nil>
		* @arg allowMoveItemsByHoldKey <boolean> <nil>
	* @return <object>
--]]
function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)

	-- variables protected
	object._drawItemStart = 1
	object._drawItemSelected = 0		
	object._prompt = {}																									-- подсказка для активной item
	object._prompt.showRight = true
	
	-- variables public
	object.items = {}																									-- строчки item
	if arg.name then object.name = arg.name end
	if arg.showMaxItems then object.showMaxItems = arg.showMaxItems end
	if arg.itemsMaxLengthInSymbols then object.itemsMaxLengthInSymbols = arg.itemsMaxLengthInSymbols end
	if arg.allowMoveItemsByHoldKey == true then object.allowMoveItemsByHoldKey = arg.allowMoveItemsByHoldKey end
	
	return object
end

--[[
	* @arg arg <table> <nil> = 
		* @arg name <string> <nil>
		* @arg func <function> <nil>
		* @arg funcArgTab <table> <nil>
		* @arg position <number> <nil>
		* @arg userData <any> <nil>
	* @return item <table>
	* return NO(number of item index) or YES(link-table)
	@todo
		- funcArgTab
--]]
function ThisModule:insertItem(arg)
	if self.destroyed then self:destroyedError() end
	
	if type(self) ~= 'object' then
		error([[table must be 'object' type, not ']]..type(self)..[[' type]])
	end
	local arg = arg or {}
	local item = {name = tostring(arg.name or (arg.position or (#self.items)+1)), userData = arg.userData, position = arg.position or (#self.items)+1, funcArgTab = arg.funcArgTab}
	table.insert(self.items, arg.position or (#self.items)+1, item)
	if arg.func then
		if type(arg.func) == 'function' then
			self.items[arg.position or #self.items].func = arg.func
		else
			error([[func must be 'func' type, not ']]..type(arg.func)..[[' type]])
		end	
	end
	
	return item
end

function ThisModule:onItemRemoved(itemPosition)
--	print(os.clock(), "onItemRemoved()", itemPosition)
end
--[[
	* @arg position <number> <nil>
	* @arg withoutCorrectItemSelected <boolean> <nil> (default <nil>)
--]]
function ThisModule:removeItem(position, withoutCorrectItemSelected)
    if self.destroyed then self:destroyedError() end
	
	if type(self) ~= 'object' then
		error([[table must be 'object' type, not ']]..type(self)..[[' type]])
	end
	local position = position or #self.items
	table.remove(self.items, position)
	
	for i=position, #self.items do																												-- для нижних строк после удаленной
		if self.items[i] ~= nil then
			self.items[i].position = self.items[i].position-1
		end
	end
	
	self:onItemRemoved(position)
	
	-- +ANTIBUG если последний итем удален и он оказался выделенным, то сбивается выделение
	if not withoutCorrectItemSelected then
		self:correctItemSelected()
	end
end

-- только при Input !!!
function ThisModule:onItemInputSelectionChanged(beforeItemNumber, afterItemNumber)
--	print(os.clock(), "onItemInputSelectionChanged()", beforeItemNumber, afterItemNumber)
end
local function itemInputSelectionChangedUpdate(self, beforeItemNumber)
	local afterItemNumber = self:getItemSelectedNumber()
	if beforeItemNumber < 1 and afterItemNumber > 0 then
		self:onItemInputSelectionChanged(beforeItemNumber, afterItemNumber)
	elseif beforeItemNumber > 0 and afterItemNumber > 0 then
		local beforeItem = self.items[beforeItemNumber]
		local afterItem = self.items[afterItemNumber]
		
--		print(os.clock(), beforeItem, afterItem, beforeItemNumber, afterItemNumber)
		if beforeItem ~= afterItem then
			self:onItemInputSelectionChanged(beforeItemNumber, afterItemNumber)
		end
	end
end
function ThisModule:onMoveItem(beforeItemNumber, afterItemNumber)
--	print(os.clock(), "onMoveItem()")
end
local function moveItemsUpdate(self, beforeItemNumber)
	if self.allowMoveItemsByHoldKey then
		local afterItemNumber = self:getItemSelectedNumber()
		if love.keyboard.isDown(config.controls.ui.holdToMoveItem) and beforeItemNumber > 0 and afterItemNumber > 0 then
--			print(self.items[beforeItemNumber].name, self.items[afterItemNumber].name)
			
			-- v1, как в teleglitch; в списке движутся строки при длительном использовании этого способа, что есть не хорошо
--			self.items[beforeItemNumber], self.items[afterItemNumber] = self.items[afterItemNumber], self.items[beforeItemNumber]
			----[[ v2, в списке не движутся строки при длительном использовании этого способа, что есть хорошо
			local beforeItem = self.items[beforeItemNumber]
			local afterItem = self.items[afterItemNumber]
			
			self:removeItem(beforeItemNumber, true)
			beforeItem.position = afterItemNumber
			self:insertItem(beforeItem)
			
--			print('beforeItem.position =', beforeItem.position)
--			print('afterItem.position =', afterItem.position)
--			print(self.items[beforeItemNumber].name, self.items[afterItemNumber].name)
			--]]
			self:onMoveItem(beforeItemNumber, afterItemNumber)
		end
	end	
end
-- version 0.1.3
function ThisModule:inputNotCharacterKeys(mode, key)
	if self.destroyed then self:destroyedError() end
	
	if key == config.controls.ui.interact or (config.controls.ui.allowInteractOnMouseWhellPressed and type(key) == 'number' and key == 3) then
		local currentItem = self.items[self:getItemSelectedNumber()]
		if currentItem then 
			if currentItem.func then
				if currentItem.funcArgTab then
--					currentItem.func(unpack(currentItem.funcArgTab))
					currentItem.func(currentItem.funcArgTab)
				else
					currentItem:func()
				end
			end
		end
	elseif key == config.controls.ui.left then
		if love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt') then
			self.x = self.x - self.moveSpeed
			return
		end
	elseif key == config.controls.ui.right then
		if love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt') then
			self.x = self.x + self.moveSpeed
			return
		end			
	elseif key == config.controls.ui.down or (mode == 'wheelMoved' and config.controls.ui.allowMouseWhellMove and type(key) == 'number' and key < 0 and not love.keyboard.isDown(config.controls.camera.zoomHoldConrol))  then
		if ((love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt'))) and key == config.controls.ui.down then
			self.y = self.y + self.moveSpeed
			return
		end
		
		local beforeItemNumber = self:getItemSelectedNumber()                           -- allowMoveItemsByHoldKey
		
		if #self.items == 0 then return end
		self._drawItemSelected = self._drawItemSelected+1								-- вниз обводку
		if self._drawItemSelected > self.showMaxItems then								-- если вышли за нижний край
			if self.items[self._drawItemStart+self.showMaxItems] ~= nil then				-- следующая item в листе существует
				self._drawItemStart = self._drawItemStart+1								-- спускаем область видимости листа
				self._drawItemSelected = self._drawItemSelected-1						-- назад обводку
			else
--				print('sleduywaya item ne sushestvuet')
				self:itemSelectFirst()
			end
		elseif self._drawItemSelected > #self.items then									-- если список мал и остаются пустые item
			self:itemSelectFirst()				
		end
		
		moveItemsUpdate(self, beforeItemNumber)                                               -- allowMoveItemsByHoldKey
		
		itemInputSelectionChangedUpdate(self, beforeItemNumber)
	elseif key == config.controls.ui.up or (mode == 'wheelMoved' and config.controls.ui.allowMouseWhellMove and type(key) == 'number' and key > 0 and not love.keyboard.isDown(config.controls.camera.zoomHoldConrol)) then
		if (love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt')) and key == config.controls.ui.up  then
			self.y = self.y - self.moveSpeed
			return
		end
		
		local beforeItemNumber = self:getItemSelectedNumber()                           -- allowMoveItemsByHoldKey
		
		if #self.items == 0 then return end
		self._drawItemSelected = self._drawItemSelected-1								-- вверх обводку
		if self._drawItemSelected < 1 then												-- если вышли за верхний край
			if self.items[self._drawItemStart-1] ~= nil then								-- следующая item в листе существует
				self._drawItemStart = self._drawItemStart-1								-- поднимаем область видимости листа
				self._drawItemSelected = self._drawItemSelected+1						-- назад обводку	
			else
				self:itemSelectLast()
			end
		else
			
		end
		
		moveItemsUpdate(self, beforeItemNumber)                                               -- allowMoveItemsByHoldKey
		
		itemInputSelectionChangedUpdate(self, beforeItemNumber)
	end				
end

--[[
	* title русуется выше начала координат
	@todo 
		TODO 1.3 -? изменить алгоритм отрисовки item
--]]
function ThisModule:draw()
	if self.destroyed then self:destroyedError() end
	
	if self.drawable == false then return end
	
	-- "+2+2" - место для (NO символа "перехода к другому листу" и ) "рамки"
	local width = (self._modGraph.mainFont.characterWidth*(self.itemsMaxLengthInSymbols+3))+(2+2)
	local listHeight = (self._itemHeight*self.showMaxItems)
	
	-- подложка
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
	love.graphics.rectangle( "fill", self.x, self.y, width+1+1, (self._itemHeight*self.showMaxItems)+1+1 )		-- border				
	love.graphics.setColor(192, 192, 192, 255)
	love.graphics.rectangle( "fill", self.x+1, self.y+1, width, self._itemHeight*self.showMaxItems )
	
	self:drawTitle(width)
	
	-- items
	for i = 1, self.showMaxItems do
		if self.items[self._drawItemStart+i-1] == nil then
			break
		end
		
		-- рисуем подсветку текущей item
		if self._drawItemSelected == i then
			love.graphics.setColor(230,230,230,255)
			love.graphics.rectangle( "fill", self.x+1, self.y+1+(self._itemHeight*(i-1)), width, self._itemHeight )
		end		
		
		-- текст item-a листа					
		local str = [[]]
		-- если имя не влазит в текущую отображаемую строку
		if self._utf8KS.len(self.items[self._drawItemStart+i-1].name) > self.itemsMaxLengthInSymbols then
			str = self._utf8KS.sub(self.items[self._drawItemStart+i-1].name, 1, self.itemsMaxLengthInSymbols).." …"
		else
			str = self._utf8KS.sub(self.items[self._drawItemStart+i-1].name, 1, self.itemsMaxLengthInSymbols)
		end						
		if self._modGraph.mainFont.coloredText then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(0, 0, 0, 255)
		end
		love.graphics.print(str, self.x+3, self.y+(self._itemHeight*(i-1))+3)	
		
		-- рисование подсказки
		-- если имя не влазит в текущую отображаемую выделеную item
		if self._drawItemSelected == i and self._utf8KS.len(self.items[self._drawItemStart+i-1].name) > self.itemsMaxLengthInSymbols then
			if self._prompt.showRight == true then
				-- рамка
				love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
				love.graphics.rectangle( "fill", self.x+width, self.y+1+(self._itemHeight*(i-1))-1, (self._modGraph.mainFont.characterWidth*(self._utf8KS.len(self.items[self._drawItemStart+i-1].name)))+(2+2)+2, self._itemHeight+2 )
				-- подсветка
				love.graphics.setColor(230, 230, 230, 255)
				love.graphics.rectangle( "fill", self.x+width+1, self.y+1+(self._itemHeight*(i-1)), (self._modGraph.mainFont.characterWidth*(self._utf8KS.len(self.items[self._drawItemStart+i-1].name)))+(2+2), self._itemHeight )
				-- текст
				if self._modGraph.mainFont.coloredText then
					love.graphics.setColor(255, 255, 255, 255)
				else
					love.graphics.setColor(0, 0, 0, 255)
				end
				love.graphics.print(self.items[self._drawItemStart+i-1].name, self.x+width+1+2, self.y+(self._itemHeight*(i-1))+3)
				
				if not self:isActive() then
					-- затемнение 
					love.graphics.setColor(50, 50, 50, 200)
					love.graphics.rectangle( "fill", self.x+width+2, self.y+1+(self._itemHeight*(i-1))-1, (self._modGraph.mainFont.characterWidth*(self._utf8KS.len(self.items[self._drawItemStart+i-1].name)))+(2+2), self._itemHeight+2 )				
				end					
			end
		end
	end
	
	-- bar
	-- подложка ползунка
	love.graphics.setColor(80, 80, 80, 255)
	love.graphics.rectangle("fill", self.x+1+width-(self._modGraph.mainFont.characterWidth), self.y+1, self._modGraph.mainFont.characterWidth, self._itemHeight*self.showMaxItems)
	-- сам ползунок
	love.graphics.setColor(255, 255, 255, 255)
	-- ползунок рисуется с учетом: 
	-- 	+ размера списка
	-- 	+ положения текущей строки (self._drawItemStart)
	local barHeight = 0
	-- чтобы ползунок не был больше листа
	if #self.items < self.showMaxItems then
		barHeight = listHeight
	else
		barHeight = (listHeight/100)*((self.showMaxItems/#self.items)*100)
	end
	if barHeight < 1 then
		barHeight = 1
	end
	love.graphics.rectangle("fill", self.x+1+width-(self._modGraph.mainFont.characterWidth), self.y+1+((listHeight/100)*(((self._drawItemStart-1)/(#self.items))*100)), self._modGraph.mainFont.characterWidth, barHeight)
	
	
	if not self:isActive() then
		-- затемнение листа
		love.graphics.setColor(50, 50, 50, 100)
		love.graphics.rectangle("fill", self.x, self.y, width+2, (self._itemHeight*(self.showMaxItems))+2)
	end
	
end

function ThisModule:itemSelectLast()
	if self.destroyed then self:destroyedError() end
	
	self:itemSelectFirst()
	if #self.items > self.showMaxItems then
		self._drawItemStart = #self.items - self.showMaxItems + 1
		self._drawItemSelected = self.showMaxItems
	else
		-- чтобы не было self._drawItemSelected <= 0
		if #self.items > 0 then
			self._drawItemSelected = #self.items
		else
			self._drawItemSelected = 0
		end
	end
end

function ThisModule:itemSelectFirst()
	if self.destroyed then self:destroyedError() end
	
	self._drawItemStart = 1
	self._drawItemSelected = 1
end

function ThisModule:clear()
	if self.destroyed then self:destroyedError() end
	
	self.items = {}
end

function ThisModule:getItemSelectedNumber()
	if self.destroyed then self:destroyedError() end
	
	if #self.items == 0 then
		return 0
	else
		return self._drawItemStart+self._drawItemSelected-1
	end
end

function ThisModule:setItemSelected(number)
	if self.destroyed then self:destroyedError() end
	
	if self.items[number] == nil then return false end
	
	self._drawItemStart = number
	self._drawItemSelected = 1
	
	self:correctItemSelected()
	
	return true
end

-- +ANTIBUG полоса прокрутки слишком длинная или строки не верно отображает
function ThisModule:correctItemSelected()
	if self.destroyed then self:destroyedError() end
	
	if self:getItemSelectedNumber() > #self.items then
--		print('debug: correctItemSelected() 1')
		self:itemSelectLast()
	end
	----[[
	if #self.items > self.showMaxItems and self.items[self._drawItemStart+self.showMaxItems-1] == nil then										-- если показывает лишние строки в конце и ползунок вышел за рамки
--		print('debug: correctItemSelected() 2')
		for i=1, self.showMaxItems-1 do
			if self.items[self._drawItemStart+i] == nil then
				self._drawItemStart = self._drawItemStart-1
				self._drawItemSelected = self._drawItemSelected+1
				
				-- control variables, страховка от непредвиденных багов
				if self._drawItemStart < 1 then
					self._drawItemStart = 1
				end
				if self._drawItemSelected > self.showMaxItems then
					self._drawItemSelected = self.showMaxItems
				end
				if self._drawItemStart < 1 or self._drawItemSelected > self.showMaxItems then
					break
				end				
			end
			
		end
	end
	--]]
end

function ThisModule:itemsSort()
	for i, v in ipairs(self.items) do
		
	end
end

-- #todo +? а нужна ли? легче пользоваться обычным for
--	* не нужна
-- func(item)
function ThisModule:forAllItemsDoFunc(func)
	for i=1, #self.items do
		if self.items[i] then
			func(self.items[i])
		end
	end
end

--[[
version 0.1.2
@help 
	+ tableExplore(table)
	+!!! сохраняется жесткая ссылка на таблицы:
		+ если таблица есть в истории (в self._tEH) данного UIList, то таблица не будет удалена до тех пор пока она находится в истории просмотра данного UIList
		+ при просмотре текущей таблицы - в функциях строк листа (в List.items[...].func)
@todo 
	- сортировать по имени и цифрам
--]]
function ThisModule:tableExplore(t, _startTab)
	if self.destroyed then self:destroyedError() end
	
	if t == nil then
		return false
	end
	if not (type(t) == 'table' or type(t) == 'class' or type(t) == 'object') then
		error([[function argument #1 must be "table" or 'class' or 'object' type, not "]]..type(t)..[[" type]])
	end
	if _startTab == true then
		self._tEStartTab = t
	end
	self._tEH = self._tEH or {}																													-- tEH: tableExploreHistory
	self._drawItemSelected = 1
	self._drawItemStart = 1
	self.items = {}

	if self._tEStartTab and self._tEStartTab ~= t then
		self.items[#self.items+1] = {}
		self.items[#self.items].name = "<= return back"
		-- self -> List
		self.items[#self.items].func = function()
			self:tableExplore(self._tEH[#self._tEH])
			table.remove(self._tEH)
		end
	end
	
	self.items[#self.items+1] = {}
	self.items[#self.items].name = "<refresh>"
	self.items[#self.items].func = function()
		self:tableExplore(t)
	end
	
	for k, v in pairs(t) do
		self.items[#self.items+1] = {}
		if type(k) == 'number' then
			self.items[#self.items].name = "["..k.."] = "
		elseif type(k) == 'string' then
			self.items[#self.items].name = "["..string.format("%q", k).."] = "
		elseif type(k) == 'boolean' then
			self.items[#self.items].name = "["..tostring(k).."] = "
		else
			self.items[#self.items].name = "["..string.format("%q", tostring(k)).."] = "
		end			
		if type(v) == 'number' then
			self.items[#self.items].name = self.items[#self.items].name..v																		-- or: _string = _string..string.format("%a", v)
		elseif type(v) == 'string' then			
			self.items[#self.items].name = self.items[#self.items].name.."[["..v.."]]"															-- or: _string = _string..string.format("%q", v)
		elseif type(v) == 'boolean' then
			self.items[#self.items].name = self.items[#self.items].name..tostring(v)
		elseif type(v) == 'table' or type(v) == 'class' or type(v) == 'object' then
			if v == _G then
				self.items[#self.items].name = self.items[#self.items].name.."[[".."tableToString(): limitation, infinity scan loop; "..tostring(v).."]]"
			else
				self.items[#self.items].name = self.items[#self.items].name.."[["..tostring(v).."]]"
				-- self -> List
				self.items[#self.items].func = function()																						-- !!! сохраняется жесткая ссылка на таблицы
					table.insert(self._tEH, t)
					self:tableExplore(v)
				end
			end
		elseif type(v) == 'function' then
			self.items[#self.items].name = self.items[#self.items].name.."[["..tostring(v).."]]"
			self.items[#self.items].func = function()
				local ok, out = pcall(v)
				if (not ok) and out ~= nil then																									-- if error in text console 
					print(out)
				end				
			end
		else
			self.items[#self.items].name = self.items[#self.items].name.."[["..tostring(v).."]]"
		end
		
		if type(v) == 'number' or type(v) == 'string' then		
			self.items[#self.items].func = function()																							-- !!! сохраняется жесткая ссылка на таблицы
				local uiTextInput = require("code.classes.UI.TextInput"):newObject({
						x=(config.window.width/2)-105,
						y=config.window.height/2,
						name="Change value("..tostring(type(v))..") to …"
				})
				uiTextInput.itemsMaxLengthInSymbols = 30
				uiTextInput:setActive()
				
				-- INFO: self -> This is List
				uiTextInput.onPushEnter = function()																							-- !!! сохраняется жесткая ссылка на таблицы
					if type(v) == 'number' then
						if tonumber(uiTextInput:getText()) then
							t[k] = tonumber(uiTextInput:getText())
						end
					elseif type(v) == 'string' then
						t[k] = uiTextInput:getText()
					end
					self:tableExplore(t)																										-- обновляем список для отображения изменённого значения
					
					-- @todo при обновлении выделять измененную строчку
					
					self:setActive()
					uiTextInput:destroy()
				end
				uiTextInput.onPushEscape = function()																							-- !!! сохраняется жесткая ссылка на таблицы
					self:setActive()
					uiTextInput:destroy()				
				end
			end
		elseif type(v) == 'boolean' then
			self.items[#self.items].func = function()																							-- !!! сохраняется жесткая ссылка на таблицы
				t[k] = not t[k]
				self:tableExplore(t)																											-- обновляем список для отображения изменённого значения
				-- @todo при обновлении выделять измененную строчку
			end
		end
	end
end

return ThisModule
