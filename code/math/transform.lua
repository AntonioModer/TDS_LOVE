--[[------------------------------------------------------------------------------------------------
	@version 0.0.1
	* структура transform
	* not done
	@todo
		- посмотреть API SFML, Unity3d, ...
		* как в https://love2d.org/wiki/love.graphics.draw
			+- position
			+- angle
			+- scale
			+-? origin
			-? shearing
		-?YES как структура
		-? как Класс
			- доработать Class, чтобы не сохранять объекты в классе
		@todo 1 - найти готовые библиотеки
--]]------------------------------------------------------------------------------------------------

local thisModule = {}
thisModule._TABLETYPE = 'transform'

thisModule.__index = thisModule
function thisModule.__newindex(t, k, v)
	error("attempt to update a read-only table", 2)
end

-- @todo - type check
-- {position, angle, scale, origin}
local function new(arg)
--	assert(type(x) == 'number', [[argument1 x must be 'number' type, not ']]..type(x)..[[' type]])
--	assert(type(y) == 'number', [[argument2 y must be 'number' type, not ']]..type(y)..[[' type]])
	
	local arg = arg or {}
	
	local structure = {}
	structure.position = arg.position or math.point()
	structure.angle = arg.angle or 0
	structure.scale = arg.scale or math.point(1, 1)
	structure.origin = arg.origin or math.point()
	
	return setmetatable(structure, thisModule)
end

--function thisModule:clone()
	
--end

--function thisModule:unpack()
	
--end

--function thisModule:__tostring()
	
--end

--function thisModule.__eq(a, b)
	
--end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})