--[[
version 0.0.5
@help 
	+ у каждого звука нужно выравнивать громкость с помощью Audacity
	+ максимальное количество проигрываемых одновреммено звуков равно 64; maximum love.audio.getSourceCount() == 64; openal max sources
	+ как грузить один звук и проигрывать его много раз одновременно?
		+ source:clone()	
	+ source stream чуть больше нагружает процессор. чем static
	+ шейп звуковой фикстуры может быть любой формы (круг, полигон, прямоугольник)
@todo 
	-? звук на основе физики
	-+ optimization
		+ не каждый раз update()
	-? увеличить максимальное количество проигрываемых одновреммено звуков; openal max sources
	+ разобраться с памятью
		+ проигрывать огромный звук
	@todo -? Класс Sound, но не как Entity
		@help для упрощения кода, API
		-? или методы данного модуля?
			@help тоже не плохо, меньше враперов писать нужно (sound:stop(), pause(), ...)
	@todo -+ как быть со звуками, которые попадают в радиус слуха существа
		@todo 1 -+ доделать более детально
		@todo 1.4 + полигональная шейп звуковой фикстуры
		@todo - всегда знать какие звуки не остановлены (stop()), т.е. они проигрываются или на паузе и считаются в love.audio.getSourceCount()
			-? способ1: тогда нужно переписать love.audio.pause(), ... , и использовать эти функции, LOVE2d методы source:play(), ... не использовать
			-? способ2: Класс Sound сделать и пихать объекты в обычную таблицу
			@help нужно для дебага
			-?NO нужно для остановки звука, чтобы воспроизвести другой, из-за лимита в 64 звука новые звуки не будут проигрываться
		@todo 1.2 -+ спец таблицы-буферы звуков-музыки, звуков-мировых
			-+ внедрить везде
		-+ из-за лимита в 64 звука
			@todo 1.1 + проигрывать всегда ближайшие звуки, а дальние останавливать, если лимит превышен
				+ в thisModule.queryBoundingBoxCallback(fixture)
		@help звук имеет максимальную дистанцию (радиус) "max", где его будет слышно: ref, max = sound:getAttenuationDistances()
			@help эту дистанцию нужно вручную настраивать для каждого звука: sound:setAttenuationDistances()
			-+ работать аналогично как с отрисовкой энтити, только зона колизии вместо вида камеры это точка-слушатель
				@todo 1.5 +? легче работать с World:setCallbacks() ?
					+ нужно делать спец функцию
					@help не легче, работает не правильно, при закрытии игры всегда ошибка вылазит
				-+ для каждого звука сделать box2d sensor радиусом максимальной дистанции
					-+ слушатель - это точка
						-+ если слушатель попадает в радиус звука, то проигрываем звук с определенной временной позиции
						-+ если слушатель выходит из радиуса звука, то останавливаем звук
							-+ с queryBoundingBoxCallback
								+ добавляем звук в список
								-+ проверяем, находится ли слушатель в радиусе звука
									-+ math.pointIncircle(px,py, cx,cy, r)
								+ если нет, то удаляем из списка
		@help координаты звука и слушателя нужно обновлять
			@help координаты слушателя - это координаты существа игрока
			@todo + координаты звука обновлять только когда слушатель в радиусе звука
		-+ звук в энтити
			-+ отдельная фикстура и шэйп
			+ ссылка на звук
			@todo 1.3 + несколько звуков в энтити
			+ удаление (stop())
			- звуковая фикстура-сенсор в дебаге физики
				- параметр: рисовать или нет
				- в конфиге
	- debug
		- on, off
		- from config
		- debug.chart sound: love.audio.getSourceCount()
	- on, off
		- world sounds
		- music
	- set volume
	-+ библиотека звуков
	-BUG1? source static и stream проигрываются с разной громкостью имея одинаковые AttenuationDistances
	- визуальный редактор
		- дальности звучания звука
		- области где звук слышен
			- круглая
			- квадратная
			- полигональная
--]]

local thisModule = {}

love.audio.setVolume(0)

-- sound library ====================================
thisModule.lib = {}

------------------------------------------
love.audio.setDistanceModel('exponentclamped')                               -- none, inverse, inverseclamped(default), linear, linearclamped, exponent, exponentclamped
local meter = require("code.world").meter
thisModule.lib.mono = {}

