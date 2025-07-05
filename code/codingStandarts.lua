--[[
	* [https://en.wikipedia.org/wiki/Programming_style](https://en.wikipedia.org/wiki/Programming_style)
		+ [https://ru.wikipedia.org/wiki/Стандарт_оформления_кода](https://ru.wikipedia.org/wiki/%D0%A1%D1%82%D0%B0%D0%BD%D0%B4%D0%B0%D1%80%D1%82_%D0%BE%D1%84%D0%BE%D1%80%D0%BC%D0%BB%D0%B5%D0%BD%D0%B8%D1%8F_%D0%BA%D0%BE%D0%B4%D0%B0)
	* [1. https://github.com/Olivine-Labs/lua-style-guide](https://github.com/Olivine-Labs/lua-style-guide)
	* [https://www.google.by/#newwindow=1&q=coding+standards+lua](https://www.google.by/#newwindow=1&q=coding+standards+lua)
	* [http://lua-users.org/wiki/LuaStyleGuide](http://lua-users.org/wiki/LuaStyleGuide)
	* [http://sputnik.freewisdom.org/en/Coding_Standard](http://sputnik.freewisdom.org/en/Coding_Standard)
	* [90 рекомендаций по стилю написания программ на C++ _ Хабрахабр](https://habrahabr.ru/post/172091/)
	@todo 
		-? с учетом генерации документации
			-? https://github.com/stevedonovan/LDoc
				* [manual](http://stevedonovan.github.io/ldoc/manual/doc.md.html)
			-? [Dox](https://love2d.org/forums/viewtopic.php?f=5&t=82685)
				-? переделать под себя
		- Шаблон проектирования или паттерн
			* https://ru.wikipedia.org/wiki/%D0%A8%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD_%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F
			- антипаттерн
				* https://ru.wikipedia.org/wiki/%D0%90%D0%BD%D1%82%D0%B8%D0%BF%D0%B0%D1%82%D1%82%D0%B5%D1%80%D0%BD
				* http://lurkmore.to/%D0%90%D0%BD%D1%82%D0%B8-%D0%BF%D0%B0%D1%82%D1%82%D0%B5%D1%80%D0%BD
--]]

-- ZeroBrane Studio markdown formatting (https://studio.zerobrane.com/doc-markdown-formatting) #####
--_italic_ = _italic_
--**bold** = **bold**
--[ZeroBrane Studio project](http://studio.zerobrane.com) = [ZeroBrane Studio project](http://studio.zerobrane.com)
--[open file in same tab](F:\Documents\MyGameDevelopment\LOVE\TDS\main.lua) = [ open file in same tab](F:\Documents\MyGameDevelopment\LOVE\TDS\main.lua)
--[open file in new tab](+F:\Documents\MyGameDevelopment\LOVE\TDS\main.lua) = [ open file in new tab](+F:\Documents\MyGameDevelopment\LOVE\TDS\main.lua)
--[[# Section = 
# Section
--]]
--|warning| = |warning|
--##################################################################################################

--[[
	* многостроковый коммент/строка:
			* test = [=[ [==[ test ]==] ]=]
			* --[=[ --[==[ comment ]==] ]=]
		* BUG: двойной многостроковый коммент в zeroBrane обрабатывается, а в LOVE нет
			* нужно применить правило знака "="
--]]

-- виды заголовков
-- MAIN ############################################################################################
-- SECOND ==========================================================================================
-- LOW +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- LOWEST ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- SIMPLE ------------------------------------------------------------------------------------------

-- DOCUMENTATION ###################################################################################
-- My documentation ================================================================================
--[[------------------------------------------------------------------------------------------------
	@name 
	@version 
	@help [
		* [ означает начало вложения в комментариях
			@todo -? сменить на {; но тогда нужно изменить обработку комментариев в ZeroBrane, но это нарушает правила вложенных комментариев
		* ] означает конец вложения в комментариях
			@todo -? сменить на }; но тогда нужно изменить обработку комментариев в ZeroBrane, но это нарушает правила вложенных комментариев
		* символ * означает пункт в комментариях
		* (comments)
		*  --> означает вывод
		* @help (различная помощь) (а нужен ли этот тэг вообще? @todo -?NO везде убрать или переименовать в * )
		* @usage (короткий пример использования)
		* @arg <key> = <value> [
			* @arg <key> = <value>
		]
		* <types> [
			* type <number> (range = x ... n) (default float)
				* type <number int>
			* type <string> (range = one, two, three, ...)
			* type <boolean>
			* type <function>
			* type <table>
				* type table <&table> (reference to table; ссылка на существующую таблицу, т.е. не копия таблицы)
				* type table <object> = Class name of object (@example: <object> = Entity)
				* type table <class> = Class name (@example: <class> = Entity)
			* type <love2d ...>
				* type <love2d Image>
				* ...
			* type <any> (any type)
		]
		* @example ()
		* @short (для быстрого кодинга)
		* @todo [
			* @todo <number> <done><modifers>
			* <number>
				* отрицательные значения имеют больший приоритет, чем положительные значения
					* пример: -1 имеет приоритет над 1
			* <done>
				* type <-> (not done)
				* type <+> (done)
				* type <-+> (unfinished done)
				* type <+-> (need polish)
		]
		* <modifers>
			* Yes
			* No
			* ? (doubt)
			* NotNow
		* @fixme (or @bug)
		@author 
		@license [
			
	]
	]
--]]------------------------------------------------------------------------------------------------

-- шаблон
--[[------------------------------------------------------------------------------------------------
	@version 0.0.1
	@help [
		* @arg arg1 <table> = [
			* @arg arg1.coordinatesSystem <string> = 'global' or 'local' (default 'global') 
		]
		* @return <number>
		* @example [
			* test({coordinatesSystem = 'global'}, 1)
		]
	]
	@todo [
		
	]
--]]------------------------------------------------------------------------------------------------

-- example шапки функции, метода, модуля, программы
--[[------------------------------------------------------------------------------------------------
	@version 0.0.1
	@help [
		* @arg arg1 <table> = [
			* @arg arg1.coordinatesSystem <string> = 'global' or 'local' (default 'global')
		]
		* @arg arg2 <number> <nil> = 1 ... 10
		* @return <number>
		* @example [
			* test({coordinatesSystem = 'global'}, 1)
		]
	@author Савощенко Антон Александрович
	]
	@todo [
		@fixme 1 - bla bla bla ...
		@todo 1 - work ...
			@todo 1.1 -+ work ...
	]
--]]------------------------------------------------------------------------------------------------
function test(arg1, arg2)  -- @usageFunc test({coordinatesSystem = 'global'}, 1)  -- @return <number>
	
	
	return 1
end

--[[
	* имя переменной ссылающейся на модуль должно начинаться с маленькой буквы
	* файл модуля должен иметь имя с маленькой буквы
	* в каждом модуле имя локальной возвращаемой модульной таблицы именовать в thisModule 
	* рефакторинг кода
		* в модулях лучше меньше делать внешних зависимостей	
	* оптимизация
		* "не ссылочные" - это number, boolean
		* "ссылочные" - это table, function, string, userdata, thread, class, object
		* "ссылочные" локальные изменяемые переменные не нужно "глобализировать", чтобы память не прыгала
		* "ссылочные" локальные неизменяемые переменные нужно "глобализировать", чтобы память не прыгала
		* "не ссылочные" локальные переменные нужно "глобализировать", чтобы память не прыгала
	* не использовать DESDOC.odt, а писать в DESDOC.txt
	* стараться использовать один тип в переменной вместо нескольких, т.е. variable <number> <nil>, вместо variable <number> <string> <nil>
--]]


















