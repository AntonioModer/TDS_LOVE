

test = test or {}

require("code.world"):load("test")
camera:setPosition(3250, 4200)
--camera.scale = 2

--require("code.world").scene:load("test")

--require("code.worldEditor"):createEntityMatrix(require("code.classes.Entity.Test1"), 0, 0, 62, 62, 70)
--require("code.worldEditor"):createEntityMatrix(require("code.classes.Entity.Test1"), 0, 0, 300, 300, 64.5) -- 64.5
--print(require('code.classes.Entity.Light'):getObjectsCount())


--test["code.ai.pathfinding.graph"] = require("code.ai.pathfinding.graph")
--test["code.ai.pathfinding.graph"]:test()

--require("code.ai.pathfinding.navMesh")

--love.graphics.setWireframe( true )

game.player.entity = require('code.classes.Entity.Humanoid'):newObject({x=3250, y=4200})
game.player.entity.allowToSave = false
--game.player.entity.debug.draw.on = false
--require("code.sound"):createListener(game.player.entity.physics.body)

test.cameraSetWindow = {}
test.cameraSetWindow.l = 0
test.cameraSetWindow.t = 0
test.cameraSetWindow.w = love.graphics.getWidth()
test.cameraSetWindow.h = love.graphics.getHeight()

--require("code.ui"):test()

test.test = [[ [=[ [==[ test ]==] ]=] ]]
--[[ --[=[ --[==[ comment ]==] ]=] ]]

do --[[ test world physics производительность
--	local matrixSize = math.ceil(100000^0.5)
--	require("code.worldEditor"):createEntityMatrix(require("code.classes.Entity.Test1"), 0, 0, matrixSize, matrixSize, 70)  -- статических
	require("code.classes.Entity.Test1"):newObject({x=70, y=70})
	
	
	matrixSize = math.ceil(1000^0.5)
	local funcForObj = function(object)
--		object.physics.body:setAwake(false)
--		object.physics.body:setActive(false)
	end
	require("code.worldEditor"):createEntityMatrix(require("code.classes.Entity.Test2"), -(matrixSize*70)-70, -(matrixSize*70)-70, matrixSize, matrixSize, 70, funcForObj)  -- динамических непулевых спящих
	
	matrixSize = math.ceil(1000^0.5)
	local funcForObj = function(object)
--		object.physics.body:setAwake(false)
		object.physics.body:setSleepingAllowed(false)
--		object.physics.body:setActive(false)
	end
	require("code.worldEditor"):createEntityMatrix(require("code.classes.Entity.Test2"), 0, -(matrixSize*70)-70, matrixSize, matrixSize, 70, funcForObj)  -- динамических непулевых неспящих
	
	local funcForObj = function(object) 
		object.physics.body:setSleepingAllowed(false)
		object.physics.body:setBullet(true)
	end
	require("code.worldEditor"):createEntityMatrix(require("code.classes.Entity.Test2"), -(1000*70)-70, 0, 1000, 1, 70, funcForObj)  -- динамических пулевых неспящих
	
	local funcForObj = function(object)
		local fixtureList = object.physics.body:getFixtureList()
		fixtureList[1]:setSensor(true)
		object:setMobility('static')
		object.physics.body:setAwake(false)
--		object.physics.body:applyLinearImpulse(0, 10000)
--		object.physics.body:setActive(false)
	end
	require("code.worldEditor"):createEntityMatrix(require("code.classes.Entity.Test2"), -(10000*70)-70, 70, 10000, 1, 70, funcForObj)  -- сенсоры
	
	require("code.physics").skip.skipMax = 0
--]]

end
--

test.humanoid = require('code.classes.Entity.Humanoid'):newObject({x=2300, y=2550})
test.humanoid.allowToSave = false

--require("code.sound"):test()

