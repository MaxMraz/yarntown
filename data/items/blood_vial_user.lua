local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_blood_vial_user")
  item:set_amount_savegame_variable"amount_blood_vials"
  item:set_assignable(true)
  item:set_variant(1)
  game:set_item_assigned(2, item)
end


function item:on_using()
  local hero = game:get_hero()
  hero:freeze()
  sol.audio.play_sound"blood_vial"
  hero:set_animation("heal", function()
    game:add_life(game:get_max_life() * .4)
    item:remove_amount(1)
    hero:unfreeze()
    item:set_finished()
  end)
end

