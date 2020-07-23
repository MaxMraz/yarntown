local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 150
enemy.blood_echoes = 1800
enemy.defense = 95

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	damage = DAMAGE,
  	life = 2031,
  	attack_range = 140,
  	speed = 100,
  deagro_threshold = 900,
  })
end

enemy:register_event("on_dying", function()
  enemy:big_death()
  sol.audio.play_sound"bell_boom"
  enemy:get_map():get_camera():shake({})
end)



function enemy:choose_attack()
  local random = math.random(1, 100)
  --Spark Uppercut
  if enemy:get_distance(hero) > 64 and not enemy.gun_recharge then
		require("enemies/lib/attacks/gun"):attack(enemy, {
      num_bullets = 5,
    })
    enemy.recovery_time = 900
    enemy.gun_recharge = true
    sol.timer.start(map, 5000, function() enemy.gun_recharge = false end)

  elseif enemy:get_distance(hero) <= 64 and random <= 30  then
    local attack = require("enemies/lib/attacks/melee_attack")
    enemy.recovery_time = 900
    attack:attack(enemy, {
      damage = 200,
      wind_up_animation = "spark_wind_up",
      wind_up_time = "500",
      attack_sprite = "enemies/weapons/gascoigne_uppercut",
      attack_animation = "upper_cut",      
    })

  --Thrust
  elseif enemy:is_orthogonal_to_hero(8) and random < 50 and enemy:get_distance(hero) < 70 then
		local attack = require("enemies/lib/attacks/melee_attack")
		attack:set_wind_up_time(900)
		enemy.recovery_time = 800
		attack:attack(enemy, {
			damage = DAMAGE+50, attack_sprite = "enemies/weapons/axe_slam"
		})

  --Melee Combo
	elseif enemy:get_distance(hero) <= 64 then
		local attack = require("enemies/lib/attacks/tracking_combo")
		attack:set_wind_up_time(600)
		enemy.recovery_time = 400
    local potential_attack_sprites = {
      [1] = {"enemies/weapons/axe_swipe", "enemies/weapons/axe_swipe",
        "enemies/weapons/axe_slam"
      },
      [2] = {"enemies/weapons/axe_swipe", "enemies/weapons/axe_slam",},
      [3] = {"enemies/weapons/axe_swipe", "enemies/weapons/axe_swipe",},
      [4] = {"enemies/weapons/axe_swipe"},
    }
    local which_attack_set = math.random(1,4)
print("Which attack set: ", which_attack_set)
    local shoot_at_end = false
    if which_attack_set > 2 then shoot_at_end = true end
		attack:attack(enemy, {
			damage = DAMAGE,
			attack_sprites = potential_attack_sprites[which_attack_set],
      attack_sounds = {
        "cleric_beast/scream_1", "cleric_beast/scream_2", "cleric_beast/scream_3",
        "cleric_beast/scream_4", "cleric_beast/scream_5"
      },
      shoot_at_end = shoot_at_end,
		})

	else
		enemy.recovery_time = 100
		enemy:choose_next_state("recover")
	end

end

