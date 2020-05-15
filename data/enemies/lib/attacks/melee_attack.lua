--Enemy takes one swing at the player. Specify the sprite for the attack in the call, allowing this script
--to be used for many different single attacks. For example, check if the hero is orthogonal to the enemy
--and call this with a thrust animation, else call it with a swipe animation
--This attack takes the enemy using it and a table as arguments
--Damage can also be specified, to allow different attacks to do different amounts of damage
--Note that without an animation, enemies will be unable to damage the player.

local attack = {}

local wind_up_time = 300

function attack:set_wind_up_time(time)
	wind_up_time = time
end

function attack:attack(enemy, props)
	attack:check_props(enemy, props)
	local damage = props.damage or 40
	local attack_sprite = props.attack_sprite
	local wind_up_animation = props.wind_up_animation or "wind_up"
	local attack_animation = props.attack_animation or "melee_attack"
	local sprite = enemy:get_sprite()
	local map = enemy:get_map()
	local hero = map:get_hero()

	enemy:stop_movement()
	sprite:set_animation(wind_up_animation)
	enemy.stagger_window = true
	sol.timer.start(enemy, wind_up_time, function()
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

		sprite:set_animation(attack_animation, function()
			sprite:set_animation"stopped"
			enemy:choose_next_state("attack")
		end)

	end)
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
    local attack_sprite = props.attack_sprite
    assert(sol.main.get_type(attack_sprite)=="string", string.format(
        "Bad property 'attack_sprite' to argument #2 in 'attack' (sol.sprite expected, got %s)",
        sol.main.get_type(attack_sprite)
    ))
end



return attack