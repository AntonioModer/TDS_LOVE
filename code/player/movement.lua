--[[
	@version 0.0.1
	* @arg parentModule <table>
	* @arg mode <string> = 'teleglitch'
	@todo 
		-+ рефакторинг
			+ перенести кнопки управления в keyReleased, keyPressed, mousePressed, mouseReleased
--]]

---------------------------------------------------------

--[[ test
--thisModule.move.__index = thisModule.move
setmetatable(thisModule.move, thisModule.move)
-- self == thisModule.move, callParentTable == thisModule
function thisModule.move:__call(callParentTable, mode)
--	print(self, thisModule.move, parentTable, thisModule)

--function thisModule:move(mode)
--]]

local thisModule = {}

function thisModule:update(parentModule, mode)
	local v = math.vector()
	
	-- перенести run/walk в Humanoid class
	parentModule.entity._moveSpeedCurrent = parentModule.entity.moveSpeed
	if config.controls.player.move.alwaysRun then
		parentModule.entity._moveSpeedCurrent = parentModule.entity._moveSpeedCurrent*2
	end
	if love.keyboard.isDown(config.controls.player.move.runSwitch) then
		if config.controls.player.move.alwaysRun then
			parentModule.entity._moveSpeedCurrent = parentModule.entity._moveSpeedCurrent/2
		else
			parentModule.entity._moveSpeedCurrent = parentModule.entity._moveSpeedCurrent*2
		end
	end
	
	if mode == 'teleglitch' then
		----[[ global mode
		-- работает, почти как в Teleglitch
		-- но это не подходит, если нужно идти с одинаковой скоростью по нестандартному 8-направленному направлению
		-- это проблема и Телеглитча также, а не только моего алгоритма
		if love.keyboard.isDown(config.controls.player.move.forward) then
			v.y = v.y-1
		end
		if love.keyboard.isDown(config.controls.player.move.backward) then			
			v.y = v.y+1
		end
		if love.keyboard.isDown(config.controls.player.move.left) then		
			v.x = v.x-1
		end
		if love.keyboard.isDown(config.controls.player.move.right) then		
			v.x = v.x+1
		end
		
		-- @todo - если нажали правую кнопку то стрейфимся клавиатурой
		
		-- @todo -?NO переместить отсюда управление мышкой, turnTo
		-- положение "целиться"
		parentModule.entity._setMoveforceLocalPositionCurrentAtCenter = false
		parentModule.entity._moveWithoutControllerRotation = false
		if parentModule.entity.state.ro_stateCurrentName == 'aiming' then --love.mouse.isDown(2) --and not parentModule.dragHands.is
			local mWX, mWY = camera:toWorld(love.mouse.getPosition())
			
			parentModule.entity:turnToUpdate(mWX, mWY)
			
			parentModule.entity._moveSpeedCurrent = parentModule.entity._moveSpeedCurrent/2
			
			-- возврат угла тела в прямое положение
			--[[ с плавной анимацией
			if parentModule.entity._bodyMoveAnimation.pause == false and parentModule.entity._bodyMoveAnimation.angle ~= 0 then
				local negate = 1                                                                                                                -- если маятник двигался по часовой стрелки, то будем потом отнимать угол, чтобы достигнуть 0
				if parentModule.entity._bodyMoveAnimation.angle < 0 then
					negate = -1                                                                                                                 -- если маятник двигался против часовой стрелки, то будем потом прибавлять угол, чтобы достигнуть 0
				end
				local speedRoot = (2000*love.timer.getDelta() * negate)/1000                                                                    -- как в math.pendulum
				parentModule.entity._bodyMoveAnimation.angle = parentModule.entity._bodyMoveAnimation.angle - speedRoot
--				print(negate, parentModule.entity._bodyMoveAnimation.angle)
				if (negate == -1 and parentModule.entity._bodyMoveAnimation.angle > 0) or (negate == 1 and parentModule.entity._bodyMoveAnimation.angle < 0) then    -- не зависит от deltaTime и FPS, всегда корректное и плавное движение
					parentModule.entity._bodyMoveAnimation.angle = 0
					parentModule.entity._bodyMoveAnimation.pause = true
					math.pendulumInit(parentModule.entity, 'bodyMoveAnimation', 1, true)
				end
				
			end--]]
			----[[ без плавной анимации
--			parentModule.entity._bodyMoveAnimation.angle = 0
			parentModule.entity._bodyMoveAnimation.pause = true
			
--			math.pendulumInit(parentModule.entity, 'bodyMoveAnimation', 0, false)
			parentModule.entity._mathPendulumPeriod['bodyMoveAnimation'] = 0
			--]]
		else
			parentModule.entity._bodyMoveAnimation.pause = false
		end
		
		-- always update version
		if v:len() > 0 then
--			parentModule.entity:moveUpdate({coordinatesSystem='global', direction=v})
		else
--			if parentModule.entity.state.ro_stateCurrentName ~= 'aiming' then
--				parentModule.entity.state:setState('idle', parentModule.entity, parentModule.entity)
--			end
		end
		--]]
		
		-- from keyPressed() keyReleased()
		if parentModule.movementVector:len() > 0 then
			parentModule.entity:moveUpdate({coordinatesSystem='global', direction=parentModule.movementVector})
