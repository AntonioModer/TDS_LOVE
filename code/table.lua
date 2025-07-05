--[[
version 0.0.1
@help 
	+ тут будет всё касаемо Lua таблиц
--]]

--print("table.lua start test")

--[[

-- пример "подводный камень 1"
-- nil в таблице с числовым ключом означает "конец таблицы" для выражения ipairs() и определение длинны таблицы (#)
local tab = {1, 2, 3}
tab[2] = nil
print('#tab = ', #tab)			
for i, v in ipairs(tab) do		
	print(v)
end

-- результат выполнения:
--> #tab = 1
--> 1
--]]


--[[

local tab = {1, 2, 3}
tab[1] = nil
--tab[2] = nil
tab[3] = nil
--for i, v in pairs(tab) do		
--	print(v)
--end
for i=1, #tab do		
	print(i, tab[i])
end

--]]

--print("table.lua end test")
