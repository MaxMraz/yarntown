--Enemy charges at the player, hurting them if contact is made
--This attack takes the enemy using it and a table as arguments. Table values:
--damage
--wind_up_animation - if not included, "wind_up" is assumed
--attack_animation - if not included, "walking" is used
--prep_sound - optional, played at wind-up
--lunge_sound - optional
--lunge_distance - optional
--speed, default 180
--distance, default 96
--smooth, default false

local attack = {}

function attack:attack(enemy, props)
	attack:check_props(enemy, props)
	local damage = props.damage or 40
	local wind_up_animation = props.wind_up_animation or "wind_up"
	local attack_animation = props.attack_animation or "walking"
	local sprite = enemy:get_sprite()
	local map = enemy:get_map()
	local hero = map:get_hero()
	local could_attack = enemy:get_can_attack()
	local wind_up_time = props.wind_up_time or 500
	attack.finishing = false

	enemy:stop_movement()
	sprite:set_animation(wind_up_animation)
	if props.prep_sound then sol.audio.play_sound(props.prep_sound) end
	enemy.stagger_window = true
	sol.timer.start(enemy, wind_up_time, function()
		enemy.stagger_window = false
		enemy:set_can_attack(true)
		enemy:set_damage(props.damage)
		sol.audio.play_sound(props.lunge_sound or "dash")
		sprite:set_animation(attack_animation)

		local m = sol.movement.create"straight"
		m:set_angle(enemy:get_angle(hero))
		m:set_speed(props.speed or 180)
		m:set_max_distance(props.distance or 96)
		m:set_smooth(props.smooth or false)
		m:start(enemy, function()
      if not attack.finishing then attack:finish(enemy) end
		end)

		function m:on_obstacle_reached()
      if not attack.finishing then attack:finish(enemy) end
		end


	end)
end

function attack:finish(enemy)
	attack.finishing = true
	enemy:set_can_attack(could_attack)
	enemy:choose_next_state("attack")
end


--Return helpful errors if you've not included the needed properties:
function attack:check_props(enemy, props)
    assert(sol.main.get_type(enemy)=="enemy", string.format(
        "Bad argument #1 to 'attack', (sol.enemy expected, got %s)",
        sol.main.get_type(enemy)
    ))
    assert(type(props)=="table", string.format(
        "Bad argument #2 to 'attack' (table expected, got %s)",
        sol.main.get_type(props)
    ))
    local damage = tonumber(props.damage)
    assert(damage, string.format(
        "Bad property 'damage' to argument #2 in 'attack' (number expected, got %s)",
        sol.main.get_type(props.damage)
    ))
end



return attack