--			print(parentModule.movementVector)
		end		
		
		--[[ local mode
		-- работает, почти как в Teleglitch
		-- но это не подходит, если нужно идти с одинаковой скоростью по нестандартному 8-направленному направлению
		-- это проблема и Телеглитча также, а не только моего алгоритма
		if love.keyboard.isDown(config.controls.player.move.forward) then
			v.x = 1			
		end
		if love.keyboard.isDown(config.controls.player.move.backward) then			
			v.x = -1				
		end
		-- @todo +?NO нужно точку силы в центр поместить, чтобы тело двигалось в сторону, а не вращалось
		--  @help тогда нельзя повернуться кнопками, только мышкой, это не нужно, НПС будет вращаться по другому	
		if love.keyboard.isDown(config.controls.player.move.left) then		
			v.y = -1
		end
		if love.keyboard.isDown(config.controls.player.move.right) then		
			v.y = 1		
		end
		
		-- @todo - если нажали правую кнопку то стрейфимся клавиатурой
		if love.mouse.isDown(2) then
			local mWX, mWY = camera:toWorld(love.mouse.getPosition())
			self.entity:turnTo(mWX, mWY)
			
			self.entity._moveSpeedCurrent = self.entity._moveSpeedCurrent/2
			
		end
		
		if v:len() > 0 then
			self.entity:move('local', v, false)	
		end
		--]]		
	end


	-- @todo + поворот тела
	-- идеально константное движение будет только так:
	-- self.entity:setAngle(..., ...)
	-- self.entity:move('local', 'forward')
	-- иначе никак, т.к. всё сводится в итоге к ограничению PI
	-- !!! блять, у тут не так как ожидал, это пиздец
	
	-- вообще идеальный контроллер - это SteamController с его сенсорными круглыми штуками, т.к. вектор устанавливается идеально, а не 4 аналоговыми кнопками, как обычно
--	local move = false
--	if love.keyboard.isDown("w") then
--		v.y = -1
--		move = true
--	end
--	if love.keyboard.isDown("s") then			
--		v.y = 1
--		move = true
--	end
--	if love.keyboard.isDown("a") then		
--		v.x = -1
--		move = true
--	end
--	if love.keyboard.isDown("d") then		
--		v.x = 1
--		move = true
--	end	
--	self.entity.physics.body:setAngle(v:angleTo())
--	if move then
--		self.entity:move('local', 'forward')
--	end
	
	-- @todo +! движение по направлению к мышке, это нужно обязательно попробовать
	-- @todo - быстрое двойное нажатие мышкой включает бег, вместо нажатия кнопкой (shift)
	--[[
	if love.mouse.isDown(1) then
--	if love.keyboard.isDown("w") and not love.mouse.isDown(2) then
		local mWX, mWY = camera:toWorld(love.mouse.getPosition())
		
--		self.entity:turnTo(mWX, mWY)			
--		self.entity:move('local', 'forward')

		-- @todo + не совсем так ка хотел, нужно чтобы тело не поворачивалось к мышке. нужно чтобы оно тящилось
			-- т.е. нужно мышкой указывать вектор, а нажатием мышки применять силу		
		-- !!! блять, у тут не так как ожидал, это пиздец, нету константной скорости
		-- но как я ожидал не получится, т.к. при изменении вектора по инерции тело движется и снижает свою скорость и вектор силы
		-- !!! значит это идеальный вариант
		-- @todo - нужна мертвая зона, где не действует эта сила, в радиусе игрока = math.max(self.entity.moveForceLocalPoint:unpack())
		-- @todo -? нужно попробовать, а что если вместо мышки использовать виртуальный указатель, который передвигать с помощью кнопок WSAD и от него брать вектор направления
		-- @todo - нужно разрабатывать управление под контроллер
		-- @todo - для каждого варианта управления сделать типы управления, чтобы легко можно было их менять не путаясь в коде
		-- @todo - экспериментировать с управлением
		
		-- вектор от игрока к мышке
--		local fpx, fpy = self.entity.physics.body:getWorldPoint(self.entity.moveForceLocalPoint:unpack())
--		v.x = mWX - fpx
--		v.y = mWY - fpy
--		self.entity:move('global', v:normalizeInplace())
	end		
	--]]
	
end

return thisModule