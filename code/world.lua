--[[
version 0.1.5
@help 
	+ 
@todo 
	@todo 1 -+ scene system
		-+ таже система что и world
		-+ загружать в мир отдельные scene
			-+ так же как и world просто не нужно: ничего удалять из мира, переименовывать мир
		-?YES удалять scene из world
			- тогда нужно знать какие Entity этот scene создал, знать их ссылки
		-?NO убрать world:load()
		@help можно запустить несколько игр и редактировать отдельные scene, а в другой игре перезагружать мир или отдельные scene в реальном времени
		- в World editor
	-? вынести в глобальную world
	-? как в GTA5
	@todo 2 -+ цельность мира
		- с уровнями
		-+YES один
		-? с фоновой загрузкой объектов
		+ разобраться с производительностью [
			+ тестировать мир с огромным количеством физических объектов
				+ ... статических, ... динамических непулевых спящих, ... динамических непулевых неспящих, ... динамических пулевых неспящих штук
					+ сенсоры
						+ статические
						+ динамические
						+ узнать отличия сенсора динамического от сенсора статического
							+ применить импульс, и посмотреть на движения
								@help есть движение у динамических, нету движения у статических
							@help сенсоры только не участвуют в коллизии, а остальное поведение аналогично
				@todo 2.1 -+!!!оптимизация: не нужно делать много статических Box2d-objects, если можно сделать один статический Box2d-object и присваивать ему статические шейпы
					-! прочитать документацмю Box2d, что такое фикстуры, как колизия обрабатывается
					-! протестировать производительность при столкновениях
					-?NO сделать компиляцию world, где все статические объекты объединяются в один объект
						@help минус: нету быстроты, в реальном времени редактирования мира
					- нужен специальный объект или класс "Статическая геометрия мира"
					- как изменять шейпы?
						- YES полигональные и прямоугольные шейпы нельзя изменять из LOVE API, можно поробовать удалять и делать новые измененные, но это не совсем корректно
						- круг можно передвигать, менять радиус
						- как поворачивать полигональные шейпы?
							- нужен специальный алгоритм поворота
					- разобраться как рисовать
						- fixtures в одном объекте
						- текстуры для fixtures в одном объекте
						- variants
							- использовать setUserData() для fixture; одна фикстура, один объект
								- проверять при рисовании параметр, если есть параметр в фикстуре. то берем ссылку на энтити из него, иначе из Box2d-object
								- тогда нельзя создавать в Entity Box2d-object
								-! проблемы с углом поворота, т.к. угол зависит от Box2d-object
									- создать новый параметр
								-?NO создать компонент для entity
							- рисовать в самом энтити
								- минус: лишний код проверки какие фикстуры в кадре
					- как добавлять новые шейпы к объекту
				+ составить отчет
					-?NO с помощью "монитора ресурсов"
					+ сколько штук физики?
						@help 100000 статических спящих fixtures, 1000 динамических непулевых спящих объектов, 1000 динамических непулевых неспящих объектов,
						  1000 динамических пулевых неспящих штук объектов, 10000 статических спящих объектов сенсоров
					+ фпс
						@help в среднем 140
					+ лаги есть?
						@help нет
					+ нагрузка на процессор
						+ задержка
							@help 0.01 сек
						+ нагрузка на ядра процессора
							@help в основном жрет одно ядро и чуть от других ядер
						+ % загрузки процессора
							@help 30% программа в диспетчере
					+ памяти сколько
						@help 140 Mb программа в диспетчере, 18600 Kb Lua
					@help большое количество Box2d-объектов снижает производительность
					@help динамические объекты больше жрут, чем статические
					@help ВЫВОД: производительность удовлетворительная
			-? оптимизация: много Box2d-worlds, каждый мир обновляется в своем потоке
		]
		- размер мира
			-? машины
				- нет, но в будущем может быть, размер = 5 км, т.к. скорость хотьбы 5 км/ч, 1 км можно пройти за 12 мин.; всю территорию можно пройти пешком примерно за  25 часов, 
				  т.к. (5км*5км) / (5 км/ч) = 5 часов*5
	- background
		-? тайловый
		-+YES? из цельного изображения
			- В zip на 5 км. нужно максимум 300 Мб места на диске с .png, с .dds меньше – где-то 170 Мб
			-? разрезать изображение на квадраты
		-? декальный?
	-? matrix
	-? objects
	-+ загрузка
		-+ явная
		- фоновая
		+ error: main function has more than 65536 constants
		-+ entitys
	-+ сохранение
		-+ в .lua
			-+ entitys
				-?NO энтити существует вне world
					- запоминать их в Классе и в world, т.к. это более гибко и меньше проблем в будущем, хотя память кушает (не много)
						- нужно при создании энтити добавлять её также в world
						- нужно при удалении энтити удалять её также из world
				+YES энтити существует в world
					-?NO запоминать их (Entity objects) в World, чем в их Классе, т.к. entity существуют только в определенном мире и когда мира нет, то и всех энтити из этого мира исчезают
					  (как в Box2d (body = love.physics.newBody( world, x, y, type )), body создается в определенном мире)
					+?YES запоминать Классы в world			
	-+ World editor
--]]

