--[[
version 0.0.25
@help 
	+ 
@todo 
	- внедрить этот модуль в:
		- world
		- worldEditor
		@todo 1.1 -debugSystem
			- menu
			- draw
	+ draw nodes
		+ debug
	- рефакторинг API
	-+ поиск пути по классу Graph
		-+ заново вспоминать
		-+ path
			- перенести в класс
			-NO findPath:aStar(): новый аргумент path
			+ как лучше его представлять
				+NO простым перебором координат x,y
				+ точками
					+ {{0, 0}, {0, 0}, ...}
		+ пока делать из того что есть, черновой вариант. А потом уже совершенствовать
		+ F:\Gamedev\AI\MotionplaningAndPathfinding\изучаю заново
		+ F:\Documents\MyGameDevelopment\LOVE\LIB\pathfinding\1
		-+ priority queue (Очередь с приоритетом) [wiki](https://ru.wikipedia.org/wiki/%D0%9E%D1%87%D0%B5%D1%80%D0%B5%D0%B4%D1%8C_%D1%81_%D0%BF%D1%80%D0%B8%D0%BE%D1%80%D0%B8%D1%82%D0%B5%D1%82%D0%BE%D0%BC_%28%D0%BF%D1%80%D0%BE%D0%B3%D1%80%D0%B0%D0%BC%D0%BC%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%29)
			- фибоначиева куча - самая быстрая, сделать её
			+ pqOpen.lua
				+ переместить в Класс
			- binary heap
				- https://github.com/Yonaba/Binary-Heaps
			- F:\Documents\MyGameDevelopment\LOVE\LIB\table
		+ listClosed
			+ переместить в Класс
		+- findPath()
			- тестировать
				+ если удалить ноды и искать путь
			+ после поиска пути, в нодах в node.parent остаются ссылки на другие ноды; нужно удалять (node.parent = false), не перебирая полностью все ноды
				+? сделать node.parent слабой ссылкой; и каждый раз проверять node.destroyed
				-?NO напрямую удалять, но как?
			-+ рефакторинг кода
			+ debug draw findPath
--]]

local thisModule = {}
thisModule.graphs = {}																									-- key is <number>; value is <object>
thisModule.debug = {}
thisModule.debug.draw = {}
thisModule.debug.draw.pathfinding = {}
thisModule.debug.draw.pathfinding.on = false
thisModule.debug.draw.path = {}
thisModule.debug.draw.path.on = true

function thisModule:draw(pathfinding)
	-- не нужно, если "Node имеет component.entity"
--	for i, graph in ipairs(self.graphs) do
--		graph:draw(pathfinding)
--	end

	if not (debug:isOn() and debug.draw:isOn()) then return nil end
	if self.debug.draw.path.on then
		love.graphics.setColor(0, 0, 200, 255)
		self:drawPath(self.path)
	end
end

function thisModule:drawPath(path)
	if not path then return false end
	love.graphics.setLineStyle('smooth')
	love.graphics.setLineWidth(5)
--	love.graphics.setLineJoin('none')	

--	love.graphics.line(path)																	-- simple and fast
	
	-- constructPath(..., version = 2) 
	for i=#path, 1, -1 do
		if i > 1 then
			require("code.graphics"):drawArrow(path[i][1], path[i][2], path[i-1][1], path[i-1][2], 30, 15)
		end
	end
	love.graphics.setLineWidth(1)
end

thisModule.closed = require('code.classes.AI.Pathfinding.ListClosed'):newObject()
thisModule.open = require('code.classes.AI.Pathfinding.PriorityQueueOpen'):newObject()

function thisModule:findH(node, endNode)
	return math.dist(node:getX(),node:getY(), endNode:getX(),endNode:getY()) 
end

function thisModule:findG(node1, node2)
	return math.dist(node1:getX(),node1:getY(), node2:getX(),node2:getY()) 
end

--[[
@help 
	+ clearNodeParent не сильно нужно
@todo 
	- некрасиво, что передается и изменяется таблица path
--]]
function thisModule:constructPath(path, startNode, endNode, version, clearNodeParent)
	version = version or 2
	if clearNodeParent == nil then clearNodeParent = false end
	
	if version == 1 then
		-- {x, y, x1, y2, ...}
		path[#path+1] = endNode:getX()
		path[#path+1] = endNode:getY()
		
		local node = endNode
		while node ~= startNode do
			node = node.weakTable.parent
			path[#path+1] = node:getX()
			path[#path+1] = node:getY()
			if clearNodeParent then node.weakTable.parent = false end
		end
	elseif version == 2 then
		-- {{x, y}, {x1, y1}, ...}
		path[#path+1] = {endNode:getX(), endNode:getY()}
		
		local node = endNode
		local nodeParent
		while node ~= startNode do
			if clearNodeParent then 
				nodeParent = node.weakTable.parent
				node.weakTable.parent = false																	-- удаляем ссылку из памяти на другой нод
				node = nodeParent
			else
				node = node.weakTable.parent
			end
		
			path[#path+1] = {node:getX(), node:getY()}
		end		
	end
end

thisModule.findPath = thisModule

-- Вариант №0 из "F:\Gamedev\AI\MotionplaningAndPathfinding\изучаю заново\алгоритм.txt"
function thisModule.findPath:aStar(startNode, endNode, debug)	
	self.open:clear()
	self.closed:clear()
	
	local nodePop, newg
	startNode.g = 0
	startNode.h = self:findH(startNode, endNode)
	startNode.f = startNode.g+startNode.h
	startNode.weakTable.parent = false
	self.open:push(startNode, startNode.f)
	if debug then startNode.part = true end
	
	while self.open:isEmpty() == false do
		nodePop = self.open:pop()
		if debug then nodePop.part = true end
		if debug then nodePop.debugPF.isPopNode = true end
		
		if not nodePop.destroyed then
			if nodePop == endNode then
				local path = {}
				self:constructPath(path, startNode, endNode)
				self.open:clear()
				self.closed:clear()
				return path
			else
				for k, conNode in pairs(nodePop.connectedNodes) do
					if not conNode.destroyed then
						if debug then 
							conNode.debugPF.isConNode = true
							conNode.part = true
						end
						
						newg = nodePop.g + self:findG(nodePop, conNode)
						if (self.open:getValue(conNode) ~= nil or self.closed:findNode(conNode) == true) and conNode.g <= newg then
							-- пропустить
						else
							conNode.weakTable.parent = nodePop
							conNode.g = newg
							conNode.h = self:findH(conNode, endNode)
							conNode.f = conNode.g+conNode.h
							
							if self.closed:findNode(conNode) == true then
								self.closed:delNode(conNode)
							end
							if self.open:getValue(conNode) == nil then
								self.open:push(conNode, conNode.f)
							end		
						end
						self.closed:addNode(nodePop)
						
						if debug then
							love.update()
							love.updateScreen()
		--					love.timer.sleep(0.2)
							conNode.debugPF.isConNode = false
						end	
					end
				end
			end
			if debug then 
				nodePop.debugPF.isPopNode = false
				love.update()
				love.updateScreen()
			end
		end
	end
	self.open:clear()
	self.closed:clear()
	
	return false
end

-- соединяем nodes
function thisModule:connectNodes(graph, minDistance)
	local math = math
	for _, node in pairs(graph.nodes) do
		for _, node1 in pairs(graph.nodes) do
			if node ~= node1 then
				if math.dist(node:getX(),node:getY(), node1:getX(),node1:getY()) < minDistance then						-- 91 - diagonal connect, 65 - not diagonal connect
					node:connect(node1)
				end
			end
		end
	end
end

--###################################################################################################################### test
function thisModule:test()
	thisModule.graphs[1] = require("code.classes.AI.Pathfinding.Graph"):newObject()

	thisModule.nodes = {}

	-- create nodes
	local x = 10
	local y = 10
	local n, spr = 0, 0
	for i=1, 20 do
		for i2=1, 15 do
			if i2==1 then
				y = 150
			else
				y=y+64
			end
			n=n+1
			
			thisModule.nodes[n] = require("code.classes.Entity.AI.Pathfinding.Node"):newObject({x = x, y = y})
			thisModule.graphs[1]:addNode(thisModule.nodes[n].component['Graph.Node'])
		end
		x = x+64
		y = 0	
	end
	thisModule.nodes[#thisModule.nodes+1] = require("code.classes.Entity.AI.Pathfinding.Node"):newObject({x = 1500, y = 100})
	thisModule.graphs[1]:addNode(thisModule.nodes[#thisModule.nodes].component['Graph.Node'])
	thisModule.nodes[#thisModule.nodes].component['Graph.Node']:connect(thisModule.nodes[300].component['Graph.Node'])
	
	for i, graph in ipairs(thisModule.graphs) do	
		thisModule:connectNodes(graph, 91)
	end

	-- find path
	local timer = {}
	timer.start = love.timer.getTime()
--	collectgarbage('stop')

--	thisModule.nodes[300]:destroy()
	thisModule.path = thisModule.findPath:aStar(thisModule.nodes[1].component['Graph.Node'], thisModule.nodes[300].component['Graph.Node'], self.debug.draw.pathfinding.on)
--	thisModule.nodes[300] = false
	
--	thisModule.path = thisModule.findPath:aStar(thisModule.nodes[1], thisModule.nodes[200], self.debug.draw.pathfinding.on)
	
--	thisModule.path = thisModule.findPath:aStar(thisModule.nodes[1], thisModule.nodes[100], self.debug.draw.pathfinding.on)
	
	
--	collectgarbage('restart')
	timer.result = love.timer.getTime() - timer.start
	print("graph:findPath() time:", math.nSA(timer.result))
	
	print("require('code.classes.Graph.Node'):getObjectsCount() = ", require('code.classes.Graph.Node'):getObjectsCount())
	thisModule.nodes[19]:destroy()
	thisModule.nodes[19] = false
	thisModule.nodes[97]:destroy()
	thisModule.nodes[97] = false	
--	collectgarbage()
	print("require('code.classes.Graph.Node'):getObjectsCount() = ", require('code.classes.Graph.Node'):getObjectsCount())
	
	print("open:isEmpty() = ", thisModule.open:isEmpty())
	print("closed:isEmpty() = ", thisModule.closed:isEmpty())
	
--	for i, graph in ipairs(self.graphs) do
--		for k, node in pairs(graph.nodes) do
--			node.weakTable.parent = false
--		end
--	end
end

function thisModule:testPath()
	thisModule.path = thisModule.findPath:aStar(thisModule.nodes[1].component['Graph.Node'], thisModule.nodes[300].component['Graph.Node'], self.debug.draw.pathfinding.on)
end

--###############################################################################################################################

return thisModule