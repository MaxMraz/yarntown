--Enemy swings at the player a number of times specificed by the call
--Requires animations: wind_up, melee_attack (nonlooping)

local attack = {}


function attack:melee_attack(enemy, damage, attack_sprite, num_attacks)
	local sprite = enemy:get_sprite()
	local map = enemy:get_map()
	local hero = map:get_hero()
	if not num_attacks then num_attacks = 3 end

	enemy:stop_movement()
	sprite:set_animation("wind_up")
	enemy.stagger_window = true
	sol.timer.start(enemy, 500, function()
		enemy.stagger_window = false
		
		for i=1, num_attacks do
			sol.timer.start(enemy, (i-1)*500, function()
				--several attacs
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
					if i == num_attacks then
						--finish attack
						enemy:choose_next_state("attack")
						enemy.recovery_time = 1800
					end
				end)

			end)
		end

	end)
end

return attack