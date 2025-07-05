--[[
	© Savoshchanka Anton, 2012-2022
--]]

--[[------------------------------------------------------------------------------------------------
	* переписываем дефолтную функцию
	@todo 
		@todo - почему используется rawget() вместо обычной проверки?
			* вроде раньше был баг с обычной проверкой?
		@todo - посмотреть в исходниках, как работает эта функция
		@todo 1 - убрать везде _TABLETYPE, писать вместо этого type(...)
--]]------------------------------------------------------------------------------------------------
local typeDef = _G.type
function type(obj)
	local typeDef = typeDef
	if typeDef(obj) == 'table' then
		--[[ old
		if rawget(obj, "_TABLETYPE") then
			return  rawget(obj, "_TABLETYPE")
		else
			return typeDef(obj)
		end
		--]]
		if obj._TABLETYPE then
			return obj._TABLETYPE
		else
			return typeDef(obj)
		end		
	else
		return typeDef(obj)
	end
end

if config.noGameMode then
	require("noGameMode")
	
	return true
end

-- from LOVE 0.10.0
function love.run()
 
	if love.math then
		love.math.setRandomSeed(os.time())
	end
 
	if love.load then love.load(arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
 
	-- Main loop time.
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end
		
		-- For what this delay?; http://www.love2d.org/wiki/Talk:love.run; http://love2d.org/forums/viewtopic.php?f=4&t=76998
		if love.timer then love.timer.sleep(0.001) end
	end
 
end

love.load = require("code.load")
love.update = require("code.update")
love.draw = require("code.draw")

love.keypressed = require("code.input").keyPressed
love.keyreleased = require("code.input").keyReleased
love.mousepressed = require("code.input").mousePressed
love.mousereleased = require("code.input").mouseReleased
love.wheelmoved = require("code.input").wheelMoved
love.mousemoved = require("code.input").mouseMoved
love.textinput = require("code.input").textInput

function love.focus(focus)
	if not focus then
		
	end
end

function love.quit()
	love.event.quit()
end

