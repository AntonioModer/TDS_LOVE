--[[
version 0.0.12
@help 
	+ https://love2d.org/forums/viewtopic.php?f=5&t=81229
@todo 
	-+ сначала научится работать с одной ячейкой
		@todo 1.1 - тестировать отдельно в "F:\Documents\MyGameDevelopment\LOVE\LIB\pathfinding\navMeshTest"
		-+ разобраться с дырками
			-+  тестировать отдельно в "F:\Documents\MyGameDevelopment\LOVE\LIB\pathfinding\CutHolesTest"
			-+ https://github.com/AntonioModer/mlib#mlibpolygonispolygoninside
				-? или Hardoncollider
		-+ разобраться с clipper
			-+ тестировать отдельно в "F:\Documents\MyGameDevelopment\LOVE\LIB\pathfinding\clipperTest"
			+ https://github.com/AntonioModer/clipperTest
			+BUG1 почему исчезает половинка, если делить с права на лево? (смотри скриншет бага)
				+ потому что существует разница между нижней границей вернего полигона и верхней границей нижнего полигона, т.е. их AABB формы не пересекаются
			+BUG2 если obstacle ниже cell, то нулевой результат
			+ если cell поделили пополам (clipper.result:size() > 1)
				+ результат должен быть отдельной простой таблицей, чтобы меньше путаницы
		-+ при нажатии на кнопку мыши запоминаем вырезаную cell, и уже вырезаем в ней в дальнейшем
			-+ когда hole
	- алгоритм
		- нужно разбить мир на матрицу
		- каждая ячейка - это полигон
		- use Clipper
		- cut holes if need
		-------------------
		-?NO а нужно ли вообще сразу вырезать? но как-нибудь нужно разобраться с этим!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			- если можно сделать Делахой-триангуляцию и убрать из pathfinding полигоны-дырки
				- не удо6но, т.к. нужно возиться с каждым полигоном и будет запутанный код; и каждый раз нужно полностью все препятсвия обрабатывать при внесении нового препятствия
					-? тогда работать только с выпуклыми полигонами
						- не поможет
	-+ рефакторинг кода
--]]

local thisModule = {}

------------------------- cell
do
	thisModule.cell = {}
	thisModule.cell.polygons = {}
	thisModule.cell.polygons[1] = {
		100, 100,
		1000, 100,
		1000, 1000,
		100, 1000
	}
	thisModule.cell.clipperPolygons = {}
end

-------------------------- obstacle
do
	thisModule.obstacle = {}
	thisModule.obstacle.polygons = {}
	thisModule.obstacle.polygons[1] = {
		150, 150,
		250, 150,
		250, 250,
		150, 250
	}
	thisModule.obstacle.clipperPolygons = {}
end

-------------------------- result
do
	thisModule.result = {}
	thisModule.result.polygons = {}
	function thisModule:refreshResultFromClipperResult()
		thisModule.result.polygons = {}
		for polyN=1, thisModule.clipper.result:size() do
			local clipperPolygon = thisModule.clipper.result:get(polyN)
			thisModule.result.polygons[polyN] = {}
			for pointN=1, clipperPolygon:size() do
				table.insert(thisModule.result.polygons[polyN], tonumber(clipperPolygon:get(pointN).x))
				table.insert(thisModule.result.polygons[polyN], tonumber(clipperPolygon:get(pointN).y))
			end		
		end	
	end
end

-------------------------- clipper
thisModule.clipper = require("code.math.clipper.clipper")

table.insert(thisModule.cell.clipperPolygons, thisModule.clipper:newPolygon(thisModule.cell.polygons[1]))
table.insert(thisModule.obstacle.clipperPolygons, thisModule.clipper:newPolygon(thisModule.obstacle.polygons[1]))

thisModule.clipper.result = thisModule.clipper:clip(thisModule.clipper:newPolygonsList(thisModule.cell.clipperPolygons), thisModule.clipper:newPolygonsList(thisModule.obstacle.clipperPolygons))
thisModule:refreshResultFromClipperResult()

function thisModule:update(dt)
	
	----------------------------------------------------------------------------------------- update obstacle
	-------------------------- двигаем obstacle
	local x, y = camera:toWorld(love.mouse.getPosition())
	thisModule.obstacle.polygons[1] = {
		x, y,
		x+250, y,
		x+250, y+250,
		x, y+250
	}
	thisModule.obstacle.polygons[2] = {
		0, 0,
		1, 0,
		1, 1,
		0, 1
	}	
	--------------------------- clipper
	if true then
	--	thisModule.obstacle.clipperPolygon:clean()															-- работает не так как я ожидал
		thisModule.obstacle.clipperPolygons[1] = thisModule.clipper:newPolygon(thisModule.obstacle.polygons[1])
		thisModule.obstacle.clipperPolygons[2] = thisModule.clipper:newPolygon(thisModule.obstacle.polygons[2])
		thisModule.clipper.result = thisModule.clipper:clip(thisModule.clipper:newPolygonsList(thisModule.cell.clipperPolygons), thisModule.clipper:newPolygonsList(thisModule.obstacle.clipperPolygons))
		
--		thisModule.clipper.result = thisModule.clipper.result:clean()
--		thisModule.clipper.result = thisModule.clipper.result:simplify()
		
		thisModule:refreshResultFromClipperResult()
	end
	
end

function thisModule:mousePressed(x, y, button)
	if button == 1 then
		-- при нажатии на кнопку мыши запоминаем вырезаную cell, и уже вырезаем в ней в дальнейшем
		thisModule.cell.polygons = thisModule.result.polygons
		do
			thisModule.cell.clipperPolygons = {}
			for i, polygon in ipairs(thisModule.cell.polygons) do
				table.insert(thisModule.cell.clipperPolygons, thisModule.clipper:newPolygon(polygon))
			end
--			print(#thisModule.cell.polygons)
		end
	end	
end

function thisModule:draw()
	
	-- cell.polygons
	if true then
		love.graphics.setColor(0, 255, 0, 255)
		for i, polygon in ipairs(thisModule.cell.polygons) do
			local triangles
			local ok, out = pcall(love.math.triangulate, polygon)
			if ok then
				triangles = out
				for i, triangle in ipairs(triangles) do
					love.graphics.polygon("fill", triangle)
				end					
			else
				love.graphics.print('cant draw(triangulate) cell.polygons', 0, 20, 0, 1, 1)
			end
		end
	end	

	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle('rough')
	love.graphics.setLineJoin('none')
	------------------------------------------------------ thisModule.result.polygons
	if true then
		love.graphics.setColor(0, 0, 255, 255)
		for i, polygon in ipairs(thisModule.result.polygons) do
			local triangles
			local ok, out = pcall(love.math.triangulate, polygon)
			if ok then
				triangles = out
				for i, triangle in ipairs(triangles) do
					love.graphics.polygon('line', triangle)
				end					
			else
				love.graphics.print('cant draw(triangulate) result.polygons', 0, 0, 0, 1, 1)
			end
		end
	end
	love.graphics.setLineStyle('smooth')
	love.graphics.setLineWidth(1)
	
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.polygon('fill', thisModule.obstacle.polygons[1])
end

return thisModule