--[[
version 0.1.1
@help 
	+ 
@todo 
	+ rename Vertex to Node
	- edges
		- Box2d EdgeShape
		- чтобы можно было рисовать
--]]

local ClassParent = require('code.Class')																										-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private
-- ...

-- variables static protected, only in Class
-- ...

-- variables static public
-- ...

-- methods static private
-- ...

-- methods static protected
-- ...

-- methods static public
function ThisModule:newObject(arg)																												-- rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- nonstatic variables, methods; init new variables from methods arguments
	object.nodes = self:newObjectsWeakTable()																									-- read only!!!; key and value is <table>; если node будет удален из-вне, то сборщик мусора удалит и из этой таблицы				
	object.nodesCount = 0																														-- read only!!!;
	
	return object																																-- be sure to return new object
end

function ThisModule:addNewNode(NodeClass)
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local node = (NodeClass or require("code.classes.Graph.Node")):newObject({graph = self})
	self.nodes[node] = node
	self.nodesCount = self.nodesCount + 1
	
	return node
end

function ThisModule:addNode(node)
	if self.destroyed then self:destroyedError() end																							-- reserved
	if node.destroyed then return false end
	
	self.nodes[node] = node
	self.nodesCount = self.nodesCount + 1
end

--[[
@help 
	+ delete node only from graph
--]]
function ThisModule:deleteNode(node)
	if self.destroyed then self:destroyedError() end																							-- reserved
	if not self.nodes[node] then return false end
	
	self.nodes[node] = nil
	self.nodesCount = self.nodesCount - 1
end

function ThisModule:destroy()
	if self.destroyed then return false end																							-- reserved
	
	
	
	ClassParent.destroy(self)
end

function ThisModule:test()
	if self.destroyed then self:destroyedError() end																							-- reserved
	print("\ntest Graph class:")
	
	test = test or {}
	
	test.graph = require("code.classes.Graph.Graph"):newObject()
	test.graph2 = require("code.classes.Graph.Graph"):newObject()
	print("test.graph = ", test.graph)
	print("test.graph2 = ", test.graph2)
	
	test.node = {}
	test.node[1] = require("code.classes.Graph.Node"):newObject({graph = test.graph})
	test.node[1].name = "Number 1"
	test.node[2] = require("code.classes.Graph.Node"):newObject({graph = test.graph})
	test.node[2].name = "Number 2"
	test.node[3] = test.graph:addNewNode()
	test.node[3].name = "Number 3"
	
	test.graph:addNode(test.node[1])
	
	test.node[1]:connect(test.node[2])
	test.node[2]:connect(test.node[3])
	test.node[3]:connect(test.node[1])
	
--	test.node[1]:disconnect(test.node[3], true)

	collectgarbage('stop')
	
--	test.graph:deleteNode(test.node[1])
--	test.node[1]:destroy(true)
	test.node[2]:destroy(true)
--	test.node[3]:destroy(true)
--	test.graph:destroy()
	
	if test.graph and (not test.graph.destroyed) and test.graph.nodes then
		print("test.graph.nodesCount = ", test.graph.nodesCount)
		print("test.graph.nodes:")
		for k, node in pairs(test.graph.nodes) do
			print("", node.name)
		end
	end	
	
	if test.node[1] and (not test.node[1].destroyed) then
--		print("test.node[1]:getGraph() = ", test.node[1]:getGraph())
--		print("test.node[1]:setGraph(test.graph2)", test.node[1]:setGraph(test.graph2))
--		print("test.node[1]:getGraph() = ", test.node[1]:getGraph())
		print("test.node[1].connectedNodes:")
		print("\ttest.node[1].connectedNodesCount = ", test.node[1].connectedNodesCount)
		for k, node in pairs(test.node[1].connectedNodes) do
--			if node and (not node.destroyed) then
				print("", node.name)
--			end
		end
	end

	if test.node[2] and (not test.node[2].destroyed) then
		print("test.node[2].connectedNodes:")
		print("\ttest.node[2].connectedNodesCount = ", test.node[2].connectedNodesCount)		
		for k, node in pairs(test.node[2].connectedNodes) do
--			if node and (not node.destroyed) then
				print("", node.name)
--			end
		end
	end
	
	if test.node[3] and (not test.node[3].destroyed) then
		print("test.node[3].connectedNodes:")
		print("\ttest.node[3].connectedNodesCount = ", test.node[3].connectedNodesCount)
		for k, node in pairs(test.node[3].connectedNodes) do
--			if node and (not node.destroyed) then
				print("", node.name)
--			end
		end
	end	
	
	collectgarbage('restart')
end

return ThisModule																																-- reserved
