--Enemy swings at the player a number of times specificed by the call
--Requires animations: wind_up, melee_attack (nonlooping)

local attack = {}

local wind_up_time = 700
local attack_frequency = 500
local tracking = false

function attack:set_wind_up_time(time)
	wind_up_time = time
end

function attack:set_frequency(time)
	attack_frequency = time
end

function attack:set_tracking(track)
  tracking = track
end

function attack:attack(enemy, damage, attack_sprite, num_attacks)
	local sprite = enemy:get_sprite()
	local map = enemy:get_map()
	local hero = map:get_hero()
	if not num_attacks then num_attacks = 3 end

	enemy:stop_movement()
	sprite:set_animation("wind_up")
	enemy.stagger_window = true
	sol.timer.start(enemy, wind_up_time, function()
		enemy.stagger_window = false
		
		for i=1, num_attacks do
			sol.timer.start(enemy, (i-1)* attack_frequency, function()
				--several attacs
        if tracking then
        	enemy:get_sprite():set_direction(enemy:get_direction4_to(hero))
        	local m = sol.movement.create"target"
        	m:set_speed(20)
        	m:start(enemy)
        end
				local sword_sound = math.random(2,4)
				sol.audio.play_sound("sword"..sword_sound)
				local x, y, z = enemy:get_position()
				local direction = sprite:get_direction()
				local weapon = map:create_custom_entity{
					x=x, y=y, layer=z, width=16, height=16, direction=direction, sprite=attack_sprite
				}
				enemy.entities[weapon] = weapon
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
						enemy:stop_movement()
						enemy:choose_next_state("attack")
					end
				end)

			end)
		end

	end)
end

return attack