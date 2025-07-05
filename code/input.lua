--[[
version 0.0.3
]]

--love.keyboard.setKeyRepeat(true)

-- variables private
local thisModule = {}
local keys = {}
keys.numlock = false
keys.scrolllock = false

-- variables public
thisModule.lastKeyPressed = ''

-- methods public

function thisModule.keyPressed(key, scancode, isrepeat)
	thisModule.lastKeyPressed = key
	
	require("code.player").input:keyPressed(key)
	require("code.ui").input:inputNotCharacterKeys('keyPressed', key)
	require("code.worldEditor").input:keyPressed(key)
	
end

function thisModule.keyReleased(key, scancode)
	if key == 'scrolllock' then
		keys.scrolllock = not keys.scrolllock
	elseif key == 'numlock' then
		keys.numlock = not keys.numlock
	end
	require("code.player").input:keyReleased(key)
end

function thisModule.mousePressed(x, y, button, istouch)
	require("code.player").input:mousePressed(x, y, button)
	require("code.worldEditor").input:mousePressed(x, y, button)
	require("code.ui").input:inputNotCharacterKeys('mousePressed', button)
	
	-- TESTS
	require("code.ai.pathfinding.navMesh"):mousePressed(x, y, button)	
end

function thisModule.mouseReleased(x, y, button, istouch)
	require("code.player").input:mouseReleased(x, y, button)
	require("code.worldEditor").input:mouseReleased(x, y, button)	
end

function thisModule.wheelMoved(x, y)
	camera.input:wheelMoved(x, y)
	require("code.ui").input:inputNotCharacterKeys('wheelMoved', y)
end

function thisModule.mouseMoved(x, y, dx, dy)
	
end

function thisModule.textInput(text)
	require("code.ui").input:textInput(text)
end

function thisModule:isNumlock()
	return keys.numlock
end

return thisModule