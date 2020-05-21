local map = ...
local game = map:get_game()

map:register_event("on_started", function()
      sol.timer.start(game, 500, function()
        hero:teleport(game:get_value"respawn_map", game:get_value"respawn_destination")
      end)
      sol.timer.start(game, 1000, function()
        sol.menu.stop(require"scripts/hud/game_over_banner")
        hero:set_animation"stopped"
        game:stop_game_over()
        hero:set_visible(true)
        hero:set_invincible(false)
        hero:set_blinking(false)
      end)
end)
