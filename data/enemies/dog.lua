local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 80
local range = 64
enemy.blood_echoes = 53

function enemy:on_created()
  if enemy:get_property"caged" then range = 16 end
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	damage = DAMAGE,
  	life = 80,
  	attack_range = range,
  	speed = 70,
  })
end


function enemy:choose_attack()
	if enemy:get_distance(hero) >= 24 then
		local attack = require("enemies/lib/attacks/lunge")
		attack:attack(enemy, {
			damage = 100,
      wind_up_time = 1000,
		})
    enemy.recovery_time = 2000
	else
		local attack = require("enemies/lib/attacks/lunge")
		attack:attack(enemy, {
			damage = 70,
      wind_up_time = 400,
		})
    enemy.recovery_time = 800
	end

end

