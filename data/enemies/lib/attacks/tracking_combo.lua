--Enemy makes several consecutive attacks. This attack takes a table of animations, and will play them
--Also can take attack_sound, or attack_sounds as a table of sounds to chose randomly

local attack = {}

local wind_up_time = 300

function attack:set_wind_up_time(time)
	wind_up_time = time
end

function attack:attack(enemy, props)
	local sprite = enemy:get_sprite()
	local map = enemy:get_map()
	local hero = map:get_hero()
	local damage = props.damage --TODO allow for different hits of combo to do different damage amounts
	local attack_sprites = props.attack_sprites --table of sprites to create in order
	local attack_animations = props.attack_animations or {}
	local wind_up_animation = props.wind_up_animation or "wind_up"
	local attack_sound = props.attack_sound
	local attack_sounds = props.attack_sounds
	local post_attack_step_distance = props.post_attack_step_distance or 8
	local shoot_at_end = props.shoot_at_end or false

	enemy:stop_movement()
	sprite:set_animation(wind_up_animation)
	sol.timer.start(enemy, props.stagger_window_delay or 1, function() enemy.stagger_window = true end)
	sol.timer.start(enemy, wind_up_time, function()
		enemy.stagger_window = false

		if attack_sound then sol.audio.play_sound(attack_sound) end
		if attack_sounds then sol.audio.play_sound(attack_sounds[math.random(1,#attack_sounds)]) end

		local i = 1

		local function combo_move()
			local sword_sound = math.random(2,4)
			sol.audio.play_sound("sword"..sword_sound)

			local x, y, z = enemy:get_position()
			local direction = sprite:get_direction()
			local weapon = map:create_custom_entity{
				x=x, y=y, layer=z, width=16, height=16, direction=direction, sprite=attack_sprites[i]
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

			sprite:set_animation(attack_animations[i] or "melee_attack", function()
				sprite:set_animation"stopped"
				if i < #attack_sprites then
					i = i + 1
					local m = sol.movement.create"straight"
					m:set_angle(enemy:get_angle(hero))
					m:set_max_distance(post_attack_step_distance)
					m:set_speed(100)
					m:start(enemy, function()
						combo_move()
					end)
          function m:on_obstacle_reached() --in case the move can't finish we still want to continue
            m:stop()
            combo_move()
          end
				else
					if shoot_at_end then
						sprite:set_direction(enemy:get_direction4_to(hero))
						require("enemies/lib/attacks/gun"):attack(enemy, {
							num_bullets =  5,
							damage = damage,
							wind_up_time = 299,
							max_bullet_distance = 120,
						})
					else
						enemy:choose_next_state("attack")
					end
				end
			end)
		end

		combo_move() --call first move

	end)

end

return attack