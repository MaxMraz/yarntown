local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
end

function entity:on_interaction()

    --Set respawn checkpoint
  game:set_value("respawn_map", map:get_id())
  local x, y, z = map:get_hero():get_position()
  game:set_value("respawn_x", x)
  game:set_value("respawn_y", y)
  game:set_value("respawn_z", z)
  local destination
  local d_dist
  for d in map:get_entities_by_type"destination" do
    if not d_dist or d:get_distance(entity) < d_dist then
      d_dist = d:get_distance(entity)
      destination = d
    end
  end
  game:set_value("respawn_destination", destination:get_name())

  --Check to return to dream
  game:start_dialog("_game.rest_at_lantern", function(answer)
    if answer == 1 then
      game:get_hero():teleport("hunters_dream/dream_outside", "from_waking_world")
      --heal
      game:set_life(game:get_max_life())
      --reset enemies by clearing enemies_killed table
      game.enemies_killed = {}
    end


    --Start level up menu
    -- sol.menu.start(game, require"scripts/menus/level_up")

  end)
end