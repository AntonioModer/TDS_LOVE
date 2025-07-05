--[[
version 0.1.7
@todo 
	@todo 1 - редактирование текста посмотреть в:
		- luigi https://github.com/airstruck/luigi
		- SUIT https://github.com/vrld/SUIT
		- LOVE-Frames
--]]

local ClassParent = require('code.classes.UI')
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
ThisModule.itemsMaxLengthInSymbols = 10																						-- длинна item в символах; def = 10
ThisModule.name = 'UITextInput name'
ThisModule.curTime = 0
ThisModule.delay = 0.5																										-- как часто мерцает курсор

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	object.x = arg.x
	object.y = arg.y
	object.name = arg.name
	object.color = {r=255, g=125, b=0, a=255}
	
	object._text = ''
	object._cursor = {}
	object._cursor.pos = 1																								-- position
	object._cursor.draw = true	

	return object
end

function ThisModule:inputCharacterKeys(unicode)
	if self.destroyed then self:destroyedError() end
	
	self._text = self._utf8KS.sub(self._text, 1, self._cursor.pos-1) .. unicode .. self._utf8KS.sub(self._text, self._cursor.pos, self._utf8KS.len(self._text))
	self._cursor.pos = self._cursor.pos+1
end

--[[
@todo 
	+- курсор: 
		- удаление символа в строке под курсором (Del)
--]]
function ThisModule:inputNotCharacterKeys(mode, key)
	if self.destroyed then self:destroyedError() end
	
	if key == config.controls.ui.interact then
		self:onPushEnter()
	elseif key == "escape" then
		self._modUI.input.blockEsc = true																												-- чтобы не срабатывало game.ui.mainMenu:toggle(true)
		self:onPushEscape()
	elseif key == 'backspace' then
		if self._cursor.pos > 1 then
			self._text = self._utf8KS.sub(self._text, 1, self._cursor.pos-2) .. self._utf8KS.sub(self._text, self._cursor.pos, self._utf8KS.len(self._text))
			self._cursor.pos = self._cursor.pos-1
		end
	elseif key == config.controls.ui.left then
		if love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt') then
			self.x = self.x - self.moveSpeed
			return
		end
		if self._cursor.pos > 1 then
			self._cursor.pos = self._cursor.pos-1
		end
	elseif key == config.controls.ui.right then
		if love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt') then
			self.x = self.x + self.moveSpeed
			return
		end		
		if self._cursor.pos < self._utf8KS.len(self._text)+1 then
			self._cursor.pos = self._cursor.pos+1
		end
	elseif key == config.controls.ui.up then
		if love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt') then
			self.y = self.y - self.moveSpeed
		end
	elseif key == config.controls.ui.down then
		if love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt') then
			self.y = self.y + self.moveSpeed
		end
	elseif (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) and love.keyboard.isDown('v') then
		self._text = love.system.getClipboardText()
		self._cursor.pos = 1
	elseif (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) and love.keyboard.isDown('c') then
		love.system.setClipboardText(self._text)
	end
end

function ThisModule:getText()
	if self.destroyed then self:destroyedError() end
	
	return self._text
end

function ThisModule:clearText()
	if self.destroyed then self:destroyedError() end
	
	self._text = ''
	self._cursor.pos = 1
end

function ThisModule:onPushEnter()
	if self.destroyed then self:destroyedError() end
	
--	self:destroy()
end

function ThisModule:onPushEscape()
	if self.destroyed then self:destroyedError() end
	
--	self:destroy()
end

function ThisModule:draw()
	if self.destroyed then self:destroyedError() end
	
	-- "+2+2" - место для (NO символа "перехода к другому листу" и ) "рамки"
	local width = (self._modGraph.mainFont.characterWidth*(self.itemsMaxLengthInSymbols+3))+(2+2)

	----------------------------- подложка
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
	love.graphics.rectangle( "fill", self.x, self.y, width+1+1, self._itemHeight+1+1 )															-- border				
	love.graphics.setColor(153,153,153,255)
	love.graphics.rectangle( "fill", self.x+1, self.y+1, width, self._itemHeight)
	
	self:drawTitle(width)
	
	----------------------- text				
	local str = [[]]
	-- если имя не влазит
	if self._utf8KS.len(self._text) > self.itemsMaxLengthInSymbols then
		str = self._utf8KS.sub(self._text, 1, self.itemsMaxLengthInSymbols).." …"
	else
		str = self._text
	end						
	if self._modGraph.mainFont.coloredText then
		love.graphics.setColor(255, 255, 255, 255)
	else
		love.graphics.setColor(0, 0, 0, 255)
	end
	love.graphics.print(str, self.x+3, self.y+(self._itemHeight*(1-1))+3)	
	
	----------------------- cursor
	self.curTime = self.curTime + love.timer.getAverageDelta()
	if self.curTime > self.delay then
		self.curTime = 0
		self._cursor.draw = not self._cursor.draw
	end
	if self._cursor.draw then	
		local lineWidth, lineStyle = love.graphics.getLineWidth(), love.graphics.getLineStyle()
		love.graphics.setLineWidth(1)
		love.graphics.setLineStyle('rough')
		

		love.graphics.setColor(0,0,0,255)	
	--	love.graphics.line(self.x-2+(7*self._cursor.pos), self.y-3+self._itemHeight+2, self.x-2+(7*self._cursor.pos)+5, self.y-3+self._itemHeight+2)		-- cursor v1: _
		love.graphics.line(self.x-3+(7*self._cursor.pos), self.y+self._itemHeight-2, self.x-3+(7*self._cursor.pos), self.y+2)								-- cursor v2: |	
		
		love.graphics.setLineWidth(lineWidth)
		love.graphics.setLineStyle(lineStyle)	
	end

	--------------------------- затемнение листа
	if not self:isActive() then
		love.graphics.setColor(50,50,50,200)
		love.graphics.rectangle( "fill", self.x, self.y, width+2, (self._itemHeight)+2 )					
	end		
end

return ThisModule
