local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 190
enemy.blood_echoes = 56

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	damage = DAMAGE,
  	life = 240,
  	attack_range = 56,
  	speed = 15,
  })
end

enemy:register_event("on_dying", function()
  local random = math.random(1,100)
  if random <= 20 then
    enemy:set_treasure("blood_vial")
  end
end)


function enemy:choose_attack()
		local num_attacks = math.random(1,2)
		enemy.recovery_time = 2000
		require("enemies/lib/attacks/multiattack"):attack(enemy, DAMAGE, "enemies/weapons/drowned_corpse_swipe", num_attacks)

end

