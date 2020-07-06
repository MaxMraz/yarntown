local calc = {}

function calc:calculate_attack_damage(enemy)
	local game = sol.main.get_game()

  local damage = game:get_value("sword_damage")

  --Weapon level scaling:
  damage = damage + (game:get_value"sword_level" or 1) * 15

  --Stat scaling:
  damage = damage + .6 * game:get_value"strength" + .4 * game:get_value"skill"

  damage = damage - (enemy.defense or 75)

  return damage
end


function calc:calculate_gun_damage(enemy)
	local game = sol.main.get_game()

	local damage = game:get_value("gun_damage") or 15
	damage = damage + ((game:get_value"skill" or 10) - 10) * damage * .1

	return damage
end


return calc