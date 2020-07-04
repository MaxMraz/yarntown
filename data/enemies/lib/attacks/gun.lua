--Shoot a gun. Variable number of bullets. Bullets do less damage the further they travel.

local attack = {}

function attack:attack(enemy, props)
	local map = enemy:get_map()
	local hero = map:get_hero()
	local sprite = enemy:get_sprite()

	local num_bullets = props.num_bullets or 1
	local damage = props.damage or 120
	local wind_up_animation = props.wind_up_animation or "wind_up"
	local wind_up_time = props.wind_up_time or 700
	local attack_animation = props.attack_animation or "shooting"
	local attack_sound = props.attack_sound or "hand_cannon"

	local BULLET_SPEED = 200
	local TRAIL_DRAW_FREQUENCY = 10

	enemy:stop_movement()
	sprite:set_animation(wind_up_animation)
	sol.timer.start(enemy, wind_up_time, function()
		sol.audio.play_sound(attack_sound)
		sprite:set_animation(attack_animation, "stopped")

		--Create bullets
		local x, y, z = enemy:get_position()
		local angle = enemy:get_angle(hero)
		for i = 1, num_bullets do
			local bullet = map:create_custom_entity{
				x=x,y=y-8,layer=z,width=8,height=8,direction=0,sprite="entities/bullet_trail"
			}
			bullet:get_sprite():set_animation("bullet")
			local angle_mod = i / 2 * math.rad(5)
			if i % 2 == 0 then angle_mode = angle_mod * -1 end

			local m = sol.movement.create"straight"
			m:set_speed(BULLET_SPEED)
			m:set_smooth(false)
			m:set_angle(angle + angle_mod)

			m:start(bullet)
			function bullet:on_obstacle_reached()
				bullet:remove()
			end

			sol.timer.start(bullet, TRAIL_DRAW_FREQUENCY, function()
				local bx,by,bz = bullet:get_position()
				local bullet_trail = map:create_custom_entity{
					x=bx,y=by,layer=bz,width=8,height=8,direction=0,sprite="entities/bullet_trail"
				}
				bullet_trail:get_sprite():set_animation("bullet_trail", function() bullet_trail:remove() end)
				return true
		  end)

		end

		enemy:choose_next_state("attack")

  end)

end


return attack