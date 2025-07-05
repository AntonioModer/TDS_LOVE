--[[------------------------------------------------------------------------------------------------
	@version 0.0.1
	* структура sprite
	* нужно для рисования Item в руках Humanoid, используя разные origin для каждого Item
	* not done
	@todo
		- documentation
		@todo 2 -? везде заменить код на этот тип
			- везде оставить пока image
			- добавить sprite где нужно, не заменяя image
		- draw
		- пример API:
			- Unity https://docs.unity3d.com/ScriptReference/Sprite.html
			- SFML http://www.sfml-dev.org/documentation/2.4.0/classsf_1_1Sprite.php
		-?YES как структура
		-? как Класс
			- переделать Class
		* готовые библиотеки
			* https://github.com/tesselode/sodapop
		+ читать файл параметров sprite ".lua"
		@todo 1 - переделать draw() (смотри draw.angle in Humanoid:draw())
--]]------------------------------------------------------------------------------------------------

local thisModule = {}
thisModule._TABLETYPE = 'graphics.sprite'

thisModule.__index = thisModule
function thisModule.__newindex(t, k, v)
	error("attempt to update a read-only table", 2)
end

-- @todo - type check
local function new(transform, color, pathWithoutName, name, image, userdata)
--	assert(type(x) == 'number', [[argument1 x must be 'number' type, not ']]..type(x)..[[' type]])
--	assert(type(y) == 'number', [[argument2 y must be 'number' type, not ']]..type(y)..[[' type]])
	
	local structure = {}
	
	structure.color = color                                                                                        -- need?
	structure.transform = transform or math.transform()
	
	if image then
		structure.image = image
	else
		local filePath = pathWithoutName.."/"..name..'.png'
		if love.filesystem.exists(filePath) then
			structure.image = love.graphics.newImage(filePath)                                                         -- Image LOVE object; <false> or <LOVE Image>
		else
			structure.image = false
		end
	end
	
	local file, error = loadfile(pathWithoutName.."/"..name..".lua")
	if file then
		file()(structure)
--		print(file, structure.transform.origin.x, structure.transform.origin.y)
	else
		if image then
			structure.transform.origin.x = structure.image:getWidth()/2
			structure.transform.origin.y = structure.image:getHeight()/2
		end
--		print(error)
	end
	
--	print(file, structure.transform.origin.x, structure.transform.origin.y)
	
	structure.userdata = userdata or {}
	
	return setmetatable(structure, thisModule)
end

--function thisModule:clone()
	
--end

--function thisModule:unpack()
	
--end

--function thisModule:__tostring()
	
--end

--function thisModule.__eq(a, b)
	
--end

function thisModule:draw(arg)
	if not self.image then return false end
--	love.graphics.setColor((arg.color or self.color):unpack())
	love.graphics.draw(self.image, self.transform.position.x, self.transform.position.y, arg.angle or self.transform.angle, self.transform.scale.x, self.transform.scale.y, self.transform.origin.x, self.transform.origin.y)
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})