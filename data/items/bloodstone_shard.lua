--Increases weapon power as collected
local item = ...
local game = item:get_game()

function item:on_started()
  item:set_amount_savegame_variable("amount_bloodstone_shards")
end

function item:on_obtaining(variant)
  item:set_brandish_when_picked(false)
  local amounts = {1,2,4}
  item:add_amount(amounts[variant])
end
