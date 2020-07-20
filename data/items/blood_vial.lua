local item = ...
local game = item:get_game()

--this code should probably be somewhere else
function game:add_stored_blood_vials(amount)
  if game:get_value"stored_blood_vials" == nil then game:set_value("stored_blood_vials", 0) end
  game:set_value("stored_blood_vials", game:get_value"stored_blood_vials" + amount)
end

function game:remove_stored_blood_vials(amount)
  if game:get_value"stored_blood_vials" == nil then game:set_value("stored_blood_vials", 0) end
  game:set_value("stored_blood_vials", game:get_value"stored_blood_vials" - amount)
  if game:get_value"stored_blood_vials" <= 0 then
    game:set_value("stored_blood_vials", 0)
  end
end

function game:replenish_blood_vials()
  local user_item = game:get_item("blood_vial_user")
  local needed_vials = 20 - user_item:get_amount()
  if not game:get_value"stored_blood_vials" then game:set_value("stored_blood_vials", 0) end
  if game:get_value"stored_blood_vials" < needed_vials then
    user_item:add_amount(game:get_value"stored_blood_vials")
    game:set_value("stored_blood_vials", 0)
  else
    game:remove_stored_blood_vials(needed_vials)
    user_item:add_amount(needed_vials)
  end
end


function item:on_obtaining(variant)
  item:set_brandish_when_picked(false)
  local amounts = {1, 2, 5}
  local user_item = game:get_item("blood_vial_user")
  local amount_obtained = amounts[variant]
  local held_amount = user_item:get_amount()
  local amount_over_20 = math.max(held_amount + amount_obtained - 20, 0)
  user_item:add_amount(amount_obtained - amount_over_20)
  game:add_stored_blood_vials(amount_over_20)
end
