--[[------------------------------------------------------------------------------------------------
	@version 0.0.1
	* структура color
	* not done
	@todo
		- documentation
		@todo 2 -? везде заменить код на этот тип
		- пример API:
			- Unity
			- SFML
		@todo 1 - найти готовые библиотеки
--]]------------------------------------------------------------------------------------------------

local thisModule = {}
thisModule._TABLETYPE = 'graphics.color'

thisModule.__index = thisModule
function thisModule.__newindex(t, k, v)
	error("attempt to update a read-only table", 2)
end

-- @todo - type check
local function new(r, g, b, a)
--	assert(type(x) == 'number', [[argument1 x must be 'number' type, not ']]..type(x)..[[' type]])
--	assert(type(y) == 'number', [[argument2 y must be 'number' type, not ']]..type(y)..[[' type]])
	
	local structure = {}
	structure.r = r or 255
	structure.g = g or 255
	structure.b = b or 255
	structure.a = a or 255
	
	return setmetatable(structure, thisModule)
end

--function thisModule:clone()
	
--end

function thisModule:unpack()
	
end

--function thisModule:__tostring()
	
--end

--function thisModule.__eq(a, b)
	
--end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})