thisModule.lib.mono.phone = {}
thisModule.lib.mono.phone.filePath = "resources/sound/nabito_phone/60901__nabito__phone_mono.ogg"
thisModule.lib.mono.phone.source = love.audio.newSource(thisModule.lib.mono.phone.filePath)--, 'static') -- BUG1, лучше не делать static
thisModule.lib.mono.phone.source:setAttenuationDistances(meter*3, meter*20)
thisModule.lib.mono.phone.source:setRolloff(3)
--thisModule.lib.mono.phone.source:setVolume(0)

-----------------------------------------------------
thisModule.lib.stereo = {}

thisModule.lib.stereo.thunderstorm = {}
thisModule.lib.stereo.thunderstorm.filePath = "resources/sound/csengeri_thunderstorm/235828__csengeri__thunderstorm-on-2nd-of-may-2014-part-2.mp3"
thisModule.lib.stereo.thunderstorm.source = love.audio.newSource(thisModule.lib.stereo.thunderstorm.filePath)

--=====================================================

-- sound buffers
thisModule.sBWorld = {}
thisModule.sBWorld.buff = {}                     -- thisModule.sBWorld.buff[fixture] = fixture.sound
thisModule.sBWorld.amountMax = 62
thisModule.sBMusic = {}
thisModule.sBMusic.buff = {}
thisModule.sBMusic.amountMax = 2
assert(thisModule.sBWorld.amountMax+thisModule.sBMusic.amountMax <= 64, "attention!!! max amount sounds in buffers must be <= 64")

function thisModule:test()

	if not test.humanoid then return false end

--	test.humanoid.sound = love.audio.newSource("resources/sound/nabito_phone/60901__nabito__phone_mono.ogg")
	test.humanoid.sound = thisModule.lib.mono.phone.source:clone()
	test.humanoid.sound:setLooping(true)
--	test.humanoid.sound:setPitch(1)
--	love.audio.play(test.humanoid.sound)
--	test.humanoid.sound:play()
	
--	print(test.humanoid.sound:getType())
	
	
	
	local shape = love.physics.newCircleShape(0, 0, meter*20)
	local fixture = love.physics.newFixture(test.humanoid.physics.body, shape, 1)																		-- shape копируется при создании fixture
	fixture:setSensor(true)
	
	
	
	
	---------------
	--love.audio.setDistanceModel('exponentclamped')                               -- none, inverse, inverseclamped(default), linear, linearclamped, exponent, exponentclamped

--	local meter = require("code.world").meter
--	local r, m = test.humanoid.sound:getAttenuationDistances()
--	m = meter*30                                                                -- 30 meters is normal

--	test.humanoid.sound:setAttenuationDistances(meter*3, m)
--	test.humanoid.sound:setRolloff(2)
	
	print(test.humanoid.sound:getAttenuationDistances())
	print(test.humanoid.sound:getRolloff())
	-----------------------------
	
	-- @todo -+ разобраться
--	test.humanoid.sound:setCone(3, 3, 0)
--	print(test.humanoid.sound:getCone())
	
	-- @todo -+ разобраться
--	test.humanoid.sound:setDirection(1, 1, 0)
--	print(test.humanoid.sound:getDirection())
	
	-- @todo - разобраться
--	love.audio.setOrientation()
--	print(love.audio.getOrientation())
	
--	print(love.audio.getVolume())
	
	
	
	--[[=================================
	local sound2 = love.audio.newSource("resources/sound/csengeri_thunderstorm/235828__csengeri__thunderstorm-on-2nd-of-may-2014-part-2.mp3", 'static')  -- raw = 333 Mb
	love.audio.play(sound2)
--	sound2:seek(sound2:getDuration()-60)
	love.audio.play(sound2)
	
--	local sound2 = love.audio.newSource("resources/sound/csengeri_thunderstorm/235828__csengeri__thunderstorm-on-2nd-of-may-2014-part-2.mp3", 'static')  -- raw = 333 Mb
--	love.audio.play(sound2)
--	local sound2 = love.audio.newSource("resources/sound/csengeri_thunderstorm/235828__csengeri__thunderstorm-on-2nd-of-may-2014-part-2.mp3", 'static')  -- raw = 333 Mb
--	love.audio.play(sound2)
	--]]
	
	--[[=================================
--	test.soundData = love.sound.newSoundData("resources/sound/csengeri_thunderstorm/235828__csengeri__thunderstorm-on-2nd-of-may-2014-part-2.mp3")
--	print(test.soundData)	
--	test.soundSource = love.audio.newSource("resources/sound/csengeri_thunderstorm/235828__csengeri__thunderstorm-on-2nd-of-may-2014-part-2.mp3")--, 'static')
	
	for i=1, 1000 do
--		test.sound2 = thisModule.lib.stereo.thunderstorm.source:clone()
		test.sound2 = thisModule.lib.mono.phone.source:clone()
--		print(test.sound2:getRolloff())
		test.sound2:setLooping(true)
		test.sound2:play()
--		test.sound2:seek(test.sound2:getDuration()-500)
	end
	
	
	--]]
