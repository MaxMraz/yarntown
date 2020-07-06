local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 100
enemy.blood_echoes = 48

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	damage = DAMAGE,
  	life = 70,
  	attack_range = 48,
  	speed = 80,
  })
end


enemy:register_event("on_dying", function()
  local random = math.random(1,100)
  if random <= 10 then
    enemy:set_treasure("quicksilver_bullets")
  end
end)



function enemy:choose_attack()
	if enemy:is_orthogonal_to_hero(12) and enemy:get_distance(hero) <= 50 then
		local attack = require("enemies/lib/attacks/melee_attack")
		attack:set_wind_up_time(100)
		enemy.recovery_time = 800
		attack:attack(enemy, {
			damage = DAMAGE+10, attack_sprite = "enemies/weapons/cleaver_thrust"
		})
	elseif enemy:get_distance(hero) <= 40 then
		local num_attacks = math.random(2,4)
		enemy.recovery_time = 1400
		require("enemies/lib/attacks/multiattack"):attack(enemy, DAMAGE, "enemies/weapons/cleaver_swipe", num_attacks)
	else
		enemy.recovery_time = 100
		enemy:choose_next_state("attack")
	end

end

