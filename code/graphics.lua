--[[
version 0.1.11
@help 
	+ draw maximum 65000 Entitys
	+ physics for thisModule.zDBEL (World:queryBoundingBox())
		+ даем ссылку на энтити в object.physics.body:setUserData(object), нужно её удалять если мы используем Class:destroyAllObjectsFromClass(), иначе энтити будут существовать в физике
	+ queryBoundingBox перенесен в один главный метод (в graphics)
		+ queryBoundingBoxCallback для каждого случая свой
@todo 
	- directional shadows
		-? по моему попиксельному методу
			- карта света как от солнца, лучи света всегда в одном направлении; и к этой карте применять шейдер
			* не получится, т.к. шейдер только для радиального света
		-? новый шейдер
	-! проблема, если в энтити физическое тело меньше его текстуры, то энтити не будет рисоваться по краям экрана
		+?YES использовать sensor Box2d
			@help но сенсор обрабатывает ненужное "World callbacks", который будет нагружать процессор
				- переместить его в другую категорию столкновений, чтобы он не сталкивался с остальными фикстурами
				-? отключить это в исходниках LOVE, или попросить
					- добавить новый параметр в фикстуре, который конролирует работает ли "World callbacks" для него
			@help также в кадр попадают все физические объекты, которые также лишне нагружают процессор
		-? делать отдельный модуль типа quadtree
			-? использовать Box2d b2DynamicTree
			- https://love2d.org/forums/viewtopic.php?f=5&t=78502
			- hardoncollider
	- почему love.graphics.line = 2 drawCals ?
	- profiling
		- график задержки
	- разобраться с 
		+ .dds
		+ mipmaps
	- quad
		- учитывать quad
			- необходим файл для атласа, в котором (в файле будут имя и координаты каждого quad)
		-? везде должен быть Quad? нет
	-+ список отрисовки		
	-+ light engine
		-+ draw shadows
			-+ light entity
		-? GI
			@todo 1 - radiosity
				- смотри мой пример radiosity2D
				-? делать в сторонней программе
					- radiosity Blender
						- разбиваем мир на полигональные квадраты, сохраняем эти квадраты и Энтити в 3D формат, загружаем в Blender, делаем Bake (вручную), экспортируем запеченные изображения в игру
	-+ camera
		-? сделать свою камеру	
	-+ draw optimisation	
		- batching	
			- dynamic
			- static
	- particles		
	-+ разобраться с .dds
		- грузить в игру текстуры только в .dds	
	- effects	
		-? fluids by pixel shaders
	- нужно чтобы размер камеры не зависел от размера окна; пример: размер камеры в 2 раза меньше размера окна, но изображение камеры рисуется во всем окне [
		- камера и окно со своими отдельными независимыми разрешениями картинки, как в редакторах движков UE4, Unity, Cryengine
		- это нужно для фиксированного размера камеры(дальности отображения мира в камере) при любом разрешении окна(экрана)
		- т.е. разрешение окна(экрана) должно только увеличивать качество картинки, и не изменять размеры камеры(дальности отображения мира в камере)
		- но тогда появляются ограничения:
			- или края обрезаются, если разрешение экрана больше размера камеры
			- или, если картинку камеры будем растягивать под разрешение экрана, то изображение становится не пропорциональное, например, круг станет элипсом, квадрат станет прямоугольником
	]
	-?NO sunLight like entity
]]

local thisModule = {}

-- settings
love.graphics.setLineJoin('none')

--##############################[ fonts ]####################################
-- INFO: http://unicode-table.com/ru
-- INFO: http://unicode-table.com/ru/tools/generator/

thisModule.mainFont = {}
thisModule.font = {}
thisModule.font.AntonioModerFont8pt_6x11pix_Ascent10BW = {}
thisModule.font.AntonioModerFont8pt_7x13pix_Ascent10Black = {}

--thisModule.mainFont.id = love.graphics.newFont([[resources/fonts/DejaVuSansMono.ttf]], 10)

--thisModule.mainFont.id = love.graphics.newFont([[resources/fonts/AntonioModerFont8pt_6x11pix_Ascent10_Fony.fon]], 11)

