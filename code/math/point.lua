--[[------------------------------------------------------------------------------------------------
	@version 0.0.1
	* структура point
	@todo
		- documentation
		-? везде заменить код на этот тип
		-?NO draw
			-? новый тип в graphics
		+ новый тип таблицы
		-? как vector2 в GLSL (vec2)
		* это как вектор, только многие методы не нужны
		@todo 1 - найти готовые библиотеки	
--]]------------------------------------------------------------------------------------------------

--local point = {x=0, y=0}

local thisModule = {}
thisModule._TABLETYPE = 'point'

thisModule.__index = thisModule
function thisModule.__newindex(t, k, v)
	error("attempt to update a read-only table", 2)
end

-- @todo - type check
local function new(x, y)
--	assert(type(x) == 'number', [[argument1 x must be 'number' type, not ']]..type(x)..[[' type]])
--	assert(type(y) == 'number', [[argument2 y must be 'number' type, not ']]..type(y)..[[' type]])
	
	local structure = {}
	structure.x = x or 0
	structure.y = y or 0
	
	return setmetatable(structure, thisModule)
end

function thisModule:clone()
	return new(self.x, self.y)
end

function thisModule:unpack()
	return self.x, self.y
end

function thisModule:__tostring()
	return "(".. self.x ..", ".. self.y ..")"
end

function thisModule.__eq(a, b)
	return a.x == b.x and a.y == b.y
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})