local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 200
enemy.blood_echoes = 4000

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_size(64, 32)
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	damage = DAMAGE,
  	life = 3015,
  	attack_range = 48,
  	speed = 70,
  })
end

enemy:register_event("on_dying", function()

end)



function enemy:choose_attack()
	if enemy:get_distance(hero) <= 80 then
		local attack = require("enemies/lib/attacks/melee_combo")
		attack:set_wind_up_time(600)
		enemy.recovery_time = 1000
		attack:attack(enemy, {
			damage = DAMAGE,
			attack_sprites = {
        "enemies/weapons/cleric_beast_swipe_1", "enemies/weapons/cleric_beast_swipe_2",
        "enemies/weapons/cleric_beast_swipe_1", "enemies/weapons/cleric_beast_swipe_2",
      },
      attack_animations = {"swipe_1", "swipe_2", "swipe_1", "swipe_2"},
      attack_sounds = {
        "cleric_beast/scream_1", "cleric_beast/scream_2", "cleric_beast/scream_3",
        "cleric_beast/scream_4", "cleric_beast/scream_5"
      },
		})
	else
		enemy.recovery_time = 100
		enemy:choose_next_state("recover")
	end

end