end

------------------------------------------------------------
local function beginContact(fixture1, fixture2, contact)
	if (not fixture1:isDestroyed()) and fixture1:isSensor() and fixture1:getUserData() and fixture1:getUserData().typeSoundListener == true then
		if (not fixture2:isDestroyed()) and fixture2:isSensor() and fixture2:getUserData() and fixture2:getUserData().typeSound == true then
			print('sound beginContact', os.clock())
			
			local fixtureSound = fixture2:getUserData().sound
			
			local i=0
			for k, v in pairs(thisModule.sBWorld.buff) do
				i=i+1	
			end
			
			local sx, sy = fixture2:getShape():computeMass(1)
			sx, sy = fixture2:getBody():getWorldPoint(sx, sy)
	--			print(sx, sy)
			if i < thisModule.sBWorld.amountMax then
				
				fixtureSound:setPosition(sx, sy)
				
				fixtureSound:play()
	--			sound:setVolume(1)						
				
				thisModule.sBWorld.buff[fixture2] = fixtureSound
			else
				-- если новый звук ближе к слушателю, по сравнению с уже имеющимися, то удаляем самый дальний имеющийся и добавляем новый
				
				-- таблица дистанций
				local tab = {}
				for fixture, sound in pairs(thisModule.sBWorld.buff) do
					local sx, sy = fixture:getShape():computeMass(1)
					sx, sy = fixture:getBody():getWorldPoint(sx, sy)
					sound:setPosition(sx, sy)
					tab[thisModule:getDistance(sound)] = fixture
				end
				
				local maxDis = table.maxn(tab)
				local maxDisFixture = tab[maxDis]
				if thisModule:getDistance(fixtureSound) < maxDis then
					maxDisFixture:getUserData().sound:stop()
					thisModule.sBWorld.buff[maxDisFixture] = nil
					
					thisModule.sBWorld.buff[fixture2] = fixtureSound
					
					fixtureSound:setPosition(sx, sy)
					fixtureSound:play()
		--			sound:setVolume(1)			
	--						print(os.clock())
				end
	--			print(thisModule:getDistance(sound), maxDis)
			end
		end
	end	
end
function thisModule.beginContact(fixture1, fixture2, contact)
	beginContact(fixture1, fixture2, contact)
	beginContact(fixture2, fixture1, contact)
end

local function endContact(fixture1, fixture2, contact)
	if (not fixture1:isDestroyed()) and fixture1:isSensor() and fixture1:getUserData() and fixture1:getUserData().typeSoundListener == true then
		if (not fixture2:isDestroyed()) and fixture2:isSensor() and fixture2:getUserData() and fixture2:getUserData().typeSound == true then
			print('sound endContact', os.clock())
			fixture2:getUserData().sound:stop()
			thisModule.sBWorld.buff[fixture2] = nil
		end
	end
end
function thisModule.endContact(fixture1, fixture2, contact)
	endContact(fixture1, fixture2, contact)
	endContact(fixture2, fixture1, contact)
end

function thisModule:createListener(physicsBody)
	local shape = love.physics.newCircleShape(0, 0, 1)
	local fixture = love.physics.newFixture(physicsBody, shape, 0)																		-- shape копируется при создании fixture
	fixture:setSensor(true)
	fixture:setUserData({typeSoundListener=true, selectedInWorldEditor=false, func={beginContact=thisModule.beginContact, endContact=thisModule.endContact}})
end
-------------------------------------------------------------

-- @todo + вместо энтити звуки
-- thisModule.sBWorld.buff = {}                -- @todo -+ разобраться с памятью
function thisModule.queryBoundingBoxCallback(fixture)
	-- @todo + нужен специальный параметр, определяющий что это сенсор для звука, а то все сенсоры будут проигрывать звук
	if (not fixture:isDestroyed()) and fixture:isSensor() and fixture:getUserData() and fixture:getUserData().typeSound == true and thisModule.sBWorld.buff[fixture] == nil then
		--local entity = fixture:getBody():getUserData()
		--if entity._TABLETYPE == "object" and (not entity.destroyed) and string.find(entity:getClassName(), "Entity") and entity.sounds then
			
			local fixtureSound = fixture:getUserData().sound
			
			local i=0
			for k, v in pairs(thisModule.sBWorld.buff) do
				i=i+1	
			end
			
			local sx, sy = fixture:getShape():computeMass(1)
			sx, sy = fixture:getBody():getWorldPoint(sx, sy)