local thisModule = {}

thisModule.mainFolderPath = [[resources/worlds/]]
thisModule.images = {}
thisModule.images.background = false
thisModule.loaded = false
thisModule.loadingNow = false                                                                                                                   -- @todo 0
thisModule.name = ''
thisModule.meter = 64                                                                                                                           -- |readonly!!!| in pixels

--[[
@help 
	+ thisModule.EntityClasses = {}
	  thisModule.EntityClasses.ClassName = <ссылка на Класс>
	+ смотри EntityClass  
--]]
thisModule.EntityClasses = {}

-- @todo - подумать как можно обойти "error: main function has more than 65536 constants", при том чтобы не грузить каждую строчку, а чтобы выполнять любой код из файла
-- @todo 1.1 - argument likeScene, сделать врапер для scene, чтобы не копировать эту функцию в scene
function thisModule:load(name)
	print('start loading world')
	
	thisModule:clear()
	
	require("code.physics"):newWorld()
	
	thisModule.name = name
	
	do
		local ok, out = true
		
--		require(thisModule.mainFolderPath..name.."."..name)                                                                                     -- or (error: main function has more than 65536 constants)
		
	--	dofile(thisModule.mainFolderPath..name.."/"..name..".lua")                                                                              -- or (error: main function has more than 65536 constants)

	--	assert(loadfile(thisModule.mainFolderPath..name.."/"..name..".lua"))()                                                                  -- or (error: main function has more than 65536 constants)

	--	local file = assert(loadfile(thisModule.mainFolderPath..name.."/"..name..".lua"))                                                       -- or (error: main function has more than 65536 constants)
	--	file()	
		
		-- +ANTIBUG error: main function has more than 65536 constants
		local file, err = io.open(thisModule.mainFolderPath..name.."/"..name..".lua", 'r')
		if err then
			print("load file world error: "..err)
			thisModule.loaded = false
			return false
		end
		local lineNumber = 0
		for line in file:lines() do
			lineNumber = lineNumber+1
			ok, out = pcall(function() assert(loadstring(line))() end)
			if not ok then
				print("error: load file world: line number "..lineNumber..';', out, "\n", debug.traceback())
				break
			end
		end
		file:close()
		
		if not ok then
			thisModule.loaded = false
			print("error: load file world")
			return false
		end
	end
	
	self:reloadBackground()
	
	require("code.graphics").light.shadows:deleteTemplightMaps()
	
	thisModule.loaded = true
	print('end loading world')
end

function thisModule:reloadBackground()
	if not self.loaded then
		print("world:reloadBackground(): world background not loaded, world must be loaded")
	end
	
	local filePath = thisModule.mainFolderPath .. self.name .. "/images/" .. self.name .. ".dds"
	if love.filesystem.exists(filePath) then
		thisModule.images.background = love.graphics.newImage(love.image.newCompressedData(filePath), {mipmaps=true})
		thisModule.images.background:setMipmapFilter("linear", 0)	
	end
end

thisModule.scene = {}
thisModule.scene.mainFolderPath = [[resources/scenes/]]
thisModule.scene.loaded = false
function thisModule.scene:load(name)
	print('start loading scene')
	
	self.loaded = false
	
	do
		local ok, out = true
		
		-- +ANTIBUG error: main function has more than 65536 constants
		local file, err = io.open(self.mainFolderPath..name.."/"..name..".lua", 'r')
		if err then
			print("load file scene error: "..err)
			return false
		end
		local lineNumber = 0
		for line in file:lines() do
			lineNumber = lineNumber+1
			ok, out = pcall(function() assert(loadstring(line))() end)
			if not ok then
				print("error: load file scene: line number "..lineNumber..';', out, "\n", debug.traceback())
				break
			end
		end
		file:close()
		
		if not ok then
			print("error: load file scene")
			return false
		end
	end
	
	self.loaded = true
	print('end loading scene')
