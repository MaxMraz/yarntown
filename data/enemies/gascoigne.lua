local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 150
enemy.blood_echoes = 1800

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	damage = DAMAGE,
  	life = 2031,
  	attack_range = 48,
  	speed = 100,
  })
end

enemy:register_event("on_dying", function()
  enemy:big_death()
  sol.audio.play_sound"bell_boom"
  enemy:get_map():get_camera():shake({})
end)



function enemy:choose_attack()
  local random = math.random(1, 100)
  --Melee Attacks
	if enemy:get_distance(hero) <= 64 and random <= 70 then
		local attack = require("enemies/lib/attacks/melee_combo")
		attack:set_wind_up_time(600)
		enemy.recovery_time = 400
    local potential_attack_sprites = {
      {"enemies/weapons/axe_swipe", "enemies/weapons/axe_swipe",
        "enemies/weapons/axe_slam"
      },
      {"enemies/weapons/axe_swipe", "enemies/weapons/axe_slam",},
      {"enemies/weapons/axe_swipe", "enemies/weapons/axe_swipe",},
      {"enemies/weapons/axe_swipe"},
    }
    local which_attack_set = math.random(1,4)
		attack:attack(enemy, {
			damage = DAMAGE,
			attack_sprites = potential_attack_sprites[which_attack_set],
      attack_sounds = {
        "cleric_beast/scream_1", "cleric_beast/scream_2", "cleric_beast/scream_3",
        "cleric_beast/scream_4", "cleric_beast/scream_5"
      },
		})
  elseif enemy:get_distance(hero) <= 64 then
    local attack = require("enemies/lib/attacks/melee_attack")
		enemy.recovery_time = 100
		enemy:choose_next_state("recover")
    enemy.recovery_time = 900
    attack:attack{
      damage = 200,
      wind_up_animation = "spark_wind_up",
      attack_sprite = "enemies/weapons/gascoigne_uppercut",
      attack_animation = "upper_cut",
      
    }    
	else

	end

end

