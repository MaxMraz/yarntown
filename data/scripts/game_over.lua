local game_over = {}

function game_over:initialize(game)

  function game:on_game_over_started()
    local hero = game:get_hero()
    hero:set_animation"dead"

    --set lost echoes location for corpse run
    local x, y, z = hero:get_position()
    game:set_value("lost_echoes_map", game:get_map():get_id())
    game:set_value("lost_echoes_x", x)
    game:set_value("lost_echoes_y", y)
    game:set_value("lost_echoes_z", z)
    game:set_value("lost_echoes_amount", game:get_money())
    game:set_money(0)

    local death_banner = require"scripts/hud/game_over_banner"
    sol.menu.start(game, death_banner)

    sol.timer.start(game, 1000, function()
      death_banner:fade_to_black()
    end)

    sol.timer.start(game, 3000, function()
      --reset all enemies by clearing the enemies_killed table
      game.enemies_killed = {}

      hero:set_visible(false)
      game:set_life(game:get_max_life())
      --send the player to a different map to ensure the one they died on resets
      hero:teleport("respawn_map", "destination", "immediate")

      sol.timer.start(game, 2000, function()
        hero:teleport(game:get_value"respawn_map", game:get_value"respawn_destination")
      end)
      sol.timer.start(game, 2000, function()
        sol.menu.stop(require"scripts/hud/game_over_banner")
        hero:set_animation"stopped"
        game:stop_game_over()
        hero:set_visible(true)
        hero:set_invincible(false)
        hero:set_blinking(false)
      end)
      
    end)
    
  end

end

return game_over