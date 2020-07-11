local map = ...
local game = map:get_game()

map:register_event("on_started", function()
  if not game:get_value"initial_controls_explanation" then
    hero:set_direction(0)
    hero:set_animation("dead")
  end
end)

map:register_event("on_opening_transition_finished", function()
  if not game:get_value"initial_controls_explanation" then
--    hero:set_animation("dead")
    hero:freeze()
    sol.timer.start(map, 2000, function()
      hero:set_animation"stopped"
      game:start_dialog("_controls.move_talk")
      hero:unfreeze()
    end)
    game:set_value("initial_controls_explanation", true)
  end
end)

function doll:on_interaction()
  sol.menu.start(game, require"scripts/menus/level_up")
end