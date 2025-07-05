return function(arg)

-- load modules ------------------------------------------------------------------------------------
table.toString = require('code.tableToTXT')
timer = require('code.timer')
require('code.math')
require("code.debug")
require('code.table')
game = require("code.game")
graphics = require("code.graphics")
require("code.Class")
require("code.classes.UI")
require("code.classes.UI.List")
require("code.classes.UI.List.Text")
require("code.classes.UI.TextInput")
require("code.classes.Chart")
require("code.classes.Entity")
require("code.filesystem")
require("code.input")
require("code.ui")
require("code.physics")
require("code.world")
require("code.worldEditor")
require("code.sound")

----------------------------------------------------------------------------------------------------

game:createMainMenu()
require("code.worldEditor"):createMainMenu()                                                                                                    -- INFO: - не переносить в "code.worldEditor"
game.player = require("code.player")

require("code.load.tests")

end