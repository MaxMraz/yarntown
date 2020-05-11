-- A menu whose only effect is to create and start a game witout any interaction.
local game_manager = require("scripts/game_manager")

local start_game_menu = {}

function start_game_menu:on_started()
  local game = game_manager:create("save1.dat")
  game:start()
end

return start_game_menu
