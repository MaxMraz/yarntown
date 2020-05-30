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
  	life = 150,
  	attack_range = 48,
  	speed = 70,
  })
end

enemy:register_event("on_dying", function()
  local random = math.random(1,100)
  if random <= 20 then
    enemy:set_treasure("blood_vial")
  elseif random <= 29 then
    --quicksilver bullets
  end
end)



function enemy:choose_attack()
	if enemy:is_orthogonal_to_hero(12) then
		local attack = require("enemies/lib/attacks/melee_attack")
		attack:set_wind_up_time(400)
		enemy.recovery_time = 800
		attack:attack(enemy, {
			damage = DAMAGE+30, attack_sprite = "enemies/weapons/axe_slam"
		})
	elseif enemy:get_distance(hero) <= 40 then
		local attack = require("enemies/lib/attacks/melee_combo")
		attack:set_wind_up_time(400)
		enemy.recovery_time = 600
		attack:attack(enemy, {
			damage = DAMAGE,
			attack_sprites = {"enemies/weapons/axe_swipe", "enemies/weapons/axe_swipe", "enemies/weapons/axe_slam"},
		})
	else
		enemy.recovery_time = 100
		enemy:choose_next_state("recover")
	end

end

