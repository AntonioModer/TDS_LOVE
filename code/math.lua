--[[
	@version 0.0.3
	@todo 
		-+ пересечение фигур
		-+ vector
			- тесты: рисовать векторы, чтобы наглядно понимать как работают функции
				@todo 1 - рисовать в math.test.draw()
			-?NO свой vector
				-? использовать code.Class
					- усовершенствовать Class module
						- нужно чтобы объекты не сохранялись в Классе
			+YES или использовать или доделать hump.vector
			-? оптимизация: на С с помощью luajit.FFI
				@help https://bitbucket.org/rude/love/issues/926/implement-native-vector-functionality
				@help https://github.com/slime73/hump/blob/master/vector.lua
		-+ point
		-? AABB querying
		-? matrix
		- изучить стороние библиотеки
			- C# math
--]]

--[[
C - Data Type

Type 			Storage size 		Value range 				Precision
double 			8 byte 				2.3E-308 to 1.7E+308 		15 decimal places
-------------------------------------------------------------------------------------
Lua number = double

max number is 1.79e+308
min number is 9.9e-323

2.001 - 2 = 0.00099999999999989      -- ЭТО ПИЗДЕЦ !!!
----------------------------------------
print(math.huge == 1.79e+309)	--> true
--]]

--[[
print(string.format("%e", 100000000000000))   --> 1.000000e+014
print(string.format("%f", 100000000000000))   --> 100000000000000.000000

print(string.format("%e", 100000000000000.5)) --> 1.000000e+014
print(string.format("%f", 100000000000000.5)) --> 100000000000000.500000
--]]

--[[
	* simple FIFO example
		tab = {}
		table.insert(tab, 1)																				-- добавляет значение в конец таблицы tab
		var = table.remove(tab, 1)																			-- Удаляет из table элемент в позиции 1, сдвигая вниз остальные элементы, если это необходимо. Возвращает значение удаленного элемента
--]]

--[[
-- examples
if math.fmod(x, 16) ~= 0 then																		-- координата x кратна 16 (деление без остатка)
end

a % b == a - math.floor(a/b)*b																		-- остаток от деления
x % 1       -- дает дробную часть x
x - x%1     -- дает целую часть x
x - x%0.1   -- дает дробную часть x с аналогичными десятичными знаками после запятой
--]]

--[[
CONSTANTS
--]]
-- не нужна -- math.DIAG_FACTOR = 0.70710678118654752440084436210485                 -- DIAGONAL_FACTOR = math.dist(0,0, 1,1)/2 = (2^0.5)/2 = math.vecRot(0,0, 1, math.rad(45)) = cos(45) = sin(45)

local math = math

-- http://stackoverflow.com/questions/11548062/how-to-generate-random-float-in-lua
function math.randomFloat(lower, greater)
    return lower + math.random() * (greater - lower)
end

--[[
version 1.0.1
@help 
	+ возвращает число с указанной точность, returns number with a specified accuracy
	+ return lower number
	+ также смотри math.stickToEdge()
EXAMPLE:
	print(nSA(0.123456789, 1))				--> 0
	print(nSA(0.123456789, 0.1))			--> 0.1
	print(nSA(0.123456789, 0.000000001))	--> 0.123456789
	print(nSA(31, 64))						--> 0
	print(nSA(65, 64))						--> 64
	print(math.nSA(10.123, 0))				--> nan
--]]
function math.nSA(x, accuracy, rounding)																		-- number specified accuracy
	if accuracy == 0.000000001 then
		accuracy = 0.0000000001
	end
	if accuracy == 0 then																						-- исключаем nan
		return 0
	end
	x = x - (x % (accuracy or 0.000000001))
	if rounding then
		-- TODO ...
	end
	return x
end

-- return the integral part of x --
-- examples:
--  print(nIP(0.23))				--> 0
function math.nIP(x)
	local integral, fractional = math.modf(x)
	return integral
end

-- return the fractional part of x --
-- examples:
--  print(nFP(0.23))				--> 0.23
function math.nFP(x)
	local integral, fractional = math.modf(x)
	return fractional
end

-- определяет четное число или нет
-- return true/false
function math.even(x)
    return x%2 == 0
end

-- Returns 1 if number is positive, -1 if it's negative, or 0 if it's 0.
function math.sign(n)
	return n>0 and 1 or n<0 and -1 or 0 
end

--[[
version 2.0.0
@help 
	+!!! не нужна, вместо этой функции использовать math.nSA()
	+ stick to edge
	+ return lower (left-buttom) coordinate
	+ coordinate - x or y
--]]
function math.stickToEdge(coordinate, step)
	-- v1
