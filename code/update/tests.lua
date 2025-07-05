return function(dt)
--require('code.classes.Entity.Light').color[1] = require('code.classes.Entity.Light').color[1] - dt*100
--require('code.classes.Entity.Light').color[2] = require('code.classes.Entity.Light').color[2] - dt*100
--require('code.classes.Entity.Light').color[3] = require('code.classes.Entity.Light').color[3] - dt*100
--require('code.classes.Entity.Light').brightness = require('code.classes.Entity.Light').brightness - dt*10

--require("code.ai.pathfinding.navMesh"):update(dt)

-- test.humanoid
--test.humanoid:turnToUpdate(game.player.entity:getX(), game.player.entity:getY())
--test.humanoid:moveUpdate({coordinatesSystem='local', direction='forward'})

--[[
test.humanoidObjects = require("code.classes.Entity.Humanoid"):getAllObjects()

for k, object in pairs(test.humanoidObjects) do
	if object ~= game.player.entity then
		object:update()
		
--		object:turnToUpdate(game.player.entity:getX(), game.player.entity:getY())
--		object:moveUpdate({coordinatesSystem='local', direction='forward'})

--		object:moveUpdate({coordinatesSystem='global', direction='east'})
	end
end

--]]

--test.humanoid.sound:setPosition((test.humanoid:getX()-game.player.entity:getX())/100, (test.humanoid:getY()-game.player.entity:getY())/100, 0)
--test.humanoid.sound:setPosition(test.humanoid:getX(), test.humanoid:getY(), 0)

--print(test.humanoid.sound:getVelocity())

--game.player.entity:move('global', 'west', true)

--print(math.random())

end