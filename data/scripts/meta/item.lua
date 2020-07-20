-- Initialize equipment item behavior specific to this quest.

require"scripts/multi_events"

--list of consumables for consumables hud script
local ITEM_LIST = {
  --equipment items
  blood_vial_user = true, --item
  blood_vial = "blood_vial_user", --pickable
  pistol = true, --item
  quicksilver_bullets = "pistol", --pickable
  bloodstone_shard = "bloodstone_shard.1", --use first variant sprite only

}

local item_meta = sol.main.get_metatable"item"
item_meta:register_event("on_obtained", function(self, variant)
  local game = self:get_game()

  --## display hud panel for consumables when obtained
  
  local name = self:get_name() --name of the obtained item
  local item_id = ITEM_LIST[name] --name of the item to display
  local variant
  
  --may substitute for different item
  if item_id then
    if type(item_id)=="string" then
      item_id, variant = item_id:match"^([^%.]+)%.?(%d*)$"
      assert(item_id, "ITEM_LIST invalid value for key "..name)
      variant = tonumber(variant) --will be nil of not specified
    else --item_id has value of true
      item_id = name --use itself as the item id
      variant = self:get_variant()
    end
  else return
  end
  
  local item = game:get_item(item_id) --item to be displayed (not necessarily the one obtained)
  assert(item, "Invalid item specified in ITEM_LIST: "..item_id)
  local variant = variant or item:get_variant() --use current variant if not specified
  
  if item:has_amount() and variant>0 then
    local hud = game:get_hud() or {}
    local menu = hud.elements and hud.elements.consumables
    if menu then menu:add_item(item, variant) end --display a panel for the item on the hud
  end
end)


return true
