local weapon_manager = {}

local SWORD_STAMINA_COST = 20
local CHARGE_STAMINA_COST = 40

function weapon_manager:process_attack_input()
  local game = sol.main.get_game()
  local hero = game:get_hero()
  if hero:get_state() == "sword swinging" or hero:get_state() == "sword spin attack" or game.stamina < SWORD_STAMINA_COST then
  	return
  else
  	hero:start_attack()
  	game:remove_stamina(SWORD_STAMINA_COST)
  end


end

return weapon_manager