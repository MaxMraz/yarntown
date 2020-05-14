--Enemy takes one swing at the player. Specify the sprite for the attack in the call, allowing this script
--to be used for many different single attacks. For example, check if the hero is orthogonal to the enemy
--and call this with a thrust animation, else call it with a swipe animation
--Damage can also be specified, to allow different attacks to do different amounts of damage
--Note that without an animation, enemies will be unable to damage the player.
--Requires animations: wind_up, melee_attack (nonlooping)

local attack = {}


function attack:melee_attack(enemy, damage, attack_sprite)
	local sprite = enemy:get_sprite()
	local map = enemy:get_map()
	local hero = map:get_hero()

	enemy:stop_movement()
	sprite:set_animation("wind_up")
	enemy.stagger_window = true
	sol.timer.start(enemy, 300, function()
		enemy.stagger_window = false

		local sword_sound = math.random(2,4)
		sol.audio.play_sound("sword"..sword_sound)
		local x, y, z = enemy:get_position()
		local direction = sprite:get_direction()
		local weapon = map:create_custom_entity{
			x=x, y=y, layer=z, width=16, height=16, direction=direction, sprite=attack_sprite
		}
		weapon:add_collision_test("sprite", function(weapon, other_entity)
			if other_entity:get_type() == "hero" then
				weapon:clear_collision_tests()
				if not hero:is_invincible() then hero:start_hurt(weapon, damage) end
			end
		end)

		weapon:get_sprite():set_animation("attack", function()
			weapon:remove()
		end)

		sprite:set_animation("melee_attack", function()
			sprite:set_animation"stopped"
			enemy.recovery_time = 1000
			enemy:choose_next_state("attack")
		end)

	end)
end

return attack