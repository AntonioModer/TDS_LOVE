--[[
@help 
	* config - это состояние игры при загрузке
	+NO game.version убрать отсюда, чтобы игрок не мог изменить значение
		* @help игрок не будет иметь доступ к conf.lua
@todo 
	-? config.controls перенести в input.lua
	- если argC.window.fullscreen = true, то отрисовка мира не такая какая нужна
--]]

config = {}
function love.conf(argC)
	argC.identity = "TDS"                                                                                                                       -- The name of the save directory (string)
	argC.version = "0.10.2"                                                                                                                     -- The LÖVE version this game was made for
	argC.console = true                                                                                                                         -- Windows only
	argC.accelerometerjoystick = true                                                                                                           -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)
	argC.gammacorrect = false                                                                                                                   -- Enable gamma-correct rendering, when supported by the system (boolean)
	
	config.gameVersion = "0.0.77"
	argC.window.title = [[top down view game engine, v]] .. config.gameVersion .. " (" .. os.date("%Y.%m.%d-%H.%M.%S") .. [[); © Savoshchanka Anton, ]] .. os.date("%Y") .. [[ (twitter.com/AntonioModer); LÖVE 2D-framework v]] .. love._version .. [[ (love2d.org)]]
	argC.window.icon = nil                                                                                                                      -- Filepath to an image to use as the window's icon (string)
	argC.window.width = 1920
	argC.window.height = 1080
	argC.window.borderless = false                                                                                                              -- Remove all border visuals from the window
	argC.window.resizable = false                                                                                                               -- Let the window be user-resizable
	argC.window.minwidth = 1                                                                                                                    -- Minimum window width if the window is resizable
	argC.window.minheight = 1                                                                                                                   -- Minimum window height if the window is resizable
	argC.window.fullscreen = true
	argC.window.fullscreentype = "exclusive"                                                                                                      -- "desktop" or "exclusive"
	argC.window.vsync = false                                                                                                                   -- Enable vertical sync
	argC.window.msaa = 10                                                                                                                       -- The number of samples to use with multi-sampled antialiasing
	argC.window.display = 1                                                                                                                     -- Index of the monitor to show the window in
	argC.window.highdpi = false                                                                                                                 -- Enable high-dpi mode for the window on a Retina display (boolean); default = false
	argC.window.x = 1
	argC.window.y = 329
	
	argC.modules.audio = true
	argC.modules.event = true
	argC.modules.graphics = true
	argC.modules.image = true
	argC.modules.joystick = true
	argC.modules.keyboard = true
	argC.modules.math = true
	argC.modules.mouse = true
	argC.modules.physics = true
	argC.modules.sound = true
	argC.modules.system = true
	argC.modules.timer = true                                                                                                                   -- Disabling it will result 0 delta time in love.update
	argC.modules.touch = true
	argC.modules.video = true
	argC.modules.window = true
	argC.modules.thread = true
	
--	config.noGameMode = true                                                                                                                    -- dont run game code
--	argC.window.y = 6320                                                                                                                        -- убираем окно, чтобы не закрывало экран
	
	config.window = {}
	config.window.width = argC.window.width
	config.window.height = argC.window.height

	config.debug = {}
	config.debug.on = false
	config.debug.physics = {}
	config.debug.physics.on = true
	config.debug.physics.draw = {}
	config.debug.physics.draw.on = true
	config.debug.physics.draw.body = {}
	config.debug.physics.draw.body.on = true		
	config.debug.physics.draw.bbox = {}
	config.debug.physics.draw.bbox.on = false	
	config.debug.draw = {}
	config.debug.draw.on = true
	config.debug.watchList = {}
	config.debug.watchList.on = false

	config.gameEditor = {}
	config.gameEditor.on = true
	config.gameEditor.grid = {}
	config.gameEditor.grid.on = false

	config.controls = {}
	config.controls.camera = {}
	config.controls.camera.zoomHoldConrol = 'z'
	config.controls.player = {}
	config.controls.player.move = {}
	config.controls.player.move.alwaysRun = true
	config.controls.player.move.forward = "w"
	config.controls.player.move.backward = "s"
	config.controls.player.move.left = "a"
	config.controls.player.move.right = "d"
	config.controls.player.move.runSwitch = "lshift"
	config.controls.player.use = "space"
	config.controls.player.itemUse = {}
	config.controls.player.itemUse[1] = 1            -- mouse (shoot, ...)
	config.controls.player.itemUse[2] = 2            -- mouse (aim, ...)
	config.controls.player.itemUse[3] = 'f1'         -- keyboard (switch fire.mode, ...)
	config.controls.player.itemUse[4] = 'r'          -- keyboard (reload, ...)
	config.controls.player.inventory = {}
	config.controls.player.inventory.pickupItem = "f"
	config.controls.player.inventory.dropItem = "q"
	config.controls.player.visZone = true           -- туман видимости
	config.controls.ui = {}
	config.controls.ui.switch = "tab"
	config.controls.ui.interact = "return"
	config.controls.ui.down = "down"
	config.controls.ui.up = "up"
	config.controls.ui.left = "left"
	config.controls.ui.right = "right"
	config.controls.ui.allowMouseWhellMove = true                    -- up, down only list selection
	config.controls.ui.allowInteractOnMouseWhellPressed = true
	config.controls.ui.holdToMoveItem = "e"
	config.controls.transformTool = {}
	config.controls.transformTool.move = "t"
	config.controls.transformTool.rotate = "r"	
end
