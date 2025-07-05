--[[
version 0.1.1
@help 
	+ heap
@todo 
	- 
--]]

local ClassParent = require('code.Class')																						-- reserved; you can change the string-name of import-module (parent Class) 
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
-- ..

-- methods static protected
-- ...

-- methods static public
function ThisModule:newObject(arg)																												-- rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- nonstatic variables, methods; init new variables from methods arguments
	object.heap = {}
	object.nodes = {}
	
	return object																																-- be sure to return new object
end

--[[
@help 
	+ key = <any type>
	+ value = <number>
--]]
function ThisModule:push(key, value)
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	-- если сувать одинаковые key - то будет ошибка в pop()
	assert(value ~= nil, "cannot push nil")
	
	local n = #self.heap + 1 																													-- node position in heap array (leaf)
	local p = (n - n % 2) / 2 																													-- parent position in heap array
	self.heap[n] = key 																															-- insert at a leaf
	self.nodes[key] = value
	while n > 1 and self.nodes[self.heap[p]] > value do 																						-- climb heap?
		self.heap[p], self.heap[n] = self.heap[n], self.heap[p]
		n = p
		p = (n - n % 2) / 2
	end
	
end

-- get min and delete
-- t[h[1]]  - min value
function ThisModule:pop()																					
	local t = self.nodes
	local h = self.heap
	local s = #h
	assert(s > 0, "cannot pop from empty heap")
	local e = h[1] 																					-- min (heap root)
	local r = t[e]
	local v = t[h[s]]
	h[1] = h[s] 																						-- move leaf to root
	h[s] = nil 																						-- remove leaf
	t[e] = nil
	s = s - 1
	local n = 1 																						-- node position in heap array
	local p = 2 * n 																					-- left sibling position
	
	if s > p and t[h[p]] > t[h[p + 1]] then
		p = 2 * n + 1 																					-- right sibling position
	end
	
	while s >= p and t[h[p]] < v do 																	-- descend heap?
		h[p], h[n] = h[n], h[p]
		n = p
		p = 2 * n
		if s > p and t[h[p]] > t[h[p + 1]] then
			p = 2 * n + 1
		end
	end
	
	return e, r																						-- (node, value)
end

function ThisModule:isEmpty() 
	return self.heap[1] == nil 
end

-- return nil if key no exist
function ThisModule:getValue(key)
	return self.nodes[key]
end

function ThisModule:clear()
	self.heap = {}
	self.nodes = {}
end

return ThisModule																																-- reserved
