--[[
version 0.0.2
@todo 
	+ заменить в Item class
		+ переделать в дочерних классах ThisModule.state.statesAllTable
			+ rename whoUsedMe to whoChangeMyState
			+ add "other"
			+ rename ThisModule.state.statesAllTable to ThisModule._statesAllTable
			+ new selfEnt from "other"
		+ require('code.logic.state').new()
	@todo 1 + state который активируется только с условием, если условие выполнено
		* это нужно для того чтобы работало все как определено точно, без ошибок, чтобы можно было перехоть из одного state в другое которое только допустимо, а не в любое другое, это хорошо понятно на графике
		+ funcCondition
--]]
local thisModule = {}
thisModule._TABLETYPE = 'logic.state'

thisModule.__index = thisModule
function thisModule.__newindex(t, k, v)
	error("attempt to update a read-only table", 2)
end

--[[
	* @arg state <string> (from self._states)
	* @arg whoChangeMyState <any>
	* @arg other <any>
	* @return <true> if state is set
	* @return <false> if state is not set because state:funcCondition() is failed
--]]
function thisModule:setState(state, whoChangeMyState, other)
	assert(type(state) == 'string', "argument 'state' must be <string>")

	assert(type(self._states) == 'table', "self._states must be <table>")
	assert(type(self._states[state]) == 'table', "state not correct, state must be <table> instead <" .. type(self._states[state]) .. ">" .. ", state string = '" .. state .. "'")
	local correctStateName = state
	state = self._states[state]
	assert((not state.funcCondition) or type(state.funcCondition) == 'function', "state.funcCondition must be <function> <nil> <false> instead <" .. type(state.funcCondition) .. ">")
	if (not state.funcCondition) or (type(state.funcCondition) == 'function' and state:funcCondition(self, whoChangeMyState, other)) then
		self.ro_stateCurrent = state
		self.ro_stateCurrentName = correctStateName
		if type(self.ro_stateCurrent.funcAction) == 'function' then                                                          -- эта функция funcAction не обязательна
			self.ro_stateCurrent:funcAction(self, whoChangeMyState, other)
		end
		
		return true
	else
		return false
	end	
	
end

function thisModule:getStateCurrent()
	return self.ro_stateCurrent
end

function thisModule:getStateCurrentName()
	return self.ro_stateCurrentName
end

function thisModule:initStates(statesTable)
	assert(type(statesTable) == 'table', "argument 'statesTable' must be <table>")
	self._states = statesTable
--	for k, state in pairs(self._states) do
--		state.ro_name = k
--	end
	
end

local function new()
	local newObject = {}
	newObject.setState = thisModule.setState
	newObject.getStateCurrent = thisModule.getStateCurrent
	newObject.initStates = thisModule.initStates
	newObject.ro_stateCurrent = false                                                                                            -- readonly from out this module
	newObject._states = {}
	newObject.ro_stateCurrentName = false
	newObject.getStateCurrentName = thisModule.getStateCurrentName
	newObject.userData = false                                                                                                   -- @todo - добавить везде вместо selfEnt
	
	return setmetatable(newObject, thisModule)
end

local function test()
	print('logic.state test start')
	
	local state = new()
	assert(state.setState == thisModule.setState)
	assert(state.getStateCurrent == thisModule.getStateCurrent)
	assert(state.initStates == thisModule.initStates)
	assert(state._states ~= thisModule._states)	
	assert(type(state) == 'logic.state')
	
	local states = {
		stateOne = {
			funcCondition = function(selfState, selfObjectState, whoChangeMyState, other)
				-- возвращает true если funcCondition выполнено, тогда state изменяется, иначе state не изменяется
				
				return true
			end
			, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
--				print(selfState, selfObjectState, whoChangeMyState, other, selfObjectState.ro_stateCurrentName)
				assert(selfState == state.ro_stateCurrent)
				assert(selfObjectState == state)
				assert(whoChangeMyState == state)
				assert(other == 'other')
				assert(selfObjectState.ro_stateCurrentName == 'stateOne')					
			end
		}
		, stateTwo = {
			funcCondition = function(selfState, selfObjectState, whoChangeMyState, other)
				-- возвращает true если funcCondition выполнено, тогда state изменяется, иначе state не изменяется
				
				return false
			end				
			, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
				
			end
		}
	}
	state:initStates(states)
	assert(state:getStateCurrent() == false)
	state:setState('stateOne', state, 'other')
	assert(state:getStateCurrentName() == 'stateOne')
	state:setState('stateTwo', state, 'other')
	assert(state:getStateCurrentName() == 'stateOne')
	
	print('logic.state test end')
end

-- example
local states = {
	stateOne = {
		funcCondition = function(selfState, selfObjectState, whoChangeMyState, other)
			-- эта функция не обязательна
			-- возвращает true если funcCondition выполнено, тогда state изменяется, иначе state не изменяется
			
			return true
		end		
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			-- эта функция не обязательна
		end
	}
	, stateTwo = {
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			
		end
	}
}

return setmetatable({new = new, test = test}, {__call = function(_, ...) return new(...) end})