----[[
function test.updateSouth(self)
	self:moveUpdate({coordinatesSystem='global', direction='south'})
end
function test.updateEast(self)
	self:moveUpdate({coordinatesSystem='global', direction='east'})
end
function test.updateWest(self)
	self:moveUpdate({coordinatesSystem='global', direction='west'})
end
function test.updateWestNorth(self)
	self:moveUpdate({coordinatesSystem='global', direction=math.vector(-1, -1)})
end
function test.updateWestNorth(self)
	self:moveUpdate({coordinatesSystem='global', direction=math.vector(-1, -1)})
end
function test.updateEastNorth(self)
	self:moveUpdate({coordinatesSystem='global', direction=math.vector(1, -1)})
end
function test.updateToMouse(self)
	if require("code.worldEditor"):isOn() then return false end
	
	local mouseVector = math.vector(camera:toWorld(love.mouse.getPosition()))
	local myVector = math.vector(self:getPosition())
	if love.mouse.isDown(1) then
		self:moveUpdate({coordinatesSystem='global', direction = mouseVector - myVector})
	end
	
--	self._setMoveforceLocalPositionCurrentAtCenter = false
--	self._moveWithoutControllerRotation = false
--	self:turnToUpdate((myVector+math.vector(0, -1)):unpack())
	self:turnToUpdate(mouseVector:unpack())
end

local funcForObj = function(object) 
	object.allowToSave = false
--	object.update = test.updateSouth
--	object._moveSpeedCurrent = 1500*2
end
require("code.worldEditor"):createEntityMatrix(require('code.classes.Entity.Humanoid'), 1100, 6300, 10, 10, 50, funcForObj)


--local funcForObj = function(object) 
--	object.allowToSave = false
--	object.update = test.updateToMouse
--end
--require("code.worldEditor"):createEntityMatrix(require('code.classes.Entity.Humanoid'), 2000+500, 500-800, 10, 10, 70, funcForObj)

--]]



local door = require('code.classes.Entity.Door'):newObject({x=3000, y=2300})
door.allowToSave = false

--local t = {}
--t.sdf = 1
--t.wew = 2
--t.tyj = 3
--t.opf = 4
--t.qcg = 5

--t.tyj = nil
--t.sdf = nil

--for k, v in pairs(t) do
--	print(k, v)
--end

--[[
local vertices = {
	{
		-- top-left corner (red-tinted)
		-32, -32, -- position of the vertex
		0, 0, -- texture coordinate at the vertex position
		255, 255, 255, -- color of the vertex
	},
	{
		-- top-right corner (green-tinted)
		32, -32,
		1, 0, -- texture coordinates are in the range of [0, 1]
		255, 255, 255
	},
	{
		-- bottom-right corner (blue-tinted)
		32, 32,
		1, 1,
		255, 255, 255
	},
	{
		-- bottom-left corner (yellow-tinted)
		-32, 32,
		0, 1,
		255, 255, 255
	},
}

-- the Mesh DrawMode "fan" works well for 4-vertex Meshes.
mesh = love.graphics.newMesh(vertices, "fan")
--]]

--local variable = false
--print((type(variable) == "boolean" and variable) or true)

--[[----------------------------
local tab = {1, 3, 4, 6, 9, 8, 7, 2, 5}
--local tab = {'one', 'three', 'four', 'six', 'nine', 'eight' , 'seven', 'two', 'five'}

table.sort(tab, function (a, b) return a < b end)

print(table.concat(tab, ', '))

--print('one_a' < 'one_b')
--]]-------------------------------


-- test jelly ========================================================================================

