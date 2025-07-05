--[[
version 0.1.3
@help 
	+ tableToString(table [, depthScanning])
	+ ограничения бесконечного цикла
		+ не сканирует ссылки на _G
			+ может сканировать только саму _G
	+ сканирует таблицу до определенного уровня подтаблиц (глубина сканирования, depth scanning - ids)
	-NO использовать rawget()
		-NO добавить параметр отвечающий за использование rawget()
		+SOLUTION не нужно, т.к. pairs() использует rawget()
	+ проблема бесконечного цикла сканирования таблиц
		+SOLUTION INFO невозможно записывать в файл ссылки на другие таблицы, можно только конструкторы таблиц
		-NO нужно помечать отсканированные таблицы; если таблица уже отсканированна, то записывать в файл только их ссылки
		+ добавить ограничения	
--]]
local function tableToString(t, ids, _it)
	if not (type(t) == 'table' or type(t) == 'class' or type(t) == 'object') then
		error([[function argument must be "table" type]])
	end
	local ids = ids or 0																														-- index depth scanning; -1 is infinite
	local _it = _it or 1																														-- index tabulation count; private
	local _string = ""
	_string = _string.."{"
	local indexCount, indexCounter = 0, 0
	for k, v in pairs(t) do
		indexCount = indexCount+1
	end
	for k, v in pairs(t) do
		indexCounter = indexCounter + 1
		_string = _string.."\n"
		for i=1, _it do
			_string = _string.."\t"
		end
		if type(k) == 'number' then
			_string = _string.."["..k.."] = "
		elseif type(k) == 'string' then
			_string = _string.."["..string.format("%q", k).."] = "		
		elseif type(k) == 'boolean' then
			_string = _string.."["..tostring(k).."] = "	
		else
			_string = _string.."["..string.format("%q", tostring(k)).."] = "	
		end			
		if type(v) == 'number' then
			_string = _string..v																												-- or: _string = _string..string.format("%a", v)
		elseif type(v) == 'string' then
			_string = _string.."[["..v.."]]"																									-- or: _string = _string..string.format("%q", v)
		elseif type(v) == 'boolean' then
			_string = _string..tostring(v)
		elseif type(v) == 'table' or type(v) == 'class' or type(v) == 'object' then
			if v == _G then
				_string = _string.."[[".."tableToString(): limitation, infinity scan loop; "..tostring(v).."]]"
			else
				if ids > 0 then
					_string = _string..tableToString(v, ids-1, _it+1)
				elseif ids == -1 then
					_string = _string..tableToString(v, ids, _it+1)
				else
					_string = _string.."[[".."tableToString(): limit the depth of the scan; "..tostring(v).."]]"
				end
			end
		else
			_string = _string.."[["..tostring(v).."]]"
		end
		if indexCounter ~= indexCount then
			_string = _string..","
		end
	end
	_string = _string.."\n"
	if _it > 1 then
		for i1=1, _it do
			_string = _string.."\t"
		end
	end
	_string = _string.."}"
--	print('tableToString(): scan ...')																				-- debug
	return _string
end

return tableToString