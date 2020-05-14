local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 20

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = "random",
  	damage = DAMAGE,
  	life = 150,
  	melee_range = 48,
  })

  enemy:start_default_state()
end




function enemy:choose_attack()
	print("is orth: ", enemy:is_orthogonal_to_hero(12))
	if enemy:is_orthogonal_to_hero() and enemy:get_distance(hero) <= 50 then
		require("enemies/lib/attacks/melee_attack"):melee_attack(enemy, DAMAGE, "enemies/weapons/test_axe_thrust")
	elseif enemy:get_distance(hero) <= 40 then
		local num_attacks = math.random(2,4)
		require("enemies/lib/attacks/multiattack"):melee_attack(enemy, DAMAGE, "enemies/weapons/test_axe_swipe", num_attacks)
	else
		enemy.recovery_time = 100
		enemy:choose_next_state("attack")
	end

end

