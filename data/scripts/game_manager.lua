-- Script that creates a game ready to be played.

-- Usage:
-- local game_manager = require("scripts/game_manager")
-- local game = game_manager:create("savegame_file_name")
-- game:start()

require("scripts/multi_events")
local initial_game = require("scripts/initial_game")
local game_restart = require("scripts/game_restart")
local stamina_manager = require"scripts/action/stamina_manager"

local game_manager = {}

-- Creates a game ready to be played.
function game_manager:create(file)

  -- Create the game (but do not start it).
  local exists = sol.game.exists(file)
  local game = sol.game.load(file)
  if not exists then
    -- This is a new savegame file.
    initial_game:initialize_new_savegame(game)
  end

  require("scripts/button_inputs"):initialize(game)

  --reset some values whenever game starts or restarts
  game:register_event("on_started", function()
    game_restart:reset_values(game)
  end)

  return game
end

return game_manager
