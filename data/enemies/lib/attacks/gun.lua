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
	local max_bullet_distance = props.max_bullet_distance or 400

	attack.bullet_trails = {}

	local BULLET_SPEED = 200
	local TRAIL_DRAW_FREQUENCY = 10

	enemy:stop_movement()
	sprite:set_animation(wind_up_animation)
	sol.timer.start(enemy, wind_up_time, function()
		sol.audio.play_sound(attack_sound)
		sprite:set_animation(attack_animation, "stopped")

		local x, y, z = enemy:get_position()

		--Muzzle flash
		local dx = {[0]=16, [1]=0, [2]=-16, [3]=0}
		local dy = {[0]=0, [1]=-24, [2]=0, [3]=16}
		local direction = sprite:get_direction()
		local muzzle_flash = map:create_custom_entity{
			x=x+dx[direction], y=y+dy[direction], layer=z, direction=0, width=8, height=8,
			sprite="entities/effects/muzzle_flash"
		}
		muzzle_flash:get_sprite():set_animation("flash", function() muzzle_flash:remove() end)

		--Create bullets
		local angle = enemy:get_angle(hero)
		for i = 1, num_bullets do
			local bullet = map:create_custom_entity{
				x=x+dx[direction], y=y+dy[direction], layer=z, width=8,height=8,direction=0,sprite="entities/bullet_trail"
			}
			bullet:set_can_traverse_ground("low_wall", true)
			bullet:set_can_traverse_ground("deep_water", true)
			bullet:set_can_traverse_ground("shallow_water", true)
			bullet:set_can_traverse_ground("hole", true)
			bullet:set_can_traverse_ground("lava", true)
			bullet:get_sprite():set_animation("bullet")
			local angle_mod = i / 2 * math.rad(10)
			if i % 2 == 0 then angle_mode = angle_mod * -1 end

			local m = sol.movement.create"straight"
			m:set_speed(BULLET_SPEED)
			m:set_smooth(false)
			m:set_angle(angle + angle_mod)
			m:set_max_distance(max_bullet_distance)
			m:set_ignore_obstacles(true)
			sol.timer.start(bullet, 100, function() m:set_ignore_obstacles(false) end)

			m:start(bullet, function() bullet:remove() end)
			function bullet:on_obstacle_reached()
				bullet:remove()
			end

			--Reduce Damage with distance
			sol.timer.start(bullet, 25, function()
				damage = damage - 5
			end)

			--Bullet Damage
			bullet:add_collision_test("sprite", function(bullet, hero)
				if hero:get_type() == "hero" then
					bullet:clear_collision_tests()
					if not hero:is_invincible() then hero:start_hurt(bullet, damage) end
				end
			end)

			--Bullet Tail
			sol.timer.start(bullet, TRAIL_DRAW_FREQUENCY, function()
				local bx,by,bz = bullet:get_position()
				local bullet_trail = {}
				bullet_trail.sprite = sol.sprite.create"entities/bullet_trail"
				bullet_trail.x = bx
				bullet_trail.y = by
				table.insert(attack.bullet_trails, bullet_trail)
				bullet_trail.sprite:set_animation("bullet_trail", function()
					for k,v in pairs(attack.bullet_trails) do
						if v.x == bx and v.y == by then
							table.remove(attack.bullet_trails, i)
						end
					end
				end)
				return true
		  end)

		end

		map:register_event("on_draw", function()
			for i=1, #attack.bullet_trails do
				map:draw_visual(attack.bullet_trails[i].sprite, attack.bullet_trails[i].x, attack.bullet_trails[i].y)
			end
	  end)

		enemy:choose_next_state("attack")

  end)

end


return attack