--[[
version 0.3.8
@help 
	+ набор текста зависит от love.textinput()
	+ работает только с англ. раскладкой клавиатуры
	+ вызов консоли "Alt+F1"
	+ ="text" == print("text")
@todo 
	- переключаться между консольными ui объектами
	-? перейти на https://github.com/vrld/love-console
--]]


local graphics = require("code.graphics")
local UIText = require("code.classes.UI.List.Text")

local thisModule = {}

local on = false
thisModule.ui = require("code.Class"):newObjectsWeakTable()
thisModule.ui.text = UIText:newObject({name='Console', x=5, y=0})
thisModule.ui.text.showMaxItems = 10
thisModule.ui.text.y = config.window.height-thisModule.ui.text._itemHeight-(thisModule.ui.text._itemHeight*thisModule.ui.text.showMaxItems)-6
thisModule.ui.text.itemsMaxLengthInSymbols = math.floor((config.window.width/graphics.mainFont.characterWidth)-5)
thisModule.ui.text:close()

thisModule.ui.textInput = require("code.classes.UI.TextInput"):newObject({name='ConsoleTextInput', x=5, y=config.window.height-thisModule.ui.text._itemHeight-3})
thisModule.ui.textInput.itemsMaxLengthInSymbols = math.floor((config.window.width/graphics.mainFont.characterWidth)-5)
thisModule.ui.textInput:close()
thisModule.ui.textInput.drawableTitle = false
function thisModule.ui.textInput:onPushEnter()
	local str = self:getText():gsub("^=%s?", "return "):gsub("^return%s+(.*)(%s*)$", "print(%1)%2")										-- "=x" - "print(x)"
	local ok, out = pcall(function() assert(loadstring(str))() end)
	if not ok then																										-- if error in text console 
		thisModule:print(out)
	else
		-- writed in console not function print()
		if string.match(str, 'print') == nil then
			print(str)																													-- show in console
		end
	end
	self:clearText()
end

function thisModule:print(...)
	if #thisModule.ui.text.items > thisModule.ui.text.showMaxItems-1 then
		table.remove(thisModule.ui.text.items, 1)
	end	
	local args = {...}
	local str = [[]]
	for k, v in ipairs(args) do
		str = str..tostring(v).."	"
	end
	self.ui.text:addText(str)
	self.ui.text:itemSelectLast()
end

function thisModule:clear()
	self.ui.text:clear()
end

-- не задействовано
function thisModule:inputCharacterKeys(unicode)
	self.ui.textInput:inputCharacterKeys(unicode)
--	print('console inputCharacterKeys')
end

-- не задействовано
function thisModule:inputNotCharacterKeys(key)
	if not self.on then
		return
	end

	self.ui.textInput:inputNotCharacterKeys(key)
--	print('console inputNotCharacterKeys')
end

local parentDraw = thisModule.ui.text.draw
function thisModule.ui.text:draw()
	love.graphics.setColor(126,126,126,126)
	love.graphics.rectangle("fill",0,0,config.window.width,config.window.height)      
	parentDraw(thisModule.ui.text)
end

-- rewrite function print()
local func = _G['print']
_G['print'] = function(...)
	thisModule:print(...)
	return func(...)
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
	self.ui.textInput:close()
	self.ui.text:close()
end

function thisModule:on()
	on = true
	self.ui.textInput._modUI:insert(self.ui.textInput)
	self.ui.text._modUI:insert(self.ui.text)
	self.ui.textInput:setActive()
end

return thisModule
