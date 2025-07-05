--[[
version 0.0.1
* https://en.wikipedia.org/wiki/Weapon
@todo 
	@todo -+ планирование структуры
	@todo -+ доделать Item, т.к. это родительский класс
	@todo -+ draw
		+ pivot, see "code.graphics.sprite"
		@todo + see "code.graphics.sprite"
	- виды: [
		* https://www.google.by/#newwindow=1&q=class+hierarchy+for+weapons+in+game
			* https://www.gamedev.net/topic/485535-weapon-class-structure/
		@todo - ближнего боя [
			* https://en.wikipedia.org/wiki/Melee_weapon
			- крутая анимация
			- точная физическая модель
			-? с помощью вращения joint
				- момент нанесенияя ущерба
					- когда нажали кнопку, проверяем калбак оружия
					- +:
						- не нужно настраивать для кадого оружия отдельно
						- готовая анимация
					- -:
						- сложная реализация
						- анимация не красивая
			-? универсальный метод для существ "взять предмет в руки"
			-? простая проверка колизии
				- +:
					- простая реализация
					- любая анимация
				- -:
					- нужно настраивать для кадого оружия отдельно
		]
		-+ оружие дальнего боя (стрелковое оружие) (Ranged)
			* ranged weapon: https://en.wikipedia.org/wiki/Ranged_weapon
			* Кинетическое оружие
				* https://ru.wikipedia.org/wiki/%D0%9A%D0%B8%D0%BD%D0%B5%D1%82%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5_%D0%BE%D1%80%D1%83%D0%B6%D0%B8%D0%B5
			-+ стрелковое оружие
				* https://ru.wikipedia.org/wiki/%D0%A1%D1%82%D1%80%D0%B5%D0%BB%D0%BA%D0%BE%D0%B2%D0%BE%D0%B5_%D0%BE%D1%80%D1%83%D0%B6%D0%B8%D0%B5
			@todo -+ огнестрельное, выстреливающее снаряды, не видные человеческим глазом при стрельбе [
				@todo -? WEAPONTYPE_LINEAR
				* Огнестрельное оружие
					* https://ru.wikipedia.org/wiki/%D0%9E%D0%B3%D0%BD%D0%B5%D1%81%D1%82%D1%80%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE%D0%B5_%D0%BE%D1%80%D1%83%D0%B6%D0%B8%D0%B5
				* https://en.wikipedia.org/wiki/Gun
				@todo 2 -+ class: Ranged.Firearm
				-+ collision
					-? by box2d bullet physics
					-+? by math-collision		
						-+?YES box2d World:rayCast
							-+ двигать простреливаемые объекты
						@todo +- внедрить сюда
			]
			@todo 1 -+ выстреливающее снаряды, видные человеческим глазом при стрельбе [
				@todo -? WEAPONTYPE_PROJECTILE
				@todo 1.1 +- class: Ranged
				-?YES имя: метательное оружие: https://ru.wikipedia.org/wiki/%D0%9C%D0%B5%D1%82%D0%B0%D1%82%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE%D0%B5_%D0%BE%D1%80%D1%83%D0%B6%D0%B8%D0%B5
				* Projectile: https://en.wikipedia.org/wiki/Projectile
				-+ арбалет
				-+ базука
				- лук
				-+ гранатомет
				- гарпун, с веревкой
					- объединять с другим оружием, например: гарпун с дробовиком
			]
		-+ взрывчатка
		- лазер
		@todo 1.2 +- огнемет (flamethrower)
			-+ fire
			-+ похож на GrenadeLauncher class
		- водомет
			- похож на огнемет
		- метательное
			-+ гранаты
			- кидать любой предмет и делать урон от удара
		- мины
	]
	@todo - параметры
		-? грузить параметры из файлов, а не для каждого оружия создавать отдельный Класс
			-? это потом, а пока Классы
		- посмотреть в других играх
			- СТАЛКЕР
			- Сурвариум
		-+ урон
			* name = damage
			-+ типы урона
				- физический
					- пули
					- удар
					- взрыв
				- термический
					- огонь
					- заморозка
						- жидкий азот
				- химический
					- яд
					- кислота
						- в реальном времени разьедает физичекие тела физического движка
				- электрический		
		- ...
	@todo +- корректное поведение с UIList инвентаря (смотри code.player)
		@todo +- когда стрелять можно?
			+-?YES только прицельный огонь, когда правой мышкой прицеливаемся (как в Teleglitch), следовательно стрелять в беге нельзя
			-?NO всегда, следовательно стрелять в беге можно		
		@todo +- при изменении выделенного Item в UIList (смотри Class List)
			+- useStart()
			+- useStop()
			+- корректный state
--]]

local ClassParent = require('code.classes.Entity.Item')
local ThisModule
if ClassParent then
	ThisModule = ClassParent:_newClass(...)
else
	ThisModule = {}
end


-- variables private
-- ...

-- variables protected, only in Class
-- ...

-- variables public


-- methods private
-- ...

-- methods protected
-- ...

-- methods public

function ThisModule:newObject(arg)
	if self.destroyed then self:destroyedError() end
	
	local arg = arg or {}
	local object = ClassParent.newObject(self, arg)
	
	
	return object
end

return ThisModule