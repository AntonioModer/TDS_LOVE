--[[------------------------------------------------------------------------------------------------
	@version 0.0.1
	* отрезок, Line (or Line segment)
	@todo
		- commented methods
		- documentation
		+ координаты точек не должы быть равны
		-? везде заменить код на этот тип
		-?NO draw
			-? новый тип в graphics
		+ новый тип таблицы
		+ имеет 2 точки, 4 координаты
		-? как vector4 в GLSL (vec4)
		* это не вектор
		@todo 1 - найти готовые библиотеки		
--]]------------------------------------------------------------------------------------------------

local thisModule = {}
thisModule._TABLETYPE = 'line'

thisModule.__index = thisModule
function thisModule.__newindex(t, k, v)
	error("attempt to update a read-only table", 2)
end

local function new(point1, point2)
	if type(point1) == 'nil' and type(point2) == 'nil' then                                                                    -- defaults
		point1 = math.point()
		point2 = math.point(1, 0)
	else
		assert(type(point1) == 'point', [[argument1 point1 must be 'point' type, not ']]..type(point1)..[[' type]])
		assert(type(point2) == 'point', [[argument2 point2 must be 'point' type, not ']]..type(point2)..[[' type]])
		assert(point1 ~= point2, "points of line are same")
	end
	
	return setmetatable({point1 = point1, point2 = point2}, thisModule)
end

function thisModule:clone()
	return new(self.point1, self.point2)
end

--function thisModule:unpack()
--	return self.x, self.y
--end

--function thisModule:__tostring()
--	return "(".. self.x ..", ".. self.y ..")"
--end

--function thisModule.__eq(a, b)
--	return a.x == b.x and a.y == b.y
--end

--function thisModule:draw()
	
--end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})