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
  local needed_vials = 20 - user_item:get_amount()
  if not game:get_value"stored_bullets" then game:set_value("stored_bullets", 0) end
  if game:get_value"stored_bullets" < needed_vials then
    user_item:add_amount(game:get_value"stored_bullets")
    game:set_value("stored_bullets", 0)
  else
    game:remove_stored_bullets(needed_vials)
    user_item:add_amount(needed_vials)
  end
end


function item:on_obtaining()
--  item:set_brandish_when_picked(false)
  local amounts = {3, 5, 10}
  local user_item = game:get_item("pistol")
  if user_item:get_amount() >= 20 then
    game:add_stored_bullets(amounts[user_item:get_variant()])
  else
    user_item:add_amount(amounts[user_item:get_variant()])
  end
end
