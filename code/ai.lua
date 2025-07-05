--[[
version 0.0.1
@todo 
	-+ планирование
		- структура живого существа
		- структура кода живого существа
	- как обновлять агентов
		- обход таблицы агентов
	- AI в отдельном треде love.thread
		- изучить love.thread
	- coroutine
		- для оптимизации
		- для одновременного обновления всех агентов	
	- общее живое существо (агент)
		- физическая база
			- органы перемещения
			- тело
			- голова
			- мозг
				- центр зрения
				- центр моторики
		- функциональная база
			-+ функция передвижения
			@todo -+ функция поворота
				- как в Teleglitch
			- восприятие мира	
				- функция зрения
				- функция слуха
	@todo 2 -+ гуманоид
		-+ функциональная база
			-+ поворот
				-+? не заданием угла телу, а с помощью силы applyTorque() по направлению к вектору
					@help http://www.iforce2d.net/b2dtut/rotate-to-angle
			-+ функция передвижения
				+ как в Teleglitch
				- нужно каждого агента обновлять, чтобы он двигался
				@todo 2.2 -+? анимация ходьбы: вращение тела туда-сюда из центра
					@todo 2.2.1 -+ с помощью моего math.pendulum
						+? @todo возврат угла тела в прямое положение когда Humanoid "смотрит по направлению"
						+ в player
						- сделать это не только в player
					@todo 2.2.2 -? с помощью hump.timer.tweeting
					-? с помощью flux https://love2d.org/forums/viewtopic.php?f=5&t=77904
					-? с помощью tween https://github.com/kikito/tween.lua
		- посмотри как в Teleglitch
		@todo 2.1 - ноги
			- раздельно
			- анимация
		- тело
			+ раздельно
		- руки
		-+ голова
			+ раздельно
			-? функция поворота
		- ...
	- intelligence(интеллект)
		-? переименовать AI в Intelligence, Intellect(no)
	- logic
		@todo 0 - FSM
			@help срок: 2 недели
			-?NO with goto
			-? by my Node class
			+?YES by setState() from Item class
			-? by my old FSM (F:\Documents\MyGameDevelopment\LOVE\old\tds-backup\tds last\npcFSM.lua)
			-? find examples
		- Behavior tree
			@help срок: 1 месяц
	- pathfinding [
		@todo - реалистичная физика и поведение толпы врагов [
			-? by Boids
				@help https://love2d.org/forums/viewtopic.php?f=5&t=78542&hilit=boids
				@help https://github.com/rlguy/boids
				- разобраться в коде
			@todo 1 -?YES by Box2d physics, мой способ с нуля
				@todo 1 - тестировать много агентов
				-?NO with Boids
			-? с помощью органов восприятия агента
			-? http://www.brandontreb.com/autonomous-steering-behaviors-in-corona-sdk-games
				- https://github.com/brandontreb/Boids
			-? https://github.com/iamwilhelm/frock
			@todo - поискать
				- где
					@todo - в закладках
					@todo - на компе
					@todo -+ в интернете
				- что
					- библиотеки
						- Lua
						- JavaScript
						- Java
						- ...
					- алгоритмы
					- примеры
				- разное
					- flocking behaviour
					- steering Behavior
		]
		-+ graph
		- navMesh
			+ module
			- https://love2d.org/forums/viewtopic.php?f=3&t=81155
			- https://en.wikipedia.org/wiki/Computational_geometry
			- http://doc.cgal.org/latest/Manual/packages.html
			-+ clipper
			-? poly2tri
			-? Blender import/export navmesh
				-? DirectX .x file mesh
				-? .obj
			-? вручную
				-? делать
				-? исправлять
			-? работать только с треугольниками, вместо сложных полигонов
		- world like	
			-? navigation mesh
				@help срок: 3 месяц
			-? matrix
			-? QuadTree
		- matrix
			-? optimization: matrix like LOVE2dimageData
	]		
	- search algorithm
		@help срок: 1 месяц
		- A*
	- социальное
		- НПС запоминают смерти, могут потом рассказать про это
	@todo - joint
		- motorJoint, distanceJoint можно использовать для следования за целью
	* http://www.cs2d.com/help.php?luacat=ai
--]]

local thisModule = {}



return thisModule