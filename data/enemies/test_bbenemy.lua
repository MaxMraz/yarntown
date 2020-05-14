local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local DAMAGE = 20

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = "random",
  	damage = DAMAGE,
  	life = 100,
  	melee_range = 48,
  })

  enemy:start_default_state()
end


function enemy:choose_attack()
  enemy:melee_attack()
--  sol.timer.start(enemy, 500, function() enemy:choose_action() end)
end


--TODO move this into a module
function enemy:melee_attack()
	enemy:stop_movement()
	sprite:set_animation("wind_up")
	enemy.stagger_window = true
	sol.timer.start(enemy, 300, function()
		enemy.stagger_window = false
		sprite:set_animation("attack", "stopped")
		local x, y, z = enemy:get_position()
		local direction = sprite:get_direction()
		local weapon = map:create_custom_entity{
			x=x, y=y, layer=z, width=16, height=16, direction=direction, sprite="enemies/test_bbenemy_weapon"
		}
		weapon:add_collision_test("sprite", function(weapon, other_entity)
			if other_entity:get_type() == "hero" then
				weapon:clear_collision_tests()
				hero:start_hurt(weapon, DAMAGE)
			end
		end)

		weapon:get_sprite():set_animation("attack", function()
			weapon:remove()
			enemy.recovery_time = 900
			enemy:choose_action()
		end)
	end)
end