--thisModule.mainFont.id = love.graphics.newImageFont("resources/fonts/Resource-Imagefont.png",
----	" a")
--    " abcdefghijklmnopqrstuvwxyz" ..
--    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
--    [=[0123456789.,!?-+/():;%&`'*#=[]"]=], 0)

----[====[

-- UNICODE NULL:
thisModule.unicode = -- require("code.graphics").unicode
-- Basic Latin; 0020 ... 007E (95 plyphs)
   [=[ !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~]=]
   
-- Latin-1 Supplement; 00A9, 00D6 (2 plyph)
.. [=[©Ö]=]

-- Cyrillic; 0410 ... 044F (64 plyphs)
.. [=[АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя]=]

-- Control character; 2026 (1 plyph)
.. [=[…]=]

-- Miscellaneous Technical; 23E0 ... (0 plyphs)
.. [=[]=]

-- Block Elements; 2588 (1 plyph)
.. [=[█]=]

thisModule.mainFont.id = love.graphics.newImageFont("resources/fonts/AntonioModerFont8pt_6x11pix_Ascent10.png", thisModule.unicode)
thisModule.mainFont.id:setFilter('nearest', 'nearest', 0)

-- @todo -? уменьшить ширину на 1 пиксель
-- @todo -? убрать знак (c)
thisModule.font.AntonioModerFont8pt_6x11pix_Ascent10BW.id = love.graphics.newImageFont("resources/fonts/AntonioModerFont8pt_6x11pix_Ascent10BW.png", thisModule.unicode, -2) 
thisModule.font.AntonioModerFont8pt_6x11pix_Ascent10BW.id:setFilter('nearest', 'nearest', 0)

-- @todo +- уменьшить ширину на 1 пиксель
-- @todo -?NO убрать знак (c)
-- @todo - переименовать шрифт
thisModule.font.AntonioModerFont8pt_7x13pix_Ascent10Black.id = love.graphics.newImageFont("resources/fonts/AntonioModerFont8pt_7x13pix_Ascent10Black.png", thisModule.unicode, -1) 
thisModule.font.AntonioModerFont8pt_7x13pix_Ascent10Black.id:setFilter('nearest', 'nearest', 0)

--]====]
--thisModule.mainFont.id:setFallbacks(love.graphics.newFont([[resources/fonts/DejaVuSansMono.ttf]], 10)) -- не работает

thisModule.mainFont.characterWidth = thisModule.mainFont.id:getWidth(' ') --7																											-- in pixels
thisModule.mainFont.characterHeight = thisModule.mainFont.id:getHeight(' ') --14																										-- in pixels

love.graphics.setFont(thisModule.mainFont.id)


--print(love.graphics.getFont():getWidth(' '), love.graphics.getFont():getHeight(' '))
--print(thisModule.mainFont.id:hasGlyphs('…'))

thisModule.mainFont.coloredText = false                                                                                                         -- если шрифт разноцветный, то рисуем текст только с помощью белого цвета

-- images ##########################################################################################
--[[
	@todo 
		-? multithreading. загружать в отдельном thread
		-+? pivot
			-+ тогда нужно:
				-+ новый тип данных <sprite> 
					-? структура
					-? Class
				-+? к каждому изображению прилагать файл с описанием pivot точки
--]]
thisModule.images = {}
thisModule.images.test = love.graphics.newImage([[resources/images/other/test.png]])
thisModule.images.testDDS = love.graphics.newImage(love.image.newCompressedData([[resources/images/other/test.dds]]), {mipmaps=true})
thisModule.images.testDDS:setMipmapFilter("linear", 0)
thisModule.images.testWhite = love.graphics.newImage([[resources/images/other/testWhite.png]])
thisModule.images.light = {}
thisModule.images.light.lightDebug = love.graphics.newImage([[resources/images/other/light/lightDebug.png]])
thisModule.images.light.light1 = love.graphics.newImage([[resources/images/other/light/light1.png]])
thisModule.images.light.lightSmooth256 = love.graphics.newImage([[resources/images/other/light/lightSmooth256.png]])
thisModule.images.light.lightSmooth512 = love.graphics.newImage([[resources/images/other/light/lightSmooth512.png]])
--thisModule.images.light.lightSmooth512DDS = love.graphics.newImage(love.image.newCompressedData([[resources/images/other/light/lightSmooth512.dds]]), {mipmaps=true})
--thisModule.images.light.lightSmooth512DDS:setMipmapFilter("linear", 0)
thisModule.images.light.lightSmooth1024 = love.graphics.newImage([[resources/images/other/light/lightSmooth1024.png]])
thisModule.images.humanoid = love.graphics.newImage([[resources/images/human/humanoid.png]])
thisModule.images.humanoidBody = love.graphics.newImage([[resources/images/human/body.png]])
--thisModule.images.humanoidBody:setFilter("nearest", "nearest", 0)
thisModule.images.humanoidBodyDDS = love.graphics.newImage(love.image.newCompressedData([[resources/images/human/body.dds]]), {mipmaps=true})
thisModule.images.humanoidBodyDDS:setMipmapFilter("linear", 0)
thisModule.images.humanoidHead = love.graphics.newImage([[resources/images/human/head.png]])
--thisModule.images.humanoidHead:setFilter("nearest", "nearest", 0)
thisModule.images.humanoidHeadDDS = love.graphics.newImage(love.image.newCompressedData([[resources/images/human/head.dds]]), {mipmaps=true})
thisModule.images.humanoidHeadDDS:setMipmapFilter("linear", 0)
thisModule.images.humanoid = {}
thisModule.images.humanoid.hands = {}
thisModule.images.humanoid.hands.idle = love.graphics.newImage([[resources/images/human/handsIdle.png]])
thisModule.images.humanoid.hands.run = love.graphics.newImage([[resources/images/human/handsRun.png]])
thisModule.images.humanoid.hands.weapon = {}
thisModule.images.humanoid.hands.weapon.oneInTwoHands = love.graphics.newImage([[resources/images/human/weaponOneInTwoHands.png]])
thisModule.images.humanoid.body = {}
thisModule.images.humanoid.body.weapon = {}
thisModule.images.humanoid.body.weapon.oneInTwoHands = love.graphics.newImage([[resources/images/human/weaponOneInTwoHandsBody.png]])
thisModule.images.items = {}
thisModule.images.items.test = {}
thisModule.images.items.test.onFloor = love.graphics.newImage([[resources/images/objects/items/test/onFloor.png]])
thisModule.images.items.test.taken = love.graphics.newImage([[resources/images/objects/items/test/taken.png]])
thisModule.images.items.weapons = {}
thisModule.images.items.weapons.test = {}
thisModule.images.items.weapons.test.onFloor = love.graphics.newImage([[resources/images/objects/items/weapons/test/onFloor.png]])
thisModule.images.items.weapons.test.taken = love.graphics.newImage([[resources/images/objects/items/weapons/test/taken.png]])
thisModule.images.items.weapons.grenadeLauncher = {}
thisModule.images.items.weapons.grenadeLauncher.onFloor = love.graphics.newImage([[resources/images/objects/items/weapons/grenadeLauncher/onFloor.png]])
thisModule.images.items.weapons.grenadeLauncher.taken = love.graphics.newImage([[resources/images/objects/items/weapons/grenadeLauncher/taken.png]])
thisModule.images.items.weapons.rocketLauncher = {}
thisModule.images.items.weapons.rocketLauncher.onFloor = love.graphics.newImage([[resources/images/objects/items/weapons/rocketLauncher/onFloor.png]])
thisModule.images.items.weapons.rocketLauncher.taken = love.graphics.newImage([[resources/images/objects/items/weapons/rocketLauncher/taken.png]])
thisModule.images.items.weapons.crossbow = {}
thisModule.images.items.weapons.crossbow.onFloor = love.graphics.newImage([[resources/images/objects/items/weapons/crossbow/onFloor.png]])
thisModule.images.items.weapons.crossbow.taken = thisModule.images.items.weapons.crossbow.onFloor
thisModule.images.items.ammo = {}
thisModule.images.items.ammo.test = {}
thisModule.images.items.ammo.test.onFloor = love.graphics.newImage([[resources/images/objects/items/ammo/test/onFloor.png]])
thisModule.images.items.projectile = {}
thisModule.images.items.projectile.common = {}
thisModule.images.items.projectile.common.onFloor = love.graphics.newImage([[resources/images/objects/items/projectile/common/onFloor.png]])
thisModule.images.items.projectile.arrow = {}
thisModule.images.items.projectile.arrow.onFloor = love.graphics.newImage([[resources/images/objects/items/projectile/arrow/onFloor.png]])
thisModule.images.items.projectile.rocket = {}
thisModule.images.items.projectile.rocket.onFloor = love.graphics.newImage([[resources/images/objects/items/projectile/rocket/onFloor.png]])
thisModule.images.items.projectile.fire = {}
thisModule.images.items.projectile.fire.onFloor = love.graphics.newImage([[resources/images/objects/items/projectile/fire/onFloor.png]])
thisModule.images.trees = {}
thisModule.images.trees.test = love.graphics.newImage([[resources/images/objects/tree.png]])
thisModule.images.crates = {}
thisModule.images.crates._1 = love.graphics.newImage([[resources/images/objects/crates/TexturesCom_Cargo0097_S_64x64.png]])
thisModule.images.crates._2 = love.graphics.newImage([[resources/images/objects/crates/TexturesCom_Cargo0095_S_64x67.png]])
thisModule.images.woodPlanks = {}
thisModule.images.woodPlanks._1 = love.graphics.newImage([[resources/images/objects/woodPlanks/TexturesCom_WoodPlanksBare0135_1_S_1_128x16.png]])
thisModule.images.woodPlanks._2 = love.graphics.newImage([[resources/images/objects/woodPlanks/TexturesCom_WoodPlanksBare0135_1_S_2_128x16.png]])
thisModule.images.barrels = {}
thisModule.images.barrels._1 = love.graphics.newImage([[resources/images/objects/barrels/TexturesCom_Barrels0008_1_S_42x64.png]])
thisModule.images.barrels._2 = love.graphics.newImage([[resources/images/objects/barrels/TexturesCom_Barrels0011_S_41x64.png]])
thisModule.images.bottles = {}
thisModule.images.bottles.big = {}
thisModule.images.bottles.big._1 = love.graphics.newImage([[resources/images/objects/bottles/IMG_20170207_203815_forGame_small.png]])

thisModule.newTypeSprite = require("code.graphics.sprite")
thisModule.sprites = {}
thisModule.sprites.items = {}
thisModule.sprites.items.test = {}
thisModule.sprites.items.test.onFloor = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/test]], 'onFloor', thisModule.images.items.test.onFloor)
thisModule.sprites.items.test.taken = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/test]], 'taken', thisModule.images.items.test.taken)
thisModule.sprites.items.weapons = {}
thisModule.sprites.items.weapons.test = {}
thisModule.sprites.items.weapons.test.onFloor = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/test]], 'onFloor', thisModule.images.items.weapons.test.onFloor)
thisModule.sprites.items.weapons.test.taken = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/test]], 'taken', thisModule.images.items.weapons.test.taken)
thisModule.sprites.items.weapons.test.aiming = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/test]], 'aiming', thisModule.images.items.weapons.test.taken)
thisModule.sprites.items.weapons.grenadeLauncher = {}
thisModule.sprites.items.weapons.grenadeLauncher.onFloor = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/grenadeLauncher]], 'onFloor', thisModule.images.items.weapons.grenadeLauncher.onFloor)
thisModule.sprites.items.weapons.grenadeLauncher.taken = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/grenadeLauncher]], 'taken', thisModule.images.items.weapons.grenadeLauncher.taken)
thisModule.sprites.items.weapons.grenadeLauncher.aiming = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/grenadeLauncher]], 'aiming', thisModule.images.items.weapons.grenadeLauncher.taken)
thisModule.sprites.items.weapons.rocketLauncher = {}
thisModule.sprites.items.weapons.rocketLauncher.onFloor = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/rocketLauncher]], 'onFloor', thisModule.images.items.weapons.rocketLauncher.onFloor)
thisModule.sprites.items.weapons.rocketLauncher.taken = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/rocketLauncher]], 'taken', thisModule.images.items.weapons.rocketLauncher.taken)
thisModule.sprites.items.weapons.rocketLauncher.aiming = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/rocketLauncher]], 'aiming', thisModule.images.items.weapons.rocketLauncher.taken)
thisModule.sprites.items.weapons.crossbow = {}
thisModule.sprites.items.weapons.crossbow.onFloor = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/crossbow]], 'onFloor', thisModule.images.items.weapons.crossbow.onFloor)
thisModule.sprites.items.weapons.crossbow.taken = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/crossbow]], 'taken', thisModule.images.items.weapons.crossbow.taken)
thisModule.sprites.items.weapons.crossbow.aiming = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/weapons/crossbow]], 'aiming', thisModule.images.items.weapons.crossbow.taken)
thisModule.sprites.items.ammo = {}
thisModule.sprites.items.ammo.test = {}
thisModule.sprites.items.ammo.test.onFloor = thisModule.newTypeSprite(nil, nil, [[resources/images/objects/items/ammo/test]], 'onFloor', thisModule.images.items.ammo.test.onFloor)

-- test --------------------------------
--test = test or {}
--test.imageTab = {}
--for i=1, 10000 do
----	test.imageTab[i] = love.graphics.newImage(love.image.newCompressedData([[resources/images/other/light/lightSmooth512.dds]]))
----	test.imageTab[i] = love.graphics.newImage([[resources/images/other/light/lightSmooth512.png]])
--end
------------------

thisModule.quads = {}
--thisModule.quads.test = love.graphics.newQuad(x, y, width, height, sw, sh)

camera = require("code.camera")																													-- @todo -?NO убрать глабольную переменную или перенести

------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
@help 
	+ zDBEL содержит <Entitys> которые будут нарисованы
	+ используется y-координата энтити относительно камеры, чем больше, тем она "выше"
		+ при рисовании считается по y от 0 и до config.window.height-1	
EXAMPLE:
	-- @todo - устаревший, обновить из кода 
	thisModule.zDBEL.layers[10] = {}																											-- new layer
	thisModule.zDBEL.layers[10].depth[1] = entity1
	thisModule.zDBEL.layers[10].depth[2] = entity2
	thisModule.zDBEL.layers[10].eq[2] = entity3
	
	-- таблица для поиска Entity, когда у одного PhysBody есть больше одной fixture; key is <object>, value is <number>; также нужна для удаления энтити из zDBEL
	thisModule.zDBEL.layers[10].searchIndex = {}
	thisModule.zDBEL.layers[10].searchIndex[entity1] = 1
	thisModule.zDBEL.layers[10].searchIndex[entity2] = 2
	
	thisModule.zDBEL.layers[10] = nil																											-- clear layer
@todo 
	-NO использовать z-buffering по номеру создания Entity
		-INFO не подходит, т.к. ipairs() аналогична "for i"
		- рефакторинг searchIndex
--]]
thisModule.zDBEL = {}																															-- z draw buffer Entitys layers
thisModule.zDBEL.layers = {}																													-- key is <number>; value is <table> or <nil>
thisModule.zDBEL.debug = {}

function thisModule.zDBEL:_existsEntity(entity)
	if entity and self.layers[entity.z] and self.layers[entity.z].searchIndex[entity] then 
		return true
	end
	
	return false
end

thisModule.zDBEL.debug.update = {}
thisModule.zDBEL.debug.update.countAdd = 0
function thisModule.zDBEL:addEntity(entity)
	if not self.layers[entity.z] then
		self.layers[entity.z] = {}																												-- key is <number>; value is <object> or <false>
		self.layers[entity.z].searchIndex = {}																									-- key is <object>; value is <number> or nil
		self.layers[entity.z].depth = {}
		self.layers[entity.z].depth.eq = {}																										-- эквивалентые, одинаковая глубина
	elseif self:_existsEntity(entity) then
		return false									
	end

	-- @todo -? сделать размер depth зависящим от разрешения окна (чем меньше разрешение, тем он больше, и наоборот), чтобы было меньше совпадений и следовательно меньше "смешивания"
		-- @todo - везде координаты с камеры в глобальные и наоборот(camera:cameraCoords(), camera:worldCoords()), без учета config.window.height; также в draw()
	-- @todo - on/off
	local _, depth = camera:toScreen(0, entity.physics.body:getY())
	depth = math.ceil(depth)
	if depth < 0 then depth = 0 end
	if depth > config.window.height-1 then depth = config.window.height-1 end
	if self.layers[entity.z].depth[depth] then																									-- если объект имеет одинаковую depth, то ложить в eq
		self.layers[entity.z].depth.eq[depth] = self.layers[entity.z].depth.eq[depth] or {}
		self.layers[entity.z].depth.eq[depth][#self.layers[entity.z].depth.eq[depth]+1] = entity 
	else
		self.layers[entity.z].depth[depth] = entity																								--!!! ссылка на object
	end
	self.layers[entity.z].searchIndex[entity] = depth																							--!!! ссылка на object
	thisModule.zDBEL.debug.update.countAdd = thisModule.zDBEL.debug.update.countAdd+1
	return true
end

-- @todo -? может не нужна, если проверять при рисовании entity.destroyed, тогда из энтити можно убрать вызов этого метода
function thisModule.zDBEL:deleteEntity(entity)
	if not self:_existsEntity(entity) then return false end
	self.layers[entity.z][self.layers[entity.z].searchIndex[entity]] = false																	-- удаляем из слоя, эта энтити не будет тут обрабатываться
	self.layers[entity.z].searchIndex[entity] = nil
	return true
end

--[[
@help 
	+ "тяжелый" (№2 когда physics.debug.draw.on и на экране > 1000 entity)
--]]
thisModule.zDBEL.debug.draw = {}
thisModule.zDBEL.debug.draw.count = 0
thisModule.zDBEL.debug.draw.timer = {}
thisModule.zDBEL.debug.draw.timer.start = 0
thisModule.zDBEL.debug.draw.timer.result = 0
function thisModule.zDBEL:draw(debug, shadowsDirectional)
	self.debug.draw.timer.start = love.timer.getTime()
	
	love.graphics.setColor(255, 255, 255, 255)
	thisModule.zDBEL.debug.draw.count = 0																										-- debug
	local cwh = config.window.height-1
	for i=-1, 15 do
		if self.layers[i] then
			for depth=0, cwh do                                                                                                                 -- размер depth тормазит отрисовку; чем он меньше, тем больше погрешность и image будут больше "смешиваться"
				local entity = self.layers[i].depth[depth]                                                                                      -- for help
				if entity and self:_existsEntity(entity) and (not entity.destroyed) then
					entity:draw({debug=debug, shadowsDirectional=shadowsDirectional})
					self.debug.draw.count = self.debug.draw.count+1                                                                               -- debug
					if self.layers[i].depth.eq[depth] then
						for i2=1, #self.layers[i].depth.eq[depth] do
							if (not self.layers[i].depth.eq[depth][i2].destroyed) then
								self.layers[i].depth.eq[depth][i2]:draw({debug=debug, shadowsDirectional=shadowsDirectional})
								self.debug.draw.count = self.debug.draw.count+1                                                                   -- debug
							end
						end
					end
				end
			end
		end
	end
	
	self.debug.draw.timer.result = love.timer.getTime()-self.debug.draw.timer.start
end

function thisModule.zDBEL.queryBoundingBoxCallback(fixture)
	-- @todo 1 + нужен специальный параметр, определяющий что это сенсор для отрисовки, а то все сенсоры будет рисовать
	if not fixture:getBody():isActive() then print('not active') end
	if (not fixture:isDestroyed()) --[[and fixture:isSensor()--]] and fixture:getUserData() and fixture:getUserData().typeDraw then
		
		local entity = fixture:getBody():getUserData()
		if entity and entity._TABLETYPE == "object" and (not thisModule.zDBEL:_existsEntity(entity)) and (not entity.destroyed) and string.sub(entity:getClassName(), 1, 6) == 'Entity' then
			thisModule.zDBEL:addEntity(entity)
		end
	end
	return true
end
function thisModule.zDBEL:update(dt)
	thisModule.zDBEL.debug.update.countAdd = 0
	self.layers = {}	
end

-- testing example, put in require("code.debug.ui")
--local foo = function()
--	return "zDBEL.debug.draw.count = "..tostring(require("code.graphics").zDBEL.debug.draw.count)												-- string
--end
--debug.ui.watchList:insertItem({name="zDBEL.debug.draw.count = ...", func = foo})

--local foo = function()
--	return "zDBEL.debug.draw.timer.result = "..tostring(require("code.graphics").zDBEL.debug.draw.timer.result)									-- string
--end
--debug.ui.watchList:insertItem({name="zDBEL.debug.draw.timer.result = ...", func = foo})

--local foo = function()
--	return "zDBEL.debug.update.countAdd = "..tostring(require("code.graphics").zDBEL.debug.update.countAdd)										-- string
--end
--debug.ui.watchList:insertItem({name="zDBEL.debug.update.countAdd = ...", func = foo})
------------------------------------------------------------------------------------------------------------------------------------------------

-- draw lights -----------------------------------
thisModule.light = require('code.graphics.light')
-------------------------------------------------

thisModule.db = {}																																-- draw buffer

function thisModule.db.queryBoundingBoxCallback(fixture)
	
	thisModule.zDBEL.queryBoundingBoxCallback(fixture)
	thisModule.light.eLB.queryBoundingBoxCallback(fixture)
	
	return true
end

--[[
@help 
	+ "тяжелый" №3
	+ чем больше entitys в области видимости, тем медленнее этот метод работает
@todo 
	- оптимизация queryBoundingBox, использовать точную проверку колизии из require("code.physics")
	- увеличить прямоугольник require("code.physics").world:queryBoundingBox()
		- потому что если skipMax включет, то может быть вероятность внезапного появления объекта в на экране, т.е. буфер не успеет обработать появление объекта в "поле рисования"
--]]
thisModule.db.skip = {}
thisModule.db.skip.counterDo = 0																												-- 0
thisModule.db.skip.doMax = 1																													-- 1...~; выполнять минимум 1 раз
thisModule.db.skip.counterSkip = 0																												-- 0
thisModule.db.skip.skipMax = 0																													-- 0...2; сколько раз пропустить
thisModule.db.skip.skiped = false																												-- чтобы во время пропуска можно было выполнять другой код
thisModule.db.debug = {}
thisModule.db.debug.update = {}
thisModule.db.debug.update.timer = {}
thisModule.db.debug.update.timer.start = 0
thisModule.db.debug.update.timer.result = 0
function thisModule.db:update(dt)
--	if require("code.physics").skip.skipMax > 0 and require("code.physics").skip.skiped then
--		return false
--	end

	if self.skip.counterDo == self.skip.doMax then
		if not (self.skip.counterSkip == self.skip.skipMax) then			
			self.skip.counterSkip = self.skip.counterSkip+1
			self.skip.skiped = true
--			print(os.clock())
			
			return false 
		end
		self.skip.counterDo = 0
	end
	
	self.debug.update.timer.start = love.timer.getTime()	
	
	thisModule.zDBEL:update(dt)
	thisModule.light.eLB.lights = {}
	
	local mPWorld, camera, config = require("code.physics").world, camera, config
	if mPWorld then
		mPWorld:queryBoundingBox(
			camera.x-((config.window.width/2)/camera.scale), 
			camera.y-((config.window.height/2)/camera.scale), 
			camera.x+((config.window.width/2)/camera.scale), 
			camera.y+((config.window.height/2)/camera.scale), 
			self.queryBoundingBoxCallback)
	end
	
	self.debug.update.timer.result = love.timer.getTime()-self.debug.update.timer.start
	
	self.skip.counterSkip = 0
	self.skip.counterDo = self.skip.counterDo+1
	self.skip.skiped = false
end
-- testing example, put in require("code.debug.ui")
--local foo = function()
--	return "db.skip.counterDo = "..tostring(require("code.graphics").db.skip.counterDo)															-- string
--end
--debug.ui.watchList:insertItem({name="db.skip.counterDo = ...", func = foo})
--local foo = function()
--	return "db.skip.counterSkip = "..tostring(require("code.graphics").db.skip.counterSkip)														-- string
--end
--debug.ui.watchList:insertItem({name="db.skip.counterSkip = ...", func = foo})
--local foo = function()
--	return "db.skip.skiped = "..tostring(require("code.graphics").db.skip.skiped)																-- string
--end
--debug.ui.watchList:insertItem({name="db.skip.skiped = ...", func = foo})
--local foo = function()
--	return "db.debug.update.timer.result = "..tostring(math.nSA(require("code.graphics").db.debug.update.timer.result, 0.0001))					-- string
--end
--debug.ui.watchList:insertItem({name="db.debug.update.timer.result = ...", func = foo})

function thisModule:update(dt)
	camera:update(dt)
	self.db:update(dt)
end

function thisModule:draw()

--	if require("code.physics").skip.skipMax > 0 and require("code.physics").skip.skiped then 
--		thisModule.shadows:update()
----		print(love.timer.getFPS())
--	end

	do camera:attach()
		local world = require("code.world")
		if world.images.background then
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.draw(world.images.background, 0, 0)
		end
		self.zDBEL:draw(false, true)     -- test shadows
		self.zDBEL:draw()
		
		-- test
--		love.graphics.setColor(255, 0, 0, 255)
--		love.graphics.print('############## test texts #################', 500)	
		
	camera:detach() end
	
	self.light:draw(1)
	-- ! все что рисуется ниже, то уже рисуется сверху света !
	
	do camera:attach()
		
		if debug:isOn() and debug.draw:isOn() then
			self.zDBEL:draw(true)
		end
		
		--###################################### TESTS
		--[[
		test["code.ai.pathfinding.graph"]:testPath()
		if test["code.ai.pathfinding.graph"] then test["code.ai.pathfinding.graph"]:draw(test["code.ai.pathfinding.graph"].debug.draw.pathfinding.on) end
		love.graphics.circle('fill', 0, 0, 15, 10)
		love.graphics.line(0, 0, -10, -10, -200, -200, -300, -300)
		--]]
		
--		require("code.ai.pathfinding.navMesh"):draw()

--		require("code.math.clipperTest"):draw()

--		require("code.math.delaunayTriangulation.delaunayTriangulationByYonabaTest"):draw()

--		require("code.math.delaunayTriangulation.delaunayTriangulation2Test"):draw()

--		require("code.math.itraykovPoly2Test"):draw()
		
		require("code.physics").test:draw()
		
		--######################################
		
		require("code.worldEditor"):draw()
		
	camera:detach() end
	
	require("code.player"):draw()
	
	require("code.ui"):draw()
	
	debug.draw.func()
	
	--###################################### TESTS
--	math.test:draw()
	
--	love.graphics.draw(mesh, 100, 100)
end

--[[
version 0.1.0
@help 
	+ example: require("code.graphics"):drawArrow(-100, 0, -100, 500, 100, 30)
@todo 
	- рефакторинг
	- поделиться с миром
--]]
function thisModule:drawArrow(x1, y1, x2, y2, headLenght, earLenght)
	headLenght = headLenght or 30
	earLenght = earLenght or 10
	local head = {}
	head.ear = {}
	head.ear[1] = {}
	head.ear[2] = {}	
	local angleLine = math.deg(math.angle(x1,y1, x2,y2))
	
	-- version 1
	if false then
		local vectorL = require('code.hump.vector-light')
		local vx, vy = vectorL.sub(x2, y2, x1, y1)
		local vLenght = vectorL.len(vx, vy)
		vx, vy = vectorL.normalize(vx, vy)
		vx, vy = vectorL.mul(vLenght-headLenght, vx, vy)
		
		head.ear[1].x = (x1+vx) + math.lengthdirX(earLenght/2, angleLine+90)
		head.ear[1].y = (y1+vy) + math.lengthdirY(earLenght/2, angleLine+90)
		head.ear[2].x = (x1+vx) + math.lengthdirX(earLenght/2, angleLine-90)
		head.ear[2].y = (y1+vy) + math.lengthdirY(earLenght/2, angleLine-90)
		
	elseif true then
		-- version 2
		local lenght = math.dist(x1,y1, x2,y2)
		
		head.endPoint = {}
		head.endPoint.x = math.lengthdirX(lenght-headLenght, angleLine)
		head.endPoint.y = math.lengthdirY(lenght-headLenght, angleLine)
		
		head.ear[1].x = (x1+head.endPoint.x) + math.lengthdirX(earLenght/2, angleLine+90)
		head.ear[1].y = (y1+head.endPoint.y) + math.lengthdirY(earLenght/2, angleLine+90)
		head.ear[2].x = (x1+head.endPoint.x) + math.lengthdirX(earLenght/2, angleLine-90)
		head.ear[2].y = (y1+head.endPoint.y) + math.lengthdirY(earLenght/2, angleLine-90)
	end	
	
	love.graphics.line(x1, y1, x2, y2)
	love.graphics.polygon('fill', x2, y2, head.ear[1].x, head.ear[1].y, head.ear[2].x, head.ear[2].y)
end

-- @todo - rename to love.graphics.updateScreen() or thisModule:updateScreen()
function love.updateScreen()
	-- from LOVE 0.10.0 love.run()
	if love.graphics and love.graphics.isActive() then
		love.graphics.clear(love.graphics.getBackgroundColor())
		love.graphics.origin()
		if love.draw then love.draw() end
		love.graphics.present()
	end
end

--################################################################## TESTS
--require("code.graphics.tests")

return thisModule