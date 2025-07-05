--[[
version 0.0.1
@help 
	+ 
@todo 
	+?YES draw with Mesh, вместо Image или rectange
	+ save
	+ load
	BUG 1 + неправильно отображаются размеры в selected листе эдитора при загрузке уровня
	- убрать из имени Test
	-? измерять в метрах
	- тестирование. создать че-нить из этого
--]]

local ClassParent = require('code.classes.Entity')
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
ThisModule.z = 10
--ThisModule.image = ThisModule._modGraph.images.testWhite
ThisModule.width = 64
ThisModule.height = 5

-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	if arg.width then
		object.width = arg.width
	end
	if arg.height then
		object.height = arg.height
	end	
	local shape = love.physics.newRectangleShape(0, 0, object.width, object.height, 0)
	local fixture = love.physics.newFixture(object.physics.body, shape, 1)																		-- shape копируется при создании fixture
--	fixture:setUserData({typeCollision = true})
	
	object.physics.body:setAwake(false)																											-- !!! обязательно, если bodyType="static"; это повышает производительность, т.к. тело само не "засыпает"
	object.physics.fixture = fixture
	
	-- drawBuffer shape
--	local shape = love.physics.newRectangleShape(0, 0, object.width, object.height, 0)
--	local fixture = love.physics.newFixture(object.physics.body, shape, 0)	
--	fixture:setSensor(true)
	fixture:setUserData({typeDraw = true})
	
	object.drawColor = arg.color or {255, 255, 255, 255}
	object.meshVertices = {
		{
			-- top-left corner
			-object.width/2, -object.height/2, -- position of the vertex
			0, 0, -- texture coordinate at the vertex position
			unpack(object.drawColor) -- color of the vertex
		},
		{
			-- top-right corner
			object.width/2, -object.height/2,
			1, 0, -- texture coordinates are in the range of [0, 1]
			unpack(object.drawColor)
		},
		{
			-- bottom-right corner
			object.width/2, object.height/2,
			1, 1,
			unpack(object.drawColor)
		},
		{
			-- bottom-left corner
			-object.width/2, object.height/2,
			0, 1,
			unpack(object.drawColor)
		}
	}
	object.mesh = love.graphics.newMesh(object.meshVertices)
	
	object.shadows.directional.on = false
--	object.shadows.directional.z = 2
	
	return object
end

function ThisModule:editInUIList(list)
	if self.destroyed then self:destroyedError() end
	
	ClassParent.editInUIList(self, list)
	
	local wE = require("code.worldEditor")
	
	wE:setItemListEditEntityFunc(list, self, self.width, 'width', function(var) self:setSize(var, nil); return self.width end)
	wE:setItemListEditEntityFunc(list, self, self.height, 'height', function(var) self:setSize(nil, var); return self.height end)
end

--[[
	@help 
		+ удалять и создавать новые фикстуры:
			+ фикстуры столкновений
			+ drawBuffer
		+ изменять вертексы в mesh
--]]
function ThisModule:setSize(width, height)
	if type(width) == 'number' then
		self.width = width
	end
	if type(height) == 'number' then
		self.height = height
	end
	
	for i, fixture in ipairs(self.physics.body:getFixtureList()) do
		if fixture:getUserData() then
			local shape = love.physics.newRectangleShape(0, 0, self.width, self.height, 0)
			local fixtureNew = love.physics.newFixture(self.physics.body, shape, 1)																		-- shape копируется при создании fixture
			fixtureNew:setUserData(fixture:getUserData())
			fixtureNew:setCategory(fixture:getCategory())
			
			fixture:setUserData(nil)
			fixture:destroy()
		end
	end
	
	self.meshVertices = {
		{
			-- top-left corner
			-self.width/2, -self.height/2, -- position of the vertex
			0, 0, -- texture coordinate at the vertex position
			unpack(self.drawColor) -- color of the vertex
		},
		{
			-- top-right corner
			self.width/2, -self.height/2,
			1, 0, -- texture coordinates are in the range of [0, 1]
			unpack(self.drawColor)
		},
		{
			-- bottom-right corner
			self.width/2, self.height/2,
			1, 1,
			unpack(self.drawColor)
		},
		{
			-- bottom-left corner
			-self.width/2, self.height/2,
			0, 1,
			unpack(self.drawColor)
		}
	}
	
	self.mesh:setVertices(self.meshVertices)
end

function ThisModule:getSavedLuaCode()
	if self.destroyed then self:destroyedError() end
	
	-- одна строка = один entity
	local saveString = ClassParent.getSavedLuaCode(self)	
--	if rawget(self, 'width') ~= nil then
		saveString = saveString..", "..[[width = ]]..tostring(self.width)
--	end
--	if rawget(self, 'height') ~= nil then
		saveString = saveString..", "..[[height = ]]..tostring(self.height)
--	end	

	return saveString
end

return ThisModule
