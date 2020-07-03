local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 150
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
  	speed = 100,
  })
end

enemy:register_event("on_dying", function()
  sol.audio.play_sound"cleric_beast/roar"
  enemy:big_death()
  sol.audio.play_sound"bell_boom"
  enemy:get_map():get_camera():shake({})
end)



function enemy:choose_attack()
	if enemy:get_distance(hero) <= 120 then
		local attack = require("enemies/lib/attacks/melee_combo")
		attack:set_wind_up_time(600)
		enemy.recovery_time = 700
    local potential_attack_sprites = {
      {"enemies/weapons/cleric_beast_swipe_1", "enemies/weapons/cleric_beast_swipe_2",
        "enemies/weapons/cleric_beast_swipe_1", "enemies/weapons/cleric_beast_swipe_2",
      },
      {"enemies/weapons/cleric_beast_swipe_1", "enemies/weapons/cleric_beast_swipe_2",
        "enemies/weapons/cleric_beast_swipe_1"
      },
      {"enemies/weapons/cleric_beast_swipe_1", "enemies/weapons/cleric_beast_swipe_2",},
    }
    local potential_attack_animations = {
      {"swipe_1", "swipe_2", "swipe_1", "swipe_2"},
      {"swipe_1", "swipe_2", "swipe_1",},
      {"swipe_1", "swipe_2",},
    }
    local which_attack_set = math.random(1,3)
		attack:attack(enemy, {
			damage = DAMAGE,
			attack_sprites = potential_attack_sprites[which_attack_set],
      attack_animations = potential_attack_animations[which_attack_set],
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

