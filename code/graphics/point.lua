--[[------------------------------------------------------------------------------------------------
	@version 0.0.1
	* структура graphics.point
	@todo
		-? transform, scale, love.graphics.setPointSize()
		- documentation
		-? везде заменить код на этот тип
		- draw
		+ новый тип таблицы
		- найти готовые библиотеки		
--]]------------------------------------------------------------------------------------------------

local thisModule = {}
thisModule._TABLETYPE = 'graphics.point'

thisModule.__index = thisModule
function thisModule.__newindex(t, k, v)
	error("attempt to update a read-only table", 2)
end

-- @todo - type check
local function new(position, color)
--	assert(type(x) == 'number', [[argument1 x must be 'number' type, not ']]..type(x)..[[' type]])
--	assert(type(y) == 'number', [[argument2 y must be 'number' type, not ']]..type(y)..[[' type]])
	
	local structure = {}
	structure.position = position or math.point()
	structure.color = color
	
	return setmetatable(structure, thisModule)
end

--function thisModule:clone()
--	return new(self.x, self.y)
--end

--function thisModule:unpack()
--	return self.x, self.y
--end

--function thisModule:__tostring()
--	return "(".. self.x ..", ".. self.y ..")"
--end

--function thisModule.__eq(a, b)
--	return a.x == b.x and a.y == b.y
--end

function thisModule:draw()
	
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})