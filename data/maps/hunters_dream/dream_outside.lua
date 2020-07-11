local map = ...
local game = map:get_game()

map:register_event("on_started", function()
  if not game:get_value"initial_controls_explanation" then
    game:get_hud():set_enabled(false)
    hero:set_direction(0)
    hero:set_animation("dead")
  end
end)

map:register_event("on_opening_transition_finished", function()
  if not game:get_value"initial_controls_explanation" then
    hero:freeze()
    hero:set_animation("dead")
    sol.timer.start(map, 1500, function()
      hero:set_animation"stopped"
      sol.timer.start(map, 1000, function()
        hero:set_direction(3)
        game:start_dialog("_controls.move_talk", function() game:get_hud():set_enabled(true) end)
        hero:unfreeze()
      end)
    end)
    game:set_value("initial_controls_explanation", true)
  end
end)



function doll:on_interaction()
  game:start_dialog("_npcs.doll.welcome", function()
    local menu = require"scripts/menus/level_up"
    sol.menu.start(game, menu)
    function menu:on_stopped() game:start_dialog("_npcs.doll.exit") end
  end)
end


for e in map:get_entities"crafting_table" do
function e:on_interaction()
  sol.menu.start(map, require"scripts/menus/weapon_upgrade")
end
end


function bath_messenger:on_interaction()
  game:start_dialog("_shop.vials", function(answer)
    if answer == 1 then
      if game:get_money() < 170 then game:start_dialog"_shop.not_enough_echoes" return end
      game:remove_money(170)
      if game:get_item("blood_vial_user"):get_amount() < 20 then
        game:get_item("blood_vial_user"):add_amount(1)
      else
        game:add_stored_blood_vials(1)
      end
    end
  end)
end