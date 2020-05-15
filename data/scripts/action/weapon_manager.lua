require("scripts/multi_events")

local weapon_manager = {}

local SWORD_STAMINA_COST = 15
local CHARGE_STAMINA_COST = 60

function weapon_manager:process_attack_input()
  local game = sol.main.get_game()
  local hero = game:get_hero()
  if hero:get_state() == "sword swinging" or hero:get_state() == "sword spin attack" or game.stamina <= 0 then
  	return
  else
  	hero:start_attack()
  	game:remove_stamina(SWORD_STAMINA_COST)
  end

end

--This is called from scripts/meta/hero, in hero:on_state_changed
--Not sure how else to trigger stamina drain for the charge attack
function weapon_manager:process_spin_attack()
  sol.main.get_game():remove_stamina(CHARGE_STAMINA_COST)
end

return weapon_manager