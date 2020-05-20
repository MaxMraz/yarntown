-- This script initializes game values for a new savegame file.
-- You should modify the initialize_new_savegame() function below
-- to set values like the initial life and equipment
-- as well as the starting location.
--
-- Usage:
-- local initial_game = require("scripts/initial_game")
-- initial_game:initialize_new_savegame(game)

local initial_game = {}

-- Sets initial values to a new savegame file.
function initial_game:initialize_new_savegame(game)

  -- You can modify this function to set the initial life and equipment
  -- and the starting location.
  game:set_starting_location("first_map", nil)  -- Starting location.

  game:set_max_money(999999999)
  game:set_ability("lift", 1)
  game:set_ability("sword", 1)

  --Stats
  game:set_value("vitality", 10)
  game:set_max_life(572) --each level, max hp goes up by (health_level * .6)+14 
  --Health bar is feasible up to around 1600 health. More than that it starts to go off screen.
  game:set_life(game:get_max_life())
  game:set_value("endurance", 10)
  game:set_value("max_stamina", 85) --max stamina = stamina_level * 2.5 + 65. Starting level 10 means 85 stamina. Over 800 stamina goes off screen

  game:set_value("strength", 10)
  game:set_value("skill", 10)
  game:set_value("sword_damage", 40)

  game:get_item("blood_vial_user"):set_amount(20)
end

return initial_game
