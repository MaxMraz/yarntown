local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
end

function entity:on_interaction()
  --Effect
  sol.audio.play_sound"lantern_activated"
  entity:sparkle_effect()
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
      --sound
      sol.audio.play_sound"lantern_commune"
      --heal
      game:set_life(game:get_max_life())
      --reset enemies by clearing enemies_killed table
      game.enemies_killed = {}

      --refill blood vials
      game:replenish_blood_vials()
      game:replenish_bullets()

      --teleport to respawn map then back to reset enemies on this map
      local hero = game:get_hero()
      local flash = require"scripts/fx/white_flash"
      sol.menu.start(game, flash)
      hero:teleport("respawn_map", "destination", "immediate")
      sol.timer.start(game, 200, function()
        hero:teleport(game:get_value"respawn_map", game:get_value"respawn_destination", "immediate")
        flash:fade_out()
        sol.timer.start(game, 200, function()
          game:set_suspended()
          sol.menu.stop(flash)
          sol.menu.start(game, require"scripts/menus/level_up")
        end)
      end)

    end


    --Start level up menu
    -- sol.menu.start(game, require"scripts/menus/level_up")

  end)
end


function entity:sparkle_effect()
  local x, y, z = entity:get_position()
  for i=1, 12 do
    
    local sparkle = map:create_custom_entity{
      x=x, y=y, layer=z, direction=0, width=8, height=16,
      sprite = "entities/lantern_sparkle",
    }
    sparkle:get_sprite():set_animation("sparkle_" .. math.random(1,2), function()
      sparkle:remove()
    end)
    sparkle:get_sprite():set_ignore_suspend(true)
    sparkle:set_drawn_in_y_order(true)
    local m = sol.movement.create"straight"
    m:set_speed(120)
    m:set_angle(math.random(100) * 2 * math.pi / 100)
    m:set_max_distance(math.random(8, 24))
    m:set_ignore_obstacles(true)
    m:set_ignore_suspend(true)
    m:start(sparkle)
  end
end
