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
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	damage = DAMAGE,
  	life = 90,
  	attack_range = GUN_RANGE,
  	speed = 10,
  agro_cone_size = "large"
  })
end

enemy:register_event("on_dying", function()
  local random = math.random(1,100)
  if random <= 40 then
    enemy:set_treasure("quicksilver_bullets")
  elseif random <= 60 then
    enemy:set_treasure("quicksilver_bullets", 2)
  elseif random <= 63 then
    enemy:set_treasure("quicksilver_bullets", 3)

  end
end)


function enemy:choose_attack()
	if enemy:get_distance(hero) <= GUN_RANGE then
		require("enemies/lib/attacks/gun"):attack(enemy, {
      num_bullets = 1,
      max_bullet_distance = 120,
    })
	else
		enemy.recovery_time = 5000
		enemy:choose_next_state("attack")
	end

end

