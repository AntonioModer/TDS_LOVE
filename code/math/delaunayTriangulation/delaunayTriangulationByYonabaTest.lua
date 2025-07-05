--[[
version 0.0.1
@todo 
	+ https://github.com/Yonaba/delaunay/issues/3
--]]

local thisModule = {}

local Delaunay = require("code.math.delaunayTriangulation.byYonaba.delaunay")
local Point    = Delaunay.Point

local points = {}

-- Creating 10 random points
--for i = 1, 100 do
--	points[i] = Point(math.random() * 1000, math.random() * 1000)
--end

---------------- small in big
-- big
points[#points+1] = Point(100, 100)
points[#points+1] = Point(200*5, 100)
points[#points+1] = Point(200*5, 200*5)
points[#points+1] = Point(100, 200*5)
-- small
points[#points+1] = Point(150, 150)
points[#points+1] = Point(250, 150)
points[#points+1] = Point(250, 250)
points[#points+1] = Point(150, 250)

--points[#points+1] = Point(100, 520)

--points[#points+1] = Point(102, 500)						-- test
-----------------------------

local timer = {}
timer.start = love.timer.getTime()

-- Triangulating de convex polygon made by those points
local triangles
for i=1, 1000 do
	triangles = Delaunay.triangulate(points)
end

timer.result = love.timer.getTime() - timer.start
print("Delaunay.triangulate time:", timer.result)
print("Delaunay.triangulate triangles:", #triangles)

-- удаляем треугольники из дырки
for i, triangle in ipairs(triangles) do
	local x, y = triangle:getCenter()
	if math.pelevesque.collisions.isPointInPolygon(x, y, {150, 150, 250, 150, 250, 250, 150, 250}) then
		triangles[i] = false
	end
end

function thisModule:draw()
--	love.graphics.setLineStyle('rough')
	love.graphics.setLineWidth(3)
--	love.graphics.setLineJoin('none')
	
	for i, triangle in ipairs(triangles) do
		if triangle ~= false then
			love.graphics.setColor(0, 255, 0, 255)
			love.graphics.polygon("fill", triangle.p1.x, triangle.p1.y, triangle.p2.x, triangle.p2.y, triangle.p3.x, triangle.p3.y)	
			
			love.graphics.setColor(0, 0, 255, 255)
			love.graphics.polygon("line", triangle.p1.x, triangle.p1.y, triangle.p2.x, triangle.p2.y, triangle.p3.x, triangle.p3.y)
			love.graphics.circle("fill", triangle.p1.x, triangle.p1.y, 5)
			love.graphics.circle("fill", triangle.p2.x, triangle.p2.y, 5)
			love.graphics.circle("fill", triangle.p3.x, triangle.p3.y, 5)
		end
	end
	
	love.graphics.setLineWidth(1)
--	love.graphics.setLineJoin('miter')
end

return thisModule