--	local math = math
--	if math.fmod(coordinate, step) ~= 0 then																	-- координата кратна step (деление без остатка)
--		if (math.ceil(coordinate/step)*step) < step then
--			return (math.ceil(coordinate/step)*step)-step
--		else
--			return (math.floor(coordinate/step)*step)
--		end
--	end
--	return coordinate

	-- v2
--	return math.floor( coordinate / step ) * step

	-- v3	
	return coordinate - (coordinate % step)
end

-- Returns the distance between two points. 
function math.dist(x1, y1, x2, y2)
--	return ((x2-x1)^2+(y2-y1)^2)^0.5
--	return math.sqrt((x2-x1)^2+(y2-y1)^2)
	return math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1))
end

--################################[ angles ]########################################

--[[
examles:

	1 deg = 0.01745329251994329576923690768489 rad = (Pi/180)
	1 rad = 57.295779513082320876798154814105  deg = (180/Pi)
	
	rad to deg: 
		rad / 0.01745329251994329576923690768489
		rad * 57.295779513082320876798154814105
	deg to rad: 
		deg * 0.01745329251994329576923690768489
		deg / 57.295779513082320876798154814105
--]]

-- Returns the angle between two points (rad).
function math.angle(x1,y1, x2,y2)
	return math.atan2(y2-y1, x2-x1)
end

-- "Lua-angle degrees" to "360-angle degrees" (degToBDeg - Lua-degrees to babylons-degrees)
-- test
--  math.degToBDeg(math.deg(math.angle(Player.physBody:getX(), Player.physBody:getY(), mouseMapX, mouseMapY)))	
function math.degToBDeg(argDeg)
	if argDeg == 0 then return argDeg end	
	argDeg = argDeg*-1
	if argDeg < 0 then
		return (360+argDeg)
	else
		return argDeg
	end	
end
-- "360-angle degrees" to "Lua-angle degrees" (bDegToDeg - babylons-degrees to Lua-degrees)
-- test 
--  math.bDegToDeg(math.degToBDeg(math.deg(math.angle(Player.physBody:getX(), Player.physBody:getY(), mouseMapX, mouseMapY))));
function math.bDegToDeg(argDeg)
	if argDeg == 0 then return argDeg end	
	if argDeg > 180 then
		return (argDeg-360)*-1
	else
		return argDeg*-1
	end	
end 

-- "Lua-angle radians" to "360-angle degrees" (radToBDeg - Lua-radians to babylons-degrees)
-- test
--  math.radToBDeg(math.angle(Player.physBody:getX(), Player.physBody:getY(), mouseMapX, mouseMapY))
-- @todo -+ ограничитель 0...360
function math.radToBDeg(argRad)
--	argRad = math.deg(argRad)
--	if argRad == 0 then return argRad end	
--	argRad = argRad*-1
--	if argRad < 0 then
--		return (360+argRad)
--	else
--		return argRad
--	end
	
--	local v = math.vector(1, 0)
--	v:rotateInplace(argRad)
--	argRad = math.deg(v:angleTo())	
	
----	argRad = math.deg(argRad)
--	if argRad < 0 then
--		argRad = argRad * -1
--	end
----	if math.abs(argRad) > 360 then
--		local integral, fractional = math.modf(argRad/360)
--		argRad = 360 * fractional
----		print(fractional)
----	end	

	return -(math.deg(argRad))%360
end
-- "360-angle degrees" to "Lua-angle radians" (bDegToRad - babylons-degrees to Lua-radians)
-- test 
--  math.bDegToRad(math.degToBDeg(math.deg(math.angle(Player.physBody:getX(), Player.physBody:getY(), mouseMapX, mouseMapY))));
function math.bDegToRad(argDeg)
	if argDeg == 0 then return argDeg end	
	if argDeg > 180 then
		return math.rad((argDeg-360)*-1)
	else
		return math.rad(argDeg*-1)
	end	
end 

-- return x from (0, 0); dir in deg
function math.lengthdirX(len, dir)
	return math.cos((dir*math.pi)/180)*len
end
-- return y from (0, 0); dir in deg
function math.lengthdirY(len, dir)
	return math.sin((dir*math.pi)/180)*len
end

-- находит координаты конца повернутого вектора с точкой поворота в начале вектора
-- angle - radians
-- return xEnd, yEnd
-- test: print(math.vecRot(0,0, 100, 0))
function math.vecRot(x,y, length, angle) 
	local xEndP = math.lengthdirX(length, math.deg(angle))											-- end 
	local yEndP = math.lengthdirY(length, math.deg(angle))
	
	return (x+xEndP), (y+yEndP)
