-- require the module
local poly2tri = assert(package.loadlib('code/math/poly2tri/poly2tri-x64', 'luaopen_poly2tri'))()

local vertices = {0, 0, 0, 200, 200, 200, 200, 0}
local holes = {
  {10, 10, 50, 10, 10, 50},
  {100, 10, 175, 10, 175, 100, 100, 50, 10, 100},
  {10, 175, 150, 100, 190, 175}
}
test.triangles = poly2tri.triangulate(vertices, holes)