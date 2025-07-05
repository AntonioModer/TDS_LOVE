--[[
	Copyright (c) Савощенко Антон Александрович, 2013-2016  
	Запрещается любое использование этого программного кода без согласия автора.
--]]
--[[------------------------------------------------------------------------------------------------
	@name AMClass (AntonioModerClass)
	@version 0.2.3
	@help [
		+ based on prototype meta system from book: "Programming in Lua 3rd Edition" by Roberto Ierusalimschy, chapter 16 (https://www.lua.org/pil/#3ed)
		+ Class - superclass, который является родителем всех классов
		+!!! при любом обращении к объекту или Классу необходимо проверять не уничтожен ли он
		+ все Классы (кроме суперкласса Class) должны быть в папке с именем "classes"
		+ только имя переменной ссылающейся на класс и имя файла класса должно начинаться с большой буквы, это нужно для лучшего понимания кода
		+ имеет базовое наследование, может быть только один класс-родитель
		+ все переменные и методы:
			+ encapsulation: private, protected, public
				+ private является истинно закрытым типом
				+ protected имеет знак подчеркивания перед именем (_) и не является закрытым типом, аналогичен public
			+ по умолчанию являются статическими и не создаются в памяти нового объекта или нового класса, или класса-потомка
			+ при переопределении создаются в памяти
			+ являются значением по умолчанию, которое определено в классе или классе-потомке
			+ их можно переопределять в определении нового класса-потомка
			+ в объекте переопределять лучше только переменные, методы не желательно, для избежания ошибок
		+ объект будет существовать пока он есть в классе; чтобы удалить объект необходимо удалить его из класса
		+ метод: удаление объекта
			+ выяснить почему часть памяти не удаляется после сборки мусора
				* нужно полностью удалить таблицу объектов из класса и внешние слабые таблицы-ссылки на объекты	
		+ метод: удаление класса
			+ если класс является родителем, то можно его удалять?
				+ нельзя	
		+ слабые ссылки
			+ нельзя использовать слабые таблицы с числовым ключом, т.к. если сборщик удалит значение (nil), то нельзя будет корректно работать с такой таблицей (смотри table.lua "подводный камень 1" и http://www.lua.org/manual/5.1/manual.html#2.5.5)
			+ все ссылки на объект вне класса желательно должны быть значением слабой таблицы
			-?NO класс должен знать свою внешнюю слабую таблицу			
		+ достоинства:
			+ не нужно контролировать вручную наследование переменных в каждом наследнике
			+ в наследнике из-за _index память под несуществующие переменные не выделяется, если не присвоить им значения
		+ недостатки:
			+? необходимо делать для каждого объекта дополнительную метатаблицу, что увеличивает память
				+ передается ссылка и память вроде не увеличивается
		+ везде проверять не удален ли объект; в каждом методе класса: если удален то выводить ошибку
			* последствие: если Класс удален, то для всех его Объектов: <self.destroyed = true>, т.е. все Объекты этого класса будут считаться удаленными, даже если они (и Класс) есть в памяти
		+ разобраться как работать с readonly variables
			-NO с помощью методов
				- проблемы с наследованием
				- медленно
					- можно ускорить с помощью локальных переменных, то тогда память возрастет
				- нужно переводить в private
			+YES просто в коментарии помечать
				- можно сделать ошибку забыв какая переменная
			-NO ввести таблицу readOnly, ro
				- проблемы с наследованием
				- нужно создавать новую таблицу
				- может случится путаница
			@todo 1 -?YES писать в имени переменной приставку ro_
				- проблемы с наследованием
				- некрасиво
				- может случится путаница
				- примеры: ro_varName, _ro_varName, __ro_varName
				- нужно переименовать везде в коде
		+ почему переменная destroyed только здесь?
			* потому что так верно, она нужна только когда true, а так она = nil
	]
	@todo [
		+? не нужно делать этого: учет _objectsCount сделать опциональным (или, на крайний случай, убрать отсюда и перенести в Entity) (чтобы не было зависимости от числа)
			* _objectsCount может достигнуть math.huge, но это не страшно, т.к. (math.huge > 0)	
		-+ изучить метатаблицы глубже
			@todo -? применять для создания объекта setmetatable, __call
		@todo -? выбор: будет ли объект существовать в классе(чтобы удалить объект необходимо удалить его из класса) или вне его
			-? параметр, чтобы объект не сохранялся в Классе
		-? во всех методах аргументы должны передаваться таблицей: method({arg1=1, arg2=2})
			* чтобы легче было работать с components в Entity
		- _TABLETYPE оптимизация памяти
			-? вместо строк использовать статические переменные в Классе _typeObject = true, _typeClass = true
				* если одновременно _typeObject = true, _typeClass = true, то это Класс
				* если rawget(_typeObject) == true, rawget(_typeClass) == false, то это объект
				- и переписать _G.type()
			-? не использовать в каждом объекте переменную _TABLETYPE, а использовать статическую переменную в Классе _typeObject = true;
				- недостаток нельзя будет определить что это тип "class"
					- для класса нужно делать отдельные методы
		+ переименовать _type в: __type или _luaType или _TABLETYPE (_prototypeType)
			-NO или перенести private переменную type в метод type(), нужна также setType()
		- рефакторинг кода
			- во всех исходных файлах классов написать в коментах "static/nonstatic" где надо
		-? узнать, есть ли определенный родитель у много-дочернего объекта (ThisModule:findParent(parentName))
		-? заменить type(self) на self._type, для оптимизации
		-?NO указывать в какой таблице хранить объекты и их количество
		- переименовать переменные в нормальные имена: из переменных убрать my
		- в объекте variables nonstatic private как именовать?
			-? добавлять приставку __ (пример: object.__privateVar)
				* нужно учитывать встроенные в Lua имена переменных метатаблиц, чтобы случайно их не повредить: __add, __len, __call, ...
	]
--]]------------------------------------------------------------------------------------------------

local ThisModule = {}                                                                                                                           -- reserved

-- variables static private ########################################################################
-- ...

-- variables static protected, only in Class #######################################################
ThisModule._TABLETYPE = 'class'                                                                                                                 -- reserved; assignment only in this Class; prototype type
ThisModule._myClassName = string.sub(..., string.find(..., "Class"), -1)                                                                        -- reserved; assignment only in this Class
ThisModule._myModuleName = ...                                                                                                                  -- reserved; assignment only in this Class
ThisModule._objects = {}                                                                                                                        -- reserved; assignment only in this Class
ThisModule._objectsCount = 0                                                                                                                    -- reserved; assignment only in this Class

-- variables static public #########################################################################

-- INFO: -NO переименовать в notDestroyed и поменять значение на противоположное; т.к. не удобно писать: if not object.destroyed then
ThisModule.destroyed = false                                                                                                                    -- reserved; |readonly!!! out Classes|; assignment only in this Class; for optimazition, instead of slow method isDestroyed()

-- methods static private ##########################################################################
-- ...

-- methods static protected ########################################################################

-- @arg moduleName <string>
-- @return <class>
function ThisModule:_newClass(moduleName)                                                                                                       -- reserved; assignment only in this Class; use only in assignment of NewClass
    if self.destroyed then self:destroyedError() end
	
	if type(self) == 'class' then
		local class = {}
		
		-- nonstatic variables, methods
		class._TABLETYPE = 'class'
		class._myModuleName = moduleName
		class._myClassName = string.sub(moduleName, string.find(moduleName, "classes")+8, -1)
		class._myClassParent = self
		class._objects = {}
		class._objectsCount = 0
		class.destroyed = false
		
		setmetatable(class, self)
		self.__index = self
		
		return class 		
	else
		error([[table must be 'class' type, not ']]..type(self)..[[' type]])
	end	
end

-- methods static public ###########################################################################

-- super-method
-- @arg arg <table> <nil>
-- @return <object>
function ThisModule:newObject(arg)                                                                                                              -- reserved; assignment only in this Class; use only outside the Class definition
    if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	
	if type(self) == 'class' then
		local object = {}
		
		object._TABLETYPE = 'object'                                                                                                            -- nonstatic variable
		self._objects[object] = object                                                                                                          -- static variable
		self._objectsCount = self._objectsCount + 1	                                                                                            -- static variable
		
		setmetatable(object, self)
		self.__index = self
		
--		print(self._myClassName..' create new object:', object)                                                                                 -- debug
		
		return object
	else
		error([[table must be 'class' type, not ']]..type(self)..[[' type]])
	end	

end

-- @return <string>
function ThisModule:getModuleName()                                                                                                             -- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	
	return self._myModuleName
end

-- @return <class>
function ThisModule:getClass()                                                                                                                  -- reserved; assignment only in this Class; use only for object
    if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	
	if type(self) == 'object' then
		return getmetatable(self)
	else
		error([[table must be 'object' type, not ']]..type(self)..[[' type]])
	end
end

-- @return <class>
function ThisModule:getClassParent()                                                                                                            -- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	
	return self._myClassParent
end

-- @return <string>
function ThisModule:getClassName()                                                                                                              -- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	
	return self._myClassName
end

-- @return <string>
function ThisModule:getClassParentName()                                                                                                        -- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	
	local parent = self:getClassParent()
	if parent then
		return parent:getClassName()
	else
		return nil
	end
end

-- @return <number int>
function ThisModule:getObjectsCount()                                                                                                           -- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	
	return self._objectsCount
end

--[[
	@help 
		* удаление из класса (разрушение)
		* разрушение объекта не гарантирует удаление объекта из памяти, т.к. может существовать внешняя ссылка на объект
		+?NO разрушенный объект нельзя использовать (как с love.physics.body)
			+ с помощью метатаблицы
			+ при любом действии над объектом выдавать ошибку
			* нет, потому что при обращении к существующей переменной (rawget()) в destroyed-объекте нельзя сделать вызов ошибки, т.к. есть только __index и __newindex, а они этого не могут обеспечить	
--]]
function ThisModule:destroy()                                                                                                                   -- reserved; assignment only in this Class; use only for object
--	if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	if self.destroyed then return false end
	
	if type(self) == 'object' then
		local selfClass = self:getClass()
		selfClass._objects[self] = nil
		if selfClass._objectsCount > 0 then
			selfClass._objectsCount = selfClass._objectsCount - 1
		end
		self.destroyed = true
		
		-- разрушенный объект нельзя использовать (этот код не используется); оставить в коментах для информации
--		setmetatable(self, --nil
--		{
--			__index = function() error([[access denied, object is destoyed]]) end,
--			__newindex = function() error([[assignment denied, object is destoyed]]) end
--		}
--		)
	elseif type(self) == 'class' then
		self.destroyed = true
		package.loaded[self._myModuleName] = nil
	else
		error([[table must be 'object' or 'class' type, not ']]..type(self)..[[' type]])
	end
end

--[[
	@help 
		+ оптимизация: этот метод заменен на переменную destroyed
		+ чтобы проверить разрушен ли объект:
			+ if object and object.destroyed then print('object is destroyed') end
			+ или: if type(object) == "object" and object.destroyed then print('object is destroyed') end
			+ или оптимизированный: if object._TABLETYPE == "object" and object.destroyed then print('object is destroyed') end
		+ имя isDestroyed, т.к. может существовать внешняя ссылка на объект и он может существовать вне класса
--]]
--[=[
function ThisModule:isDestroyed()
	if self.destroyed then self:destroyedError() end

	if type(self) == 'object' then
		if self:getClass()._objects[self] then
			return false
		else
			return true
		end
	elseif type(self) == 'class' then
		if package.loaded[self._myModuleName] then
			return false
		else
			return true
		end		
	else
		error([[table must be 'object' type, not ']]..type(self)..[[' type]])
	end		
end
--]=]

function ThisModule:destroyedError()
	error('Attempt to use destroyed '..self._TABLETYPE..'.')
end

-- не использую эту функцию из-за соображения скорости кода, т.к. функция выполняется медленее условия (if then), а разница в удобности и наглядности небольшая
function ThisModule:errorIfDestroyed()
	if self.destroyed then self:destroyedError() end
end

-- @arg individualForEachObject <boolean> <nil> (default <nil>)
function ThisModule:destroyAllObjectsFromClass(individualForEachObject)                                                                         -- reserved; assignment only in this Class
    if self.destroyed then self:destroyedError() end                                                                                            -- reserved
	
	if self._objectsCount == 0 then return false end
	if type(self) == 'object' then
		self = self:getClass()
	end
	if individualForEachObject then
		for k, object in pairs(self._objects) do
			object:destroy()
		end
	end
	self._objects = {}
	self._objectsCount = 0
end

--[[
	@help 
		* использовать только в короткосуществующей ссылке !!!
		+NO возвращает таблицу "только для чтения"
		@return <&table> = (ссылка на существующую рабочую таблицу !!! пользоваться осторожно)
			* [key <object>] = value <object> (key == value)
--]]
function ThisModule:getAllObjects()
	-- make this table read-only 
	local proxy = {}
	setmetatable(proxy, 
		{
			__index = self._objects,                                                                                                            -- this table
			__newindex = function (t, k, v)
				error("attempt to update a read-only table", 2)
			end
		}
	)
	return self._objects
end

-- @arg existsTable <table> <nil>
-- @return <nil> (if existsTable <table>) <table> (if existsTable <nil>)
-- @usage require("code.Class"):newObjectsWeakTable()
-- @todo - rename to newWeakTableObjects
function ThisModule:newObjectsWeakTable(existsTable)                                                                                                  -- reserved; for objects
	return setmetatable(existsTable or {}, { __mode = "kv" })
end

function ThisModule:test()
	print('AMMetaClass test start')

	
	local tab = setmetatable({destroyed = false}, 
		{ __call = function(_, ...) print('test __call', _, ...) end,
			__index = {_TABLETYPE = 'test _TABLETYPE'},  -- function() print([[test __index]]) end,
			__newindex = function() print([[test __newindex]]) end,
			__len = function() print([[test __len]]) return 'test __len' end                                                                    -- не работает в Lua 5.1, luajit -DLUAJIT_ENABLE_LUA52COMPAT
			--, _TABLETYPE = 'test _TABLETYPE' -- not work
	})
	print(tab)
	tab(1, 2, 3, 4)
	print('-------')
	print(tab.destroyed1)
	tab.destroyed1 = true
	print('-------')
	print(tab.destroyed)
	tab.destroyed = true
	print('-------')
	print(type(tab))
	print(#tab)
	print('-------')
	
	print('AMMetaClass test end')
end

function ThisModule:examples()
	print('AMMetaClass examples start')
	
	local object = require('code.classes.ClassTemplate'):newObject({x=1, y=1})
	print('static publicVar in Class:', object:getClass().publicVar)
	print('publicVar in object:', object.publicVar)
	print('static x in Class:', object:getClass().x)
	print('x in object:', object.x)
	
	print('AMMetaClass examples end')
end

return ThisModule                                                                                                                               -- reserved