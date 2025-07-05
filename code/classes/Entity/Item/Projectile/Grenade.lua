local ClassParent = require('code.classes.Entity.Item.Projectile')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end

ThisModule._statesAllTable = {
	onFloor = {
--		, image = ThisModule._modGraph.images.items.weapons.test.onFloor
--		, sprite = ThisModule._modGraph.sprites.items.weapons.test.onFloor
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt:useStop(nil, whoChangeMyState)
			selfEnt.image = selfState.image
			selfEnt.sprite = selfState.sprite
			selfEnt.shadows.directional.z = 0
			selfEnt.physics.body:setActive(true)
			selfEnt:setPosition(whoChangeMyState:getPosition())
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
			
			selfEnt.physics.fixture:setCategory(3)
			selfEnt.physics.fixture:setMask(2, 4)				
			
--			print(os.clock(), 'state onFloor')
		end
	}
	, onFloor = ClassParent._statesAllTable.onFloor
	, taken = {
--		, image = ThisModule._modGraph.images.items.weapons.test.taken
--		, sprite = ThisModule._modGraph.sprites.items.weapons.test.taken
		funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.image = selfState.image
			selfEnt.sprite = selfState.sprite
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.body:setActive(false)
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
--			print(os.clock(), 'state taken')
		end
	}
	, shooting = {                                                                                                                       -- @todo -? rename to "firing"
		funcCondition = ClassParent._statesAllTable.shooting.funcCondition
		, funcAction = function(selfState, selfObjectState, whoChangeMyState, other)
			local selfEnt = selfObjectState.userData.selfEnt
			selfEnt.state.ro_stateCurrent.whoChangeMyState = whoChangeMyState
--			print(os.clock(), 'state shooting')
			
			selfEnt.z = 5
			selfEnt.shadows.directional.z = 2
			selfEnt.physics.fixture:setCategory(2)
			selfEnt.physics.fixture:setMask(4)			
			
			selfEnt.timer:after(3, function()                                                                                                   -- 3 сек: взрыв сразу после остановки гранаты; 5 сек: можно взять гранату и кинуть в кидавшего или спокойно убежать
--				print(selfEnt, 'destroy')
				local x, y = selfEnt:getX(), selfEnt:getY()
				selfEnt:destroy()
				local explosion = require('code.classes.Entity.Explosion'):newObject({x=x, y=y})
				explosion:boom()
			end)
		end
	}
	, throw = ClassParent._statesAllTable.throw
	, dragged = ClassParent._statesAllTable.dragged
}
--ThisModule.state.ro_stateCurrent = ThisModule._statesAllTable.onFloor

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	object.physics.fixture:setRestitution(0.5)       -- для гранаты >= 0
	
	object.state:setState('onFloor', object)
	
	return object
end

function ThisModule:update(arg)
	if self.destroyed then return false end
--	print(self, self.destroyed)
	ClassParent.update(self, arg)
	
--	print('update')
end

return ThisModule