end

function thisModule:deleteAllEntitys()
	for name, Class in pairs(self.EntityClasses) do		
		Class:destroyAllObjectsFromClass(true)
	end
	self.EntityClasses = {}	
end

function thisModule:clear()
	thisModule.images.background = false
	thisModule.loaded = false
	thisModule.name = ''
	
	thisModule:deleteAllEntitys()

	require("code.physics"):destroyWorld()
	collectgarbage()																											-- обязательно !!!
end

function thisModule:getAllMapsNames()
	return love.filesystem.getDirectoryItems(thisModule.mainFolderPath)
end

--[[
@help 
	+ sourceLevel -> true or (nil or false) (сохранять в папку игры, иначе в папку AppData; когда Editor включен, то sourceLevel = true; если просто сохраняем игру, то sourceLevel = false)
	+ likeScene =  <boolean>
@todo 
	-NO сохранения игры в папку с исходниками
	+ запомнить каждую Entity в saveString
		+ ссылки на Классы брать:
			+YES (легче) ссылки на классы в world
			-?NO (меньше ссылок) по имени модуля из package.loaded
			-+NO вручную
			-?NO из папки "code/classes/Entity/" и подпапок
			-NO или при создании дочернего класса запоминать имя в родительском?
	- делать дубликат перед пересохранением
	@todo 1.2 - argument likeScene
--]]
function thisModule:save(sourceLevel, likeScene)
	local saveString = ''
	
	print("start save world")
	-- очищаем файл
	if sourceLevel then
		require("code.file").write(thisModule.mainFolderPath..thisModule.name.."/"..thisModule.name..".lua", saveString)
	else
		local success;
		if not love.filesystem.exists("save/worlds/"..thisModule.name) then
			success = love.filesystem.createDirectory("save/worlds/"..thisModule.name)
		end	
		success = love.filesystem.write("save/worlds/"..thisModule.name.."/"..thisModule.name..".lua", saveString)
	end
	
	local file, err
	file, err = io.open(thisModule.mainFolderPath..thisModule.name.."/"..thisModule.name..".lua", "a")
	if err then
		print(err)
	end	
	
	for name, Class in pairs(thisModule.EntityClasses) do
		local allObjects = Class:getAllObjects()		
		if Class:getObjectsCount() > 0 then
			for k, obj in pairs(allObjects) do
				if obj.allowToSave then
					-- одна строка = один entity
					obj.saved = true
					saveString = saveString.."\n"..[[require("]]..obj:getModuleName()..[[")]]..":newObject({"..obj:getSavedLuaCode().."})"
					
					-- сохраняем в файл
					if sourceLevel then
						file:write(saveString)
					else
						love.filesystem.append("save/worlds/"..thisModule.name.."/"..thisModule.name..".lua", saveString)
					end
					
					saveString = ''
				end
			end
		end
	end
	
	-- @todo -? это не нужно, убрать
	-- сохраняем в файл
--	if sourceLevel then
--		file:write(saveString)
--	else
--		local success, errormsg;
--		if not love.filesystem.exists("save/worlds/"..thisModule.name) then
--			success = love.filesystem.createDirectory("save/worlds/"..thisModule.name)
--		end	
--		success, errormsg = love.filesystem.append("save/worlds/"..thisModule.name.."/"..thisModule.name..".lua", saveString)
--	end
	
	file:close()
	print('world is saved')																												-- debug
end

-- not done
function thisModule:update(dt)
	for name, Class in pairs(thisModule.EntityClasses) do
		if rawget(Class, 'update') then                                                                                                 -- |!!!| оптимизация, чтобы не перебирать впустую все объекты Класса
			local allObjects = Class:getAllObjects()		
			for k, obj in pairs(allObjects) do
				if obj.allowUpdate and obj.destroyed == false then
					obj:update({dt=dt})
				end
			end
		end
	end
end

-- make this table read-only (indexes is hiden for "pairs()" operator)
local proxy = {}
setmetatable(proxy, 
	{
		__index = thisModule,																									-- this table	
		__newindex = function (t, k, v)
			error("attempt to update a read-only table", 2)
		end
	}
)

function thisModule:test()
	for name, Class in pairs(thisModule.EntityClasses) do
		local allObjects = Class:getAllObjects()		
		for k, obj in pairs(allObjects) do
			if obj.destroyed == false then
				obj:setPosition(obj:getX()+1000, obj:getY()+1000)
			end
		end
	end
end

return thisModule