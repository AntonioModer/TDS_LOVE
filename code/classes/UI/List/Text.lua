--[[
version 0.3.3
@help 
	+ setActive(): всегда должен существовать один лист, чтобы переключаться между игровыми листами и консольным листом
	+ see "gui_list_prototype.xcf"
--]]

local ClassParent = require('code.classes.UI.List')
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
ThisModule.name = 'UIText name'

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

--[[
version 0.1.2
--]]
function ThisModule:addText(str)
	if self.destroyed then self:destroyedError() end
	
	-- отрезаем новую строку, если есть переход на новую строку
	local _start = string.find(str, "\n")
	if _start ~= nil then
		self.items[#self.items+1] = {}
		self.items[#self.items].name = tostring(self._utf8KS.sub(str, 1, _start))
		-- строка не влазит
		if self._utf8KS.len(self.items[#self.items].name) > self.itemsMaxLengthInSymbols then
			self.items[#self.items].name = tostring(self._utf8KS.sub(str, 1, self.itemsMaxLengthInSymbols))
			self:addText(string.sub(str, self.itemsMaxLengthInSymbols+1, -1))
		else
			self:addText(string.sub(str, _start+1, -1))
		end
	else
		self.items[#self.items+1] = {}
		self.items[#self.items].name = tostring(str)
		-- строка не влазит
		if self._utf8KS.len(self.items[#self.items].name) > self.itemsMaxLengthInSymbols then
			self.items[#self.items].name = tostring(self._utf8KS.sub(str, 1, self.itemsMaxLengthInSymbols))
			self:addText(self._utf8KS.sub(str, self.itemsMaxLengthInSymbols+1, -1))
		end		
	end
end

return ThisModule
