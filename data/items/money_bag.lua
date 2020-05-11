local item = ...

function item:on_created()

  self:set_savegame_variable("possession_money_bag")
end

function item:on_variant_changed(variant)

  -- Obtaining a gem bag changes the max money.
  local max_moneys = {100, 300, 999}
  local max_money = max_moneys[variant]
  if max_money == nil then
    error("Invalid variant '" .. variant .. "' for item 'gem_bag'")
  end

  self:get_game():set_max_money(max_money)
end

