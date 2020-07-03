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

	enemy:stop_movement()
	sprite:set_animation(wind_up_animation)
	enemy.stagger_window = true
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
					combo_move()
				else
					enemy:choose_next_state("attack")
				end
			end)
		end

		combo_move() --call first move

	end)

end

return attack