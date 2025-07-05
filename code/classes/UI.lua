--[[
version 0.2.5
@help 
	+ setActive(): всегда должен существовать один объект, чтобы переключаться между игровыми листами и консольным листом
	+ тесно взаимосвязан с "code.ui"
	+ передвигать с помощью:
		+ стрелок, когда нажали Alt
	+ попробовать utf8 из LOVE2D 0.9.2
		@help не полный, не подходит		
@todo 
	+ немного светлее неактивные объекты
	+- передвигать с помощью:
		+ клавиатуры
			-NO вынести код управления в общий(родительский) метод(интерфейс)
		-?NO LATER мышкой за бордюр
--]]

local ClassParent = require('code.Class')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end

-- variables private
-- ...

-- variables protected, use only in Class
ThisModule._utf8KS = require('code.utf8KSv2')
ThisModule._modGraph = require("code.graphics")
ThisModule._modUI = require("code.ui")
ThisModule._itemHeight = ThisModule._modGraph.mainFont.characterHeight+2+2																-- высота минимальной обводки для строки


-- variables public
ThisModule.x = 0
ThisModule.y = 0
ThisModule.drawable = true
ThisModule.name = 'UI name'
ThisModule.color = {r=255, g=125, b=0, a=255}
ThisModule.drawableTitle = true
ThisModule.moveSpeed = 5																														-- in pixels

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

-- newObject({x = <number>, y = <number>, name = <string>, drawable = <boolean>})
function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	object.x = arg.x
	object.y = arg.y
	object.name = arg.name	
	object.drawable = arg.drawable
	
	self._modUI:insert(object)
	
	return object
end

function ThisModule:destroy()
    if self.destroyed then return false end
	
	if type(self) == 'object' then	
		self:close()
	end
	ClassParent.destroy(self)
end

-- make object is usable
function ThisModule:setActive()
	if self.destroyed then self:destroyedError() end
	
	if type(self) == 'object' then
		self._modUI.currentActiveObject = self
	else
		error([[table must be 'object' type, not ']]..type(self)..[[' type]])
	end
end

function ThisModule:isActive()
	if self.destroyed then self:destroyedError() end
	
	if type(self) == 'object' then
		return self == self._modUI.currentActiveObject
	else
		error([[table must be 'object' type, not ']]..type(self)..[[' type]])
	end
end

function ThisModule:inputNotCharacterKeys()
	
end

function ThisModule:draw()
	
end

-- для title отдельно рисовать затемнение неактивного UI-объекта
function ThisModule:drawTitle(width)
	if self.destroyed then self:destroyedError() end

	if not self.drawableTitle then return nil end
	
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
	love.graphics.rectangle( "fill", self.x, self.y-self._itemHeight-1, width+1+1, self._itemHeight+2 )											-- border			
	love.graphics.setColor(255,255,255,255)
	love.graphics.rectangle( "fill", self.x+1, self.y+1-self._itemHeight-1, width, self._itemHeight )
	
	local str = [[]]
	if self._utf8KS.len(self.name) > self.itemsMaxLengthInSymbols then
		str = self._utf8KS.sub(self.name, 1, self.itemsMaxLengthInSymbols).."…"
	else	
		str = self.name
	end
	
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
	love.graphics.print('█ ', self.x+3, self.y+1-self._itemHeight-1+2)
	
	if self._modGraph.mainFont.coloredText then
		love.graphics.setColor(255, 255, 255, 255)
	else
		love.graphics.setColor(0, 0, 0, 255)
	end
	
	love.graphics.print(str, self.x+3+(self._modGraph.mainFont.characterWidth*2), self.y+1-self._itemHeight-1+2)
	
	if not self:isActive() then
		love.graphics.setColor(50,50,50,150)
		love.graphics.rectangle( "fill", self.x, self.y-self._itemHeight-1, width+1+1, self._itemHeight+1 )										-- затемнение листа			
	end		
end

function ThisModule:isOpen()
	if self.destroyed then self:destroyedError() end
	
	if self._managerUINumber then 
		return true 
	else 
		return false 
	end
end

-- setActive?=<boolean>
function ThisModule:open(setActive)
	if self.destroyed then self:destroyedError() end
	
	self._modUI:insert(self)
	if setActive then self:setActive() end
end

function ThisModule:close()
	if self.destroyed then self:destroyedError() end
	
	return self._modUI:remove(self)
end

-- @todo - rename to toggleActive()
-- setActive? = <boolean>
function ThisModule:toggle(setActive)
	if self.destroyed then self:destroyedError() end
	
	if debug.consoleG:isOn() then
		return
	end
	
	if self:isOpen() then
		self:close()
		self._modUI:switchingUIObjects()
	else
		self:open(true)
--		if setActive then self:setActive() end
	end	
end

return ThisModule
