--[[
version 0.1.0
@help 
	+ Node существует вне класса Graph
@todo 
	+ rename Vertex to Node
	+ ThisModule.connectedNodesCount
		@help невозможно, т.к. при удалении соединенной вершины (self -> node) этой вершине не будет известо о удалении
			+ значит нужно ввести новую таблицу, которая будет запоминать какие вершины соединены по одностороннему направлению с данной (также это нужно при прямом удалении из памяти, без слабых таблиц)
		- или напрямую каждый раз подсчитывать с помощью pairs(), но это медленно
--]]

local ClassParent = require('code.Class')																										-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private
-- ..

-- variables static protected, only in Class
-- ..

-- variables static public
-- ..

-- methods static private
-- ..

-- methods static protected
-- ..

-- methods static public
function ThisModule:newObject(arg)																												-- example; rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
--	assert(arg.graph, "need argument graph")
	
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- nonstatic variables, methods; init new variables from methods arguments
	object.connectedNodes = self:newObjectsWeakTable()																							-- read only!!!; key and value is <table>; если соединенные вершины будут удалены из-вне, то сборщик мусора удалит и из этой таблицы
	object.connectedNodesCount = 0																												-- read only!!!;
	object.connectedNodesClearMemory = self:newObjectsWeakTable()																				-- для прямого удаления из памяти; тут содержатся ссылки на Node которые соединены со мной
	
	object.weakTable = self:newObjectsWeakTable()																								-- read only!!!;
	object.weakTable.graph = arg.graph																											-- read only!!!; если graph будет удален из-вне, то сборщик мусора удалит и из этой таблицы
	
	return object																																-- be sure to return new object
end

function ThisModule:destroy(direct)
	if self.destroyed then self:destroyedError() end
	
	if self.weakTable.graph and (not self.weakTable.graph.destroyed) then
		self.weakTable.graph:deleteNode(self)
	end
	
	if direct then
		self.weakTable.graph = nil																												-- прямое удаление graph из памяти 
		-- прямое удаления из памяти моих ссылок
		for k, node in pairs(self.connectedNodesClearMemory) do
			node:disconnect(self)
		end
		for k, node in pairs(self.connectedNodes) do
			node.connectedNodesClearMemory[self] = nil
		end		
		-- прямое удаления из памяти чужих ссылок
		self.connectedNodesClearMemory = nil
		self.connectedNodes = nil
	end

	ClassParent.destroy(self)
end

--[[
@help 
	+ undirectedConnection: true: self <-> node; false or nil: self -> node
@todo 
	-? undirectedConnection rename to twoWayConnection
--]]
function ThisModule:connect(node, undirectedConnection)
	if self.destroyed then self:destroyedError() end																							-- reserved
	if node == self then return false end
	
	if undirectedConnection then
		self.connectedNodes[node] = node
		node:connect(self)
	else
		self.connectedNodes[node] = node
		node.connectedNodesClearMemory[self] = self
	end
	self.connectedNodesCount = self.connectedNodesCount + 1
end

--[[
@help 
	+ undirectedDisconnection: true: self <-> node; false or nil: self -> node
--]]
function ThisModule:disconnect(node, undirectedDisconnection)
	if self.destroyed then self:destroyedError() end																							-- reserved
	if not self.connectedNodes[node] then return false end
	
	if undirectedDisconnection then
		self.connectedNodes[node] = nil
		node:disconnect(self)
	else
		self.connectedNodes[node] = nil
	end
	self.connectedNodesCount = self.connectedNodesCount - 1
end

function ThisModule:getGraph()
	if self.destroyed then self:destroyedError() end																							-- reserved	
	
	return self.weakTable.graph or false
end

function ThisModule:setGraph(graph)
	if self.destroyed then self:destroyedError() end																							-- reserved	
	
	self.weakTable.graph = graph
end

return ThisModule																																-- reserved