end

--###################################[ колизия ]###################################################


-- колизия точки к кругом
function math.pointIncircle(px,py, cx,cy, r) 
	return (px-cx)^2+(py-cy)^2 < r^2		
	-- or -- return (px-cx)^2+(py-cy)^2 <= r^2														-- if '=' - то на круге
end

-- pointWithinShape(shape, x, y)
    -- returns true if (x,y) lays within the bounds of the given shape. Shape defined by an array of 0 to n {x=n, y=y} values. 
    -- It generally defers to the other other functions in the file to do the heavy lifting (CrossingsMultipyTest(...), pointWithinLine(...), boundingBox(...) and colinear(...)) 

-- boundingBox(box, x, y)
    -- returns true if the given point is inside the box defined by two points (in the same format taken by pointWithinShape(...)). 

-- colinear(line, x, y, e)
    -- returns true if the given point lies on the infinite line defined by two points (again, in the same format taken by pointWithinShape(...)) 
    -- e is optional, if given it controls how close (x,y) must be to the line to be considered colinear. it defaults to 0.1 

-- pointWithinLine(line, x, y, e)
    -- returns true if the given point lies on the finite line defined by two points (again, in the same format taken by pointWithinShape(...)) 
    -- e is optional, if given it controls how close (x,y) must be to the line to be considered within the line. it defaults to 0.66 

-- crossingsMultiplyTest(polygon, x, y)
    -- returns true if the given point lies within the area of the polygon defined by three or points (again, in the same format taken by pointWithinShape(...)) 
    -- (it is based on code from Point in Polygon Strategies) 

-- getIntersect( points )
    -- returns the x,y coordinates of the intersect, same format taken by pointWithinShape(...) 
    -- (Added by Bambo - You will need the checkIntersect from the "General math" snippet for it to work) 

function math.pointWithinShape(shape, tx, ty)
    if #shape == 0 then
        return false
    elseif #shape == 1 then
        return shape[1].x == tx and shape[1].y == ty
    elseif #shape == 2 then
        return math.pointWithinLine(shape, tx, ty)
    else
        return math.crossingsMultiplyTest(shape, tx, ty)
    end
end

function math.boundingBox(box, tx, ty)
    return  (box[2].x >= tx and box[2].y >= ty)
        and (box[1].x <= tx and box[1].y <= ty)
        or  (box[1].x >= tx and box[2].y >= ty)
        and (box[2].x <= tx and box[1].y <= ty)
end

function math.colinear(line, x, y, e)
    e = e or 0.1
    m = (line[2].y - line[1].y) / (line[2].x - line[1].x)
    local function f(x) return line[1].y + m*(x - line[1].x) end
    return math.abs(y - f(x)) <= e
end

function math.pointWithinLine(line, tx, ty, e)
    e = e or 0.66
    if math.boundingBox(line, tx, ty) then
        return math.colinear(line, tx, ty, e)
    else
        return false
    end
end

-------------------------------------------------------------------------
-- The following function is based off code from
-- [ http://erich.realtimerendering.com/ptinpoly/ ]
--
--[[
 ======= Crossings Multiply algorithm ===================================
 * This version is usually somewhat faster than the original published in
 * Graphics Gems IV; by turning the division for testing the X axis crossing
 * into a tricky multiplication test this part of the test became faster,
 * which had the additional effect of making the test for "both to left or
 * both to right" a bit slower for triangles than simply computing the
 * intersection each time.  The main increase is in triangle testing speed,
 * which was about 15% faster; all other polygon complexities were pretty much
 * the same as before.  On machines where division is very expensive (not the
 * case on the HP 9000 series on which I tested) this test should be much
 * faster overall than the old code.  Your mileage may (in fact, will) vary,
 * depending on the machine and the test data, but in general I believe this
 * code is both shorter and faster.  This test was inspired by unpublished
 * Graphics Gems submitted by Joseph Samosky and Mark Haigh-Hutchinson.
 * Related work by Samosky is in:
 *
 * Samosky, Joseph, "SectionView: A system for interactively specifying and
 * visualizing sections through three-dimensional medical image data",
 * M.S. Thesis, Department of Electrical Engineering and Computer Science,
 * Massachusetts Institute of Technology, 1993.
 *
 --]]

--[[ Shoot a test ray along +X axis.  The strategy is to compare vertex Y values
 * to the testing point's Y and quickly discard edges which are entirely to one
 * side of the test ray.  Note that CONVEX and WINDING code can be added as
 * for the CrossingsTest() code; it is left out here for clarity.
 *
 * Input 2D polygon _pgon_ with _numverts_ number of vertices and test point
 * _point_, returns 1 if inside, 0 if outside.
 --]]
function math.crossingsMultiplyTest(pgon, tx, ty)
    local i, yflag0, yflag1, inside_flag
    local vtx0, vtx1
   
    local numverts = #pgon

    vtx0 = pgon[numverts]
    vtx1 = pgon[1]

    -- get test bit for above/below X axis
    yflag0 = ( vtx0.y >= ty )
    inside_flag = false
   
    for i=2,numverts+1 do
        yflag1 = ( vtx1.y >= ty )
   
        --[[ Check if endpoints straddle (are on opposite sides) of X axis
         * (i.e. the Y's differ); if so, +X ray could intersect this edge.
         * The old test also checked whether the endpoints are both to the
         * right or to the left of the test point.  However, given the faster
         * intersection point computation used below, this test was found to
         * be a break-even proposition for most polygons and a loser for
         * triangles (where 50% or more of the edges which survive this test
         * will cross quadrants and so have to have the X intersection computed
         * anyway).  I credit Joseph Samosky with inspiring me to try dropping
         * the "both left or both right" part of my code.
         --]]
        if ( yflag0 ~= yflag1 ) then
            --[[ Check intersection of pgon segment with +X ray.
             * Note if >= point's X; if so, the ray hits it.
             * The division operation is avoided for the ">=" test by checking
             * the sign of the first vertex wrto the test point; idea inspired
             * by Joseph Samosky's and Mark Haigh-Hutchinson's different
             * polygon inclusion tests.
             --]]
            if ( ((vtx1.y - ty) * (vtx0.x - vtx1.x) >= (vtx1.x - tx) * (vtx0.y - vtx1.y)) == yflag1 ) then
                inside_flag =  not inside_flag
            end
        end

        -- Move to the next pair of vertices, retaining info as possible.
        yflag0  = yflag1
        vtx0    = vtx1
        vtx1    = pgon[i]
    end

    return  inside_flag
end

function math.checkDir(pt1, pt2, pt3) 
	return math.sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) 
end
-- Checks if two line segments intersect. Line segments are given in form of ({x,y},{x,y}, {x,y},{x,y}).
function math.checkIntersect(l1p1, l1p2, l2p1, l2p2)
    return (math.checkDir(l1p1,l1p2,l2p1) ~= math.checkDir(l1p1,l1p2,l2p2)) and (math.checkDir(l2p1,l2p2,l1p1) ~= math.checkDir(l2p1,l2p2,l1p2))
end
-- Пересечение 2-х линий
function math.getIntersect( g1,h1,g2,h2, i1,j1,i2,j2 )
   
    local xk = 0
    local yk = 0
   
    if math.checkIntersect({x=g1, y=h1}, {x=g2, y=h2}, {x=i1, y=j1}, {x=i2, y=j2}) then
        local a = h2-h1
        local b = (g2-g1)
        local v = ((h2-h1)*g1) - ((g2-g1)*h1)

        local d = i2-i1
        local c = (j2-j1)
        local w = ((j2-j1)*i1) - ((i2-i1)*j1)

        xk = (1/((a*d)-(b*c))) * ((d*v)-(b*w))
        yk = (-1/((a*d)-(b*c))) * ((a*w)-(c*v))
    else
        xk,yk = 0,0
    end
    return xk, yk
end




-- Пересечение 2-х линий
-- Checks if two lines intersect (or line segments if seg is true)
-- Lines are given as four numbers (two coordinates)
-- example (за 0.002 сек) (Fixture:rayCast() за 0.001 сек):
-- for i=1, 1000 do
	-- math.findIntersect(5,0, 5,10, 0,5, 10,5, true, true)
-- end
function math.findIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y, seg1, seg2)
    local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
    local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
    local det,x,y = a1*b2 - a2*b1
    if det==0 then return false, "The lines are parallel." end
    x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
    if seg1 or seg2 then
        local min,max = math.min, math.max
        if seg1 and not (min(l1p1x,l1p2x) <= x and x <= max(l1p1x,l1p2x) and min(l1p1y,l1p2y) <= y and y <= max(l1p1y,l1p2y)) or
           seg2 and not (min(l2p1x,l2p2x) <= x and x <= max(l2p1x,l2p2x) and min(l2p1y,l2p2y) <= y and y <= max(l2p1y,l2p2y)) then
            return false, "The lines don't intersect."
        end
    end
    return x,y
end

math.pelevesque = {}
math.pelevesque.collisions = require("code.math.gamemathByPelevesque.collisions")

--[[ vector
	@todo 
		-? like in GLSL
		-? vector2
		-? vector4
--]]
math.vector = require("code.hump.vector")

math.point = require("code.math.point")

math.transform = require("code.math.transform")

math.line = require("code.math.line")

-- other #####################################################################################################

-----------------------------------------------------------------------------------------
--[[
version 1.1.1
pendulum
@help 
	+ 
@todo 
	- 
--]]

-- id - number of array
-- period - 0 or 1
-- rand - random?
function math.pendulumInit(selfTab, id, period, rand)
	if rand == true then
		period = math.random(0, 1)																	-- рандом: 0 или 1
	end
	
	-- определяем пи --
	if period == 1 then
		period = -math.pi
	end
	
	if selfTab._mathPendulumPeriod == nil then
		selfTab._mathPendulumPeriod = {}
	end
	selfTab._mathPendulumPeriod[id] = period																-- текущий период колебания	
end

-- return ( angle in deg )
-- speedRot: 1...
-- dotime = 0.00001
-- repeat 100
    -- dotime = 0.0007
-- angleStart - начальный угол, deg
-- angleMax - отклонение маятника, deg
-- example: math.rad(math.pendulumStep(Player, 1, 180, 360, 10))
function math.pendulumStep(selfTab, id, angleStart, angleMax, speedRot)
	local speedRot = speedRot/1000																	-- скорость вращения	
	local angleMax = angleMax/2
	
	-- зацикливание периода колебания --
	selfTab._mathPendulumPeriod[id] = selfTab._mathPendulumPeriod[id]+speedRot
	if selfTab._mathPendulumPeriod[id] > math.pi then
		selfTab._mathPendulumPeriod[id] = -math.pi
	end

	return angleStart+math.sin(selfTab._mathPendulumPeriod[id])*angleMax
end
--------------------------------------------------------------------------------------------

-- tests ####################################################################################
math.test = {}
--math.test.on = true
math.test.vector = {}
math.test.vector.v1 = math.vector(100, 0)
math.test.vector.v2 = math.vector(100, 0)
math.test.vector.v3 = math.vector(100, 0)
--print(type(math.test.vector.v1))

math.test.point = math.point(1, 0)
--math.test.point.z = 2
--print(type(math.test.point), math.test.point)

math.test.line = math.line(math.test.point, math.point(0, 0))
--print(type(math.test.line), math.test.line.point2.x)

function math.test:draw()
	if not math.test.on then return false end
	
	local mpx, mpy = love.mouse.getPosition()
	local sccx, sccy = config.window.width/2,config.window.height/2
	
	-- vector
	local v1, v2, v3 = self.vector.v1, self.vector.v2, self.vector.v3
	-- angles
	
	-- @help в стандартной системе Lua:
	--   по часовой стрелке: увеличение угла
	--   против часовой стрелке: уменьшение угла
	
	
	if love.mouse.isDown(1) then
		self.vector.v1 = math.vector(100, 0):rotated(math.angle(sccx, sccy, mpx, mpy))
	end	
	love.graphics.setColor(200, 0, 0, 255)
	love.graphics.line(sccx, sccy, sccx+v1.x, sccy+v1.y)	
	
--	v2 = math.vector(100, 0)
--	v2 = math.vector(100, 0):rotated(math.angle(sccx, sccy, mpx, mpy))  -- to mouse
--	v2 = -v1                                                -- v1 в обратном направлении
	v2 = v1:rotated(math.rad(175))                          -- v1 в обратном направлении
--	v2 = v2:mirrorOn(v1)  -- непонял
--	v2 = v2:projectOn(v1)
	love.graphics.setColor(0, 200, 0, 255)
	love.graphics.line(sccx, sccy, sccx+v2.x, sccy+v2.y)
	
	-- @todo 1 -+ проблема: если применять силы ровно противоположную, то тело не разворачивается
	-- v1 - это направление игрока
	-- v2 - это направление ?
	-- v3 - это направление applyForce()
--	print(math.radToBDeg(v1:angleTo(v2)))
	local diffA = math.radToBDeg(v1:angleTo(v2))
	if diffA > 170 then
		
		v3 = v1:rotated(math.rad(-diffA-20))
	end
	
	love.graphics.setColor(0, 0, 200, 255)
	love.graphics.line(sccx, sccy, sccx+v3.x, sccy+v3.y)	
	
	local text = ''
	love.graphics.setColor(200, 0, 0, 255)
	love.graphics.print(text, sccx, sccy-200)
	
	
--	love.graphics.circle('fill', sccx, sccy, 30)
end
