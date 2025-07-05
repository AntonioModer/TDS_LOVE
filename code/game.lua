--[[
version 0.0.10
@help 
	+ когда открыт TextInput, то esc работает только для него
@todo 
	- 
--]]

local thisModule = {}

local worldEditor = require('code.worldEditor')
local pause = false
thisModule.ui = require("code.Class"):newObjectsWeakTable()																	-- list of ui-objects


function thisModule:createMainMenu()
	if self.ui.mainMenu then return false end
	
	local List = require("code.classes.UI.List")
	
	self.ui.mainMenu = List:newObject({name='Game main menu', x=110, y=200, showMaxItems=7})
	self.ui.mainMenu.itemsMaxLengthInSymbols = 20
	self.ui.mainMenu:setActive()
	
	self.ui.mainMenu:insertItem({name = [[1. new game]]})
	
	self.ui.mainMenu:insertItem({name = [[2. resume game]]})
	
	self.ui.mainMenu:insertItem({name = [[3. load game]]	})
	
	self.ui.mainMenu:insertItem({name = [[4. options]]	})
	
	self.ui.mainMenu:insertItem({name = [[5. exit game]], func = function() love.quit() end})
	
	self.ui.mainMenu:insertItem({name = [[6. game editor = ]]..tostring(worldEditor:isOn()),
		func = function(self)
			worldEditor:toggle()
			self.name = [[6. game editor = ]]..tostring(worldEditor:isOn())
		end
	})

	self.ui.mainMenu:insertItem({ name = [[7. debug mode = ]]..tostring(debug:isOn()),
		func = function(self)
			debug:toggle()
			self.name = [[7. debug mode = ]]..tostring(debug:isOn())
		end
	})
end

return thisModule