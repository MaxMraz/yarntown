local item = ...
local game = item:get_game()

--this code should probably be somewhere else
function game:add_stored_bullets(amount)
  if game:get_value"stored_bullets" == nil then game:set_value("stored_bullets", 0) end
  game:set_value("stored_bullets", game:get_value"stored_bullets" + amount)
end

function game:remove_stored_bullets(amount)
  if game:get_value"stored_bullets" == nil then game:set_value("stored_bullets", 0) end
  game:set_value("stored_bullets", game:get_value"stored_bullets" - amount)
  if game:get_value"stored_bullets" <= 0 then
    game:set_value("stored_bullets", 0)
  end
end

function game:replenish_bullets()
  local user_item = game:get_item("pistol")
  local needed_vials = 20 - (user_item:get_amount() or 0)
  if not game:get_value"stored_bullets" then game:set_value("stored_bullets", 0) end
  if game:get_value"stored_bullets" < needed_vials then
    user_item:add_amount(game:get_value"stored_bullets")
    game:set_value("stored_bullets", 0)
  else
    game:remove_stored_bullets(needed_vials)
    user_item:add_amount(needed_vials)
  end
end


function item:on_obtaining(variant)
  item:set_brandish_when_picked(false)
  local amounts = {3, 5, 10}
  local amount_obtained = amounts[variant]
  local user_item = game:get_item("pistol")
  local held_amount = user_item:get_amount()
  local amount_over_20 = math.max(held_amount + amount_obtained - 20, 0)
  user_item:add_amount(amount_obtained - amount_over_20)
  game:add_stored_bullets(amount_over_20)
end