function test.createJelly(x, y, r, fixtureGroupIndex)
	local centerEntity = require('code.classes.Entity.TestCircle'):newObject({x=x, y=y, r=r, physics={sensor=true}, mobility='dynamic'})
	--centerEntity.debug.draw.phys.on = false
	centerEntity.drawable = false
	centerEntity.physics.body:setLinearDamping(1)
	centerEntity.physics.body:setAngularDamping(1)
	centerEntity.nodes = {}
	centerEntity.allowToSave = false

	-- create 'nodes' (outer bodies) & connect to center body
	local nodes = r/2
	for node = 1, nodes do
		local angle = (2*math.pi)/nodes*node
	--	print(angle)
		
		local posx = x+r*math.cos(angle)
		local posy = y+r*math.sin(angle)
		
		local entity = require('code.classes.Entity.TestCircle'):newObject({x=posx, y=posy, r=8, mobility='dynamic', physics={fixtureGroupIndex=fixtureGroupIndex}, ["shadows.on"]=false})
		entity.allowToSave = false
		entity.z = 3
		entity.physics.body:setAngle(angle)
		entity.physics.body:setLinearDamping(0.1)
		entity.physics.body:setAngularDamping(0.1)
	--	entity.physics.body:setFixedRotation(true)
	--	print(entity.physics.body:getLinearDamping())
		
		--[[ v1 не то
		centerEntity:setAngle(math.radToBDeg(math.angle(centerEntity:getX(), centerEntity:getY(), entity:getX(), entity:getY())))
		local ax, ay = centerEntity.physics.body:getWorldVector(1, 0)
		centerEntity:setAngle(0)
		local joint = love.physics.newPrismaticJoint(centerEntity.physics.body, entity.physics.body, entity:getX(), entity:getY(), ax, ay, false )
		joint:setLimits(-r, 0)
		joint:setLimitsEnabled(true)
		joint:setMaxMotorForce(100)
		joint:setMotorSpeed(100)
		joint:setMotorEnabled(true)
		--]]
		
		----[[ v2 то что надо
		local joint = love.physics.newDistanceJoint(centerEntity.physics.body, entity.physics.body, posx, posy, posx, posy, false)
		joint:setDampingRatio(0.1)
		joint:setFrequency(6*(10/r))
	--	joint:setFrequency(1)
	--	print(joint:getFrequency())
		--]]
		
		--[[ v3 то, но нестабильно, может вывернуться на изнанку
		local joint = love.physics.newDistanceJoint(centerEntity.physics.body, entity.physics.body, centerEntity:getX(), centerEntity:getY(), entity:getX(), entity:getY(), false)
		joint:setDampingRatio(0.1)
		joint:setFrequency(10*(10/r))
	--	print(joint:getLength())
		--]]	
		
		--[[ v4 не совсем то, но интересно, нужно в будущем использовать
		local joint = love.physics.newMotorJoint(centerEntity.physics.body, entity.physics.body, 0.3)
		joint:setAngularOffset(angle)
	--	print(joint:getLinearOffset())
	--	print(joint:getAngularOffset())
		--]]		
		
		table.insert(centerEntity.nodes, entity)
	end

	----[[ connect nodes to each other
	for i = 1, #centerEntity.nodes do
		local joint
		if i < #centerEntity.nodes then
			joint = love.physics.newDistanceJoint(centerEntity.nodes[i].physics.body, centerEntity.nodes[i+1].physics.body, centerEntity.nodes[i].physics.body:getX(), centerEntity.nodes[i].physics.body:getY(),
			centerEntity.nodes[i+1].physics.body:getX(), centerEntity.nodes[i+1].physics.body:getY(), false)
		else
			joint = love.physics.newDistanceJoint(centerEntity.nodes[i].physics.body, centerEntity.nodes[1].physics.body, centerEntity.nodes[i].physics.body:getX(), centerEntity.nodes[i].physics.body:getY(),
			centerEntity.nodes[1].physics.body:getX(), centerEntity.nodes[1].physics.body:getY(), false)
		end
		joint:setDampingRatio(0.1)
	--	joint:setFrequency(10*(10/r))
	end
	--]]

end

test.createJelly(2100, 2500, 50, -1)
test.createJelly(1900, 2500, 50, -2)
test.createJelly(1700, 2500, 50, -3)



--require('code.Class'):examples()
--require('code.logic.state'):test()

--local tab = {}
--if tab then
--	print(unpack(tab))
--else
--	print(3)
--end

--require("code.world"):test()




















