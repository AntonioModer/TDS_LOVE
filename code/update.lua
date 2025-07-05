return function(dt)

require("code.player"):update(dt)
require("code.worldEditor"):update(dt)

--require("code.physics").channel:push({physicsWorld=require("code.physics").world, dt=love.timer.getDelta()})  
require("code.physics"):update(dt)

require("code.world"):update(dt)

require("code.graphics"):update(dt)

--require("code.sound"):updateV1(dt)
--require("code.sound"):updateV2(dt)  -- no

debug:update()

require("code.update.tests")(dt)


end