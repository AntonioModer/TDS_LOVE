if arg[#arg] == "-debug" then require("mobdebug").start() end																							-- ZeroBraneStudio debuger

print('noGameMode \n')





local timer = 0
local tm = {result = 0} -- среднее значение тестов
local ii = 0
local i1i = 100000000

-- PRE TESTS ----------------


--[[
--local math = math                                           -- локальная переменная ускоряет выполнение на 0.02 sec
local cos = math.cos                                          -- локальная переменная ускоряет выполнение на 0.16 sec

local class = {math = math}
function class.test(self, x)
	
--	if self.destroyed then                                  -- тормозить выполнение на 0.15 sec
		
--	end
	
--	local math = math                                       -- локальная переменная тормозить выполнение на 0.03 sec
	for i=1, 10 do
		cos(x)                                  			-- self.math.cos(x) тормозить выполнение на 0.07 sec по сравнению с math.cos(x)
	end
end
--]]

--[[
local mt = {}
mt.t = {}
mt.t.t = {}
mt.t.t.__index = mt

local function func(self, arg)

	for i=1, 10 do
		self.test = math.cos(arg)
	end
	
	return arg
end
mt.__call = func

local tab = {}
setmetatable(tab, mt)

--]]

----[[

local mt = {}
mt.t = {}
setmetatable(mt.t, mt.t)

--mt.t.__index = mt.t
function mt.t:__call(arg1, arg2, arg3)
	print(self, arg1, arg2, arg3)
end



print("mt.t = " .. tostring(mt.t), ", mt = " .. tostring(mt))

-- if use mt.t.__call(...) then print 2 argument: mt.t, 1
-- if use mt.t:__call(...) then print 1 argument: 1
--mt.t(1)

-- if use mt.t.__call(...) then print argument: nil, mt.t, mt, 1
-- if use mt.t:__call(...) then print argument: mt.t, mt, 1, nil
mt:t(1)


--]]

--require('code.Class'):test()

--require('code.math')
--local vector = math.vector

--local vector = require("code.math.vectorFFITest")
-----------------------------


for i=1, ii do
	
	
	
	
	timer = os.clock()
--	print(collectgarbage("count"))
	-- TESTS ########################################################
	
--	local math = math       -- локальная переменная тормозить выполнение на 0.06 sec
	
	for i1=1, i1i do
				
		
--		class:test(i1)
		
--		vector(-1, -1):angleTo()
		
		
		


		--[=[
		local ffi = require("ffi")
		ffi.cdef[[
		typedef struct { uint8_t red, green, blue, alpha; } rgba_pixel;
		]]
		local function image_ramp_green(n)
		  local img = ffi.new("rgba_pixel[?]", n)
		  local f = 255/(n-1)
		  for i=0,n-1 do
			img[i].green = i*f
			img[i].alpha = 255
		  end
		  return img
		end
		local function image_to_grey(img, n)
		  for i=0,n-1 do
			local y = 0.3*img[i].red + 0.59*img[i].green + 0.11*img[i].blue
			img[i].red = y; img[i].green = y; img[i].blue = y
		  end
		end
		local N = 400*400
		local img = image_ramp_green(N)
		for i=1,1000 do
		  image_to_grey(img, N)
		end
		--]=]

		--[[
		local floor = math.floor
		local function image_ramp_green(n)
		  local img = {}
		  local f = 255/(n-1)
		  for i=1,n do
			img[i] = { red = 0, green = floor((i-1)*f), blue = 0, alpha = 255 }
		  end
		  return img
		end
		local function image_to_grey(img, n)
		  for i=1,n do
			local y = floor(0.3*img[i].red + 0.59*img[i].green + 0.11*img[i].blue)
			img[i].red = y; img[i].green = y; img[i].blue = y
		  end
		end
		local N = 400*400
		local img = image_ramp_green(N)
		for i=1,1000 do
		  image_to_grey(img, N)
		end
		--]]
		
--		tab:func(1)  -- 4.32520
--		tab(1)       -- 4.38160
		
		
		
		
		
		
	end
--	print(collectgarbage("count"))
	timer = os.clock()-timer
	tm[i] = timer
	print(string.format(i .. " result time: %0.5f", timer))
end

for i=1, ii do
	tm.result = tm.result+tm[i]
end
tm.result = tm.result/ii

-- INFO: clear i=1000000000 -> 0.3 sec
print(string.format("result time middle: %0.5f", tm.result))

-----------------------------------------------------------
print()

--------------
--local ffi = require("ffi")
--ffi.cdef [[struct vector { double x, y;};]]
--local new = ffi.new("struct vector")
--local test = ffi.typeof("struct vector")
--print(new, test, ffi.istype(new, test))
--local test2 = test()
----test2.x = -678
--print(test2.x, test2.y)
--local mt = {}
--mt.__index = mt
--local test = setmetatable({}, mt)
--ffi.metatype(new, mt)
----test.x = 1111
--print(new, getmetatable(test), ffi.istype(new, test))

--------------------
--local ffi = require("ffi")
--local vector = require("code.math.vectorFFITest")
--local v = vector()
----v.x = '67'
--print(vector.isvector(v), ffi.istype(vector.new, v), type(v), type(v.x))

-- const -----------------------
--local ffi = require("ffi")
--ffi.cdef[[
--	struct whatever {
--	    static const int FOO = 42;
--	    static const int BAR = 99;
--		bool VARB;
--	};
--	]]
--local W = ffi.new("struct whatever")
--W.VARB = true
--print(W.FOO, W.BAR, W.VARB)

--[[ пример изменения окружения для Lua 5.1
local M = {}
_ENV = M  -- не обязательно
local _G = _G
setfenv(1, _ENV)

M.testVar = 'testVar'
function testFunc()
	
end
--testFunc = _G.setfenv(testFunc, _ENV)

_G.print(_G, _G.getfenv(1))
_G.print(testFunc, _G.testFunc)
_G.print(testVar, _G.testVar)
--]]

--[[ coroutine
if arg[#arg] == "-debug" then require("mobdebug").start() end																							-- ZeroBraneStudio debuger

local function func1(arg)
	print(string.format("coroutine.status(%q) ->", tostring(coroutine.running())), coroutine.status(coroutine.running()))
	print(string.format("coroutine.yeld %q ->", tostring(coroutine.running())), coroutine.yield("yeld return by " .. tostring(coroutine.running()) .. ": ", arg))
	print("pint by func1:", arg)
	return 'return by func1'
end
local function func2(arg)
	print(string.format("coroutine.status(%q) ->", tostring(coroutine.running())), coroutine.status(coroutine.running()))
	print(string.format("coroutine.yeld %q ->", tostring(coroutine.running())), coroutine.yield("yeld return by " .. tostring(coroutine.running()) .. ": ", arg))
	print("pint by func2:", arg)
	
	return 'return by func2'
end

local cor1 = coroutine.create(func1)
print("coroutine.create cor1 ->", cor1)
local cor2 = coroutine.create(func2)
print("coroutine.create cor2 ->", cor2)
print()

--[=[ работает одна coroutine
print("coroutine.status(cor1) ->", coroutine.status(cor1))
print("coroutine.resume(cor1) ->", coroutine.resume(cor1, 'resume1'))
print("coroutine.running ->", coroutine.running())
print("coroutine.status(cor1) ->", coroutine.status(cor1))
print("coroutine.resume(cor1) ->", coroutine.resume(cor1))
print("coroutine.status(cor1) ->", coroutine.status(cor1))
print("coroutine.resume(cor1) ->", coroutine.resume(cor1, 'resume3'))
--]=]

----[=[ работают две coroutine

--]=]

--]]

require("code.sound")









