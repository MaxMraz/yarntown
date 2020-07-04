local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 100
local GUN_RANGE = 150
enemy.blood_echoes = 48

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/gascoigne")
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	damage = DAMAGE,
  	life = 70,
  	attack_range = GUN_RANGE,
  	speed = 10,
  })
end




function enemy:choose_attack()
	if enemy:get_distance(hero) <= GUN_RANGE then
		require("enemies/lib/attacks/gun"):attack(enemy, {
      num_bullets = 7,
    })
	else
		enemy.recovery_time = 2000
		enemy:choose_next_state("attack")
	end

end