--			print(sx, sy)
			if i < thisModule.sBWorld.amountMax then
				if fixture:testPoint(game.player.entity:getX(), game.player.entity:getY()) then
				--if math.pointIncircle(game.player.entity:getX(), game.player.entity:getY(), sx, sy, meter*20) then
					
					fixtureSound:setPosition(sx, sy)
					
					fixtureSound:play()
		--			sound:setVolume(1)						
					
					
					thisModule.sBWorld.buff[fixture] = fixtureSound
				end
			else
				if fixture:testPoint(game.player.entity:getX(), game.player.entity:getY()) then
				--if math.pointIncircle(game.player.entity:getX(), game.player.entity:getY(), sx, sy, meter*20) then
					
					fixtureSound:setPosition(sx, sy)
					
					----------------
					-- если новый звук ближе к слушателю, по сравнению с уже имеющимися, то удаляем самый дальний имеющийся и добавляем новый
					
					-- таблица дистанций
					local tab = {}
					for fixture, sound in pairs(thisModule.sBWorld.buff) do
						sx, sy = fixture:getShape():computeMass(1)
						sx, sy = fixture:getBody():getWorldPoint(sx, sy)
						sound:setPosition(sx, sy)
						tab[thisModule:getDistance(sound)] = fixture
					end
					
					local maxDis = table.maxn(tab)
					local maxDisFixture = tab[maxDis]
					if thisModule:getDistance(fixtureSound) < maxDis then
						maxDisFixture:getUserData().sound:stop()
						thisModule.sBWorld.buff[maxDisFixture] = nil
						
						thisModule.sBWorld.buff[fixture] = fixtureSound
						
						fixtureSound:play()
			--			sound:setVolume(1)			
--						print(os.clock())
					end
--					print(thisModule:getDistance(sound), maxDis)
					
				end
			end
			
		--end
	end
	
	return true
end

thisModule.skip = {}
thisModule.skip.counterDo = 0																												-- 0
thisModule.skip.doMax = 1																													-- 1...; выполнять минимум 1 раз
thisModule.skip.counterSkip = 0																												-- 0
thisModule.skip.skipMax = 0																												-- 0...; сколько раз пропустить
thisModule.skip.skiped = false																												-- чтобы во время пропуска можно было выполнять другой код
function thisModule:updateV1(dt)
	if self.skip.counterDo == self.skip.doMax then
		if not (self.skip.counterSkip == self.skip.skipMax) then			
			self.skip.counterSkip = self.skip.counterSkip+1
			self.skip.skiped = true
--			print(os.clock())
			
			return false 
		end
		self.skip.counterDo = 0
	end	
	
	-- проверяем звуки, может ли их слышать слушатель
	require("code.physics").world:queryBoundingBox(game.player.entity:getX()-1, game.player.entity:getY()-1, game.player.entity:getX()+1, game.player.entity:getY()+1, self.queryBoundingBoxCallback)
	
	for fixture, sound in pairs(thisModule.sBWorld.buff) do
		if (not fixture:isDestroyed()) and (not fixture:testPoint(game.player.entity:getX(), game.player.entity:getY())) then
		--if v.destroyed or not math.pointIncircle(game.player.entity:getX(), game.player.entity:getY(), v:getX(), v:getY(), meter*20) then
--			v.sound:pause()
			sound:stop()
--			v.sound:setVolume(0)
			thisModule.sBWorld.buff[fixture] = nil
			
--			print(os.clock())
		end
	end
	
	--[[ debug
	local i=0
	for k, v in pairs(thisModule.sBWorld.buff) do
		i=i+1	
	end
	print(i)
	--]]
	
	self.skip.counterSkip = 0
	self.skip.counterDo = self.skip.counterDo+1
	self.skip.skiped = false	
end

-- @help работает не правильно, при закрытии игры всегда ошибка вылазит
function thisModule:updateV2(dt)
	for fixture, sound in pairs(thisModule.sBWorld.buff) do
		if (not fixture:isDestroyed()) then
			local sx, sy = fixture:getShape():computeMass(1)
			sx, sy = fixture:getBody():getWorldPoint(sx, sy)
			fixture:getUserData()sound:setPosition(sx, sy)
		end
	end
end

function thisModule:getDistance(soundSource)
	local ref, max = soundSource:getAttenuationDistances()
	local sx, sy = soundSource:getPosition()
	
	return math.dist(game.player.entity:getX(), game.player.entity:getY(), sx, sy)
end

return thisModule