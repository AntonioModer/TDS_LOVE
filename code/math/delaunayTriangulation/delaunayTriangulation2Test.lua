local thisModule = {}

local Delaunay = require("code.math.delaunayTriangulation.delaunayTriangulation2")
local Vertex    = Delaunay.Vertex

local points = {}

-- Creating 10 random points
--for i = 1, 100 do
--	points[i] = Point(math.random() * 1000, math.random() * 1000)
--end

---------------- small in big
-- big
points[#points+1] = Vertex(100, 100)
points[#points+1] = Vertex(200*5, 100)
points[#points+1] = Vertex(200*5, 200*5)
points[#points+1] = Vertex(100, 200*5)
-- small
--points[#points+1] = Vertex(150, 150)
--points[#points+1] = Vertex(250, 150)
--points[#points+1] = Vertex(250, 250)
--points[#points+1] = Vertex(150, 250)

points[#points+1] = Vertex(101, 500)						-- test
-----------------------------

local timer = {}
timer.start = love.timer.getTime()

-- Triangulating de convex polygon made by those points
local triangles = Delaunay.Triangulate(points)

timer.result = love.timer.getTime() - timer.start
print("Delaunay.triangulate time:", timer.result)
print("Delaunay.triangulate triangles:", #triangles)

local function triangleGetCenter(triangle)
  local x = (triangle.v0.x + triangle.v1.x + triangle.v2.x) / 3
  local y = (triangle.v0.y + triangle.v1.y + triangle.v2.y) / 3
  return x, y
end
-- удаляем треугольники из дырки
for i, triangle in ipairs(triangles) do
	local x, y = triangleGetCenter(triangle)
	if math.pelevesque.collisions.isPointInPolygon(x, y, {150, 150, 250, 150, 250, 250, 150, 250}) then
		triangles[i] = false
	end
end

function thisModule:draw()
	
	love.graphics.setLineWidth(3)
--	love.graphics.setLineJoin('none')

	for i, triangle in ipairs(triangles) do
		if triangle ~= false then
			love.graphics.setColor(0, 255, 0, 255)
			love.graphics.polygon("fill", triangle.v0.x, triangle.v0.y, triangle.v1.x, triangle.v1.y, triangle.v2.x, triangle.v2.y)
			
			love.graphics.setColor(0, 0, 255, 255)
			love.graphics.polygon("line", triangle.v0.x, triangle.v0.y, triangle.v1.x, triangle.v1.y, triangle.v2.x, triangle.v2.y)
		end
	end
	
	love.graphics.setLineWidth(1)
--	love.graphics.setLineJoin('miter')	
end

return thisModule