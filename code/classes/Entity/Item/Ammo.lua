--[[
@version 0.0.1
@help 
	* коробка в боеприпасами
@todo 
	@todo 1 -+ Ammo.Test
		- Ammo other
	-+ tupe
		-? like variable
			* тогда нужно в одном классе расписывать все типы, это неудобно
		-+? like Class
	@todo + sprite
	@todo + если патроны кончились
		+?YES удалять Энтити
			* для оптимизации хорошо
			* намного легче реализовать
			-?NO выкинуть на землю и удалить
				* физика может отрицательно сказаться на геймплее
			+ удалять напрямую
				+ из инвентаря
				+ из UIList
		-?NotNow рисовать спрайт "пустой коробки"
			* более интерактивный мир
			* не сейчас; хорошо для open-world game, а для простой игры это не кретически
			@todo -? и удалять через некоторое время
				- после того как Итем окажется на земле
--]]

local ClassParent = require('code.classes.Entity.Item')																							-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private

-- variables static protected, only in Class
ThisModule._projectileType = 'Test'

-- variables static public
ThisModule.image = ThisModule._modGraph.images.items.ammo.test.onFloor--false
--ThisModule.sprite = ThisModule._modGraph.sprites.items.ammo.test.onFloor
ThisModule.count = 10

-- methods static private

-- methods static protected

-- methods static public
function ThisModule:newObject(arg)																												-- example; rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	object.info = {}
	object.info[1] = function () return 'count = ' .. object.count end
	object.info[2] = function () return 'projectile type = ' .. object._projectileType end
	
--	print(ThisModule:getProjectileType())
	
	return object																																-- be sure to return new object
end

function ThisModule:getProjectileType()
	return self._projectileType
end

-- @todo - not done; а нужна ли? да
-- взять боеприпасы из коробки
function ThisModule:take(number)
	-- упроститель; мы пишем сколько нужно боеприпасов, а функция возвращает сколько боеприпасов может дать; чтобы каждый раз из-вне не проверять сколько в ammo осталось боеприпасов
	-- функция-контролер-упроститель, чтобы ThisModule.count не изменять из-вне; т.е. когда мы берем патроны, то тут нужно отнять и чтобы это отнятие не писать каждый раз из-вне
	local taken = 0
	
	if self.count > 0 then
		if self.count < number then
			taken = self.count
			self.count = 0
		else
			taken = number
			self.count = self.count - number
		end
	end
	
	return taken
end

function ThisModule:update(arg)
	if self.destroyed then return false end
	ClassParent.update(self, arg)
	
end

return ThisModule																																-- reserved
