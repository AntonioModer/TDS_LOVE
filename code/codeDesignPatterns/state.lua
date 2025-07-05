-- @todo + make module

local ThisModule = {}                                                                                                                        -- start name from big later, like class, for simple copy&paste

ThisModule.state = {}
ThisModule.state.statesAllTable = {
	stateOne = {
		name = 'stateOne'
		, funcAction = function(selfState, selfModule, whoUsedMe, other)
			
		end
	}
	, stateTwo = {
		name = 'stateTwo'
		, funcAction = function(selfState, selfModule, whoUsedMe, other)
			
		end
	}
}
ThisModule.state.ro_stateCurrent = ThisModule.state.statesAllTable.onFloor                                                                         -- readonly from out @todo -? вместо этого использовать self:setState('stateOne', self)

--[[
	* @arg state <string> <nil> = "see self.state.statesAllTable" (default 'onFloor')
	* @arg whoUsedMe <table>
--]]
function ThisModule:setState(state, whoUsedMe, other)
	assert(state == nil or type(state) == 'string', "variable 'state' must be <string> <nil>")
	
	local correctState = false
	for statePatternName, statePattern in pairs(self.state.statesAllTable) do
		if state == statePatternName then
			correctState = true
			break
		end
	end
	
	assert(correctState, 'state not correct')
	assert(type(whoUsedMe) == 'object', "variable 'whoUsedMe' must be <object>")
	
	self.state.ro_stateCurrent = self.state.statesAllTable[state] or self.state.statesAllTable['onFloor']
	self.state.ro_stateCurrent:funcAction(self, whoUsedMe, other)
end