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

  game:set_max_money(999999999)
  game:set_ability("lift", 1)
  game:set_ability("sword", 1)

  --Stats
  game:set_value("player_level", 10)
  game:set_value("vitality", 10)
  game:set_max_life(572) --each level, max hp goes up by (vitality * .6)+14 
  --Health bar is feasible up to around 1600 health. More than that it starts to go off screen.
  game:set_life(game:get_max_life())
  game:set_value("endurance", 10)
  game:set_value("max_stamina", 85) --max stamina = endurance * 2.5 + 65. Endurance level 10 means 85 stamina. Over 800 stamina goes off screen

  game:set_value("strength", 10)
  game:set_value("sword_damage", 100) --base Saw Cleaver damage
  game:set_value("skill", 10) --No effect on anything yet
  game:set_value("gun_damage", 15)

  --Just have 20 blood vials to start
  game:get_item("blood_vial_user"):set_amount(20)

  --Same with bullets
  game:get_item("pistol"):set_amount(20)

  --Set starting location and starting respawn
  game:set_starting_location("central_yarntown/central_yarntown", "lantern_clinic")  -- Starting location.
  game:set_value("respawn_map", "central_yarntown/central_yarntown")
  game:set_value("respawn_destination", "lantern_clinic")
  game:set_value("respawn_x", 1864)
  game:set_value("respawn_y", 2605)
  game:set_value("respawn_z", 0)

end

return initial_game
