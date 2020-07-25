require"enemies/lib/patrol_route"

local souls_enemy = {}

local DEFAULT_ATTACK_RANGE = 40

function souls_enemy:create(enemy, props)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = enemy:get_sprite()

  enemy.entities = {}

  enemy:set_life(props.life or 150)
  enemy:set_damage(props.damage or 20)
  enemy:set_pushed_back_when_hurt(props.pushed_back_when_hurt or false)
  enemy:set_push_hero_on_sword(props.push_hero_on_sword or false)
  enemy:set_can_attack(props.hurts_to_touch or false)
  -- enemy:set_traversable(props.traversable or false)

  -- function enemy:on_collision_enemy() print"Yeah it happened!" end

  --Calculate sword damage
  local sword_damage = require("scripts/damage_calc"):calculate_attack_damage(enemy)

  enemy:set_attack_consequence("sword", function() enemy:get_hit(sword_damage) end)
  enemy:set_attack_consequence("thrown_item", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("explosion", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("fire", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("arrow", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("hookshot", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("boomerang", function() enemy:get_hit(1) end)


  --Common functions for map entities
  enemy:register_event("on_position_changed", function()
    if not enemy.staggered then
      if sprite:get_num_directions() == 2 then
        if enemy:get_movement():get_angle() > math.pi / 2
        and enemy:get_movement():get_angle() < 3 * math.pi / 2 then
          sprite:set_direction(1)
        else
          sprite:set_direction(0)
        end

      else
        sprite:set_direction(enemy:get_movement():get_direction4())
      end
    end
  end)



  --Enemy Hurt
  function enemy:get_hit(damage)
  	if not enemy.being_hit then
  		enemy.being_hit = true
  		sol.timer.start(map, 300, function() enemy.being_hit = false end)
  		sprite:set_blend_mode"add"
  		sol.timer.start(map, 50, function()
  			sprite:set_blend_mode"blend"
  		end)

    --alert nearby enemies
    enemy:agro_nearby_enemies()

  		sol.audio.play_sound(props.enemy_hurt_sound or "enemy_hurt")

      if enemy.agro_cone then enemy.agro_cone:remove() enemy.agro_cone = nil end

      if hero:get_state() == "sword swinging" and enemy.staggered then
        enemy:visceral_attack(damage)
        return

      elseif hero:get_state() == "sword spin attack" and hero:get_direction() == sprite:get_direction() then
        --this is where a backstab would go in Souls, but in Bloodborne it's a stagger
        enemy:stagger()

      elseif hero:get_state() == "sword spin attack" then
        damage = damage * 2.5
      else
        if not enemy.agro then enemy:start_agro() end
      end

  		enemy:remove_life(damage)

      --Player Rally
      if hero.can_rally then hero:rally(damage) end

      --TODO consider stunning enemies if you hit them super hard. Not open for visceral attacks, but stunned
      if damage >= (props.life or 9000) * .75 then
        --something like enemy:stun. Having a stun and stagger that are different seems confusing tho
      end
  	end
  end


  function enemy:visceral_attack(init_damage)
    init_damage = init_damage + (init_damage * ((game:get_value"skill" or 10) - 10) * .25 )
    enemy:remove_life(init_damage * 6)
    enemy:stop_movement()
    --create effect probably TODO improve this later
    local x,y,z = enemy:get_position()
    for i=1, 20 do
      local blood_drop = map:create_custom_entity{x=x,y=y,layer=z,width=8,height=8,direction=0,sprite="entities/blood_drop"}
      local bm = sol.movement.create("straight")
      bm:set_speed(200)
      bm:set_angle(math.random(1,100) * math.pi / 100)
      bm:set_ignore_obstacles()
      bm:start(blood_drop)
      blood_drop:get_sprite():set_animation("drop", function() blood_drop:remove() end)
    end
    local m = sol.movement.create"straight"
    m:set_angle(hero:get_angle(enemy))
    m:set_max_distance(24)
    m:set_speed(100)
    m:start(enemy)
    enemy.unstagger_timer:stop()
    enemy:unstagger()
  end


  enemy:register_event("on_dying", function()
    for _, entity in pairs(enemy.entities) do
      if entity:exists() then entity:remove() end
    end
    game:add_money(enemy.blood_echoes or 25)
    -- Save enemy data to respawn at lanterns/bonfires
    game.enemies_killed[enemy] = true
    
  end)



  function enemy:on_restarted()
    enemy:start_default_state()
  end



  function enemy:start_default_state()
  	--Start idle movement
  	if props.initial_movement_type == "random" then
  		local m = sol.movement.create"random_path"
  		m:set_speed(20)
  		m:start(enemy)
  	elseif props.initial_movement_type == "route" then
  		--TODO create a script for enemy to follow a set path
      if not enemy:has_valid_patrol_route() then
        props.initial_movement_type = "random"
        enemy:start_default_state()
      else
        enemy:start_patrol_route()
      end
  	else
  		--Enemy just waits in place
  		sprite:set_animation"stopped"


  	end

  	enemy:create_agro_cone()

  	--Check for hero being noisy
  	sol.timer.start(enemy, 100, function()
  		--TODO check for hero swinging sword or rolling
  	end)
  end



  function enemy:create_agro_cone()
  	--Create a vision cone to check for hero
  	local ex, ey, ez = enemy:get_position()
  	local direction = sprite:get_direction()
  	local cone_size = props.agro_cone_size or "medium"
  	local cone_sprite = "enemies/tools/agro_cone_" .. cone_size
  	enemy.agro_cone = map:create_custom_entity{
  		x=ex, y=ey, layer=ez, width=16, height=16, direction=direction, sprite=cone_sprite
  	}
  	enemy.agro_cone:set_visible(false)
  	enemy.agro_cone:add_collision_test("sprite", function(cone, other_entity)
  		if other_entity:get_type() == "hero" and enemy:is_in_same_region(other_entity) then
      enemy.agro_cone:clear_collision_tests()
  			enemy.agro_cone:remove()
        enemy.agro_cone = nil
        sol.timer.start(enemy, 400, function() --slight delay once they see you before attacking
          enemy:start_agro()
        end)
  		end
  	end)

  	enemy:register_event("on_position_changed", function()
      if enemy.agro_cone then
    		enemy.agro_cone:set_position(enemy:get_position())
    		enemy.agro_cone:get_sprite():set_direction(sprite:get_direction())
      end
  	end)
  end


  function enemy:start_agro()
    	enemy.agro = true
    enemy.deagro_x, enemy.deagro_y, enemy.deagro_z = enemy:get_position()
  	  enemy:approach_hero()
  end


  function enemy:agro_nearby_enemies()
    local ALERT_DISTANCE = 48
    for e in map:get_entities_by_type"enemy" do
      if e:get_distance(enemy) <= ALERT_DISTANCE and e:get_layer() == enemy:get_layer() and not e.agro then
        if e.agro_cone then e.agro_cone:remove() e.agro_cone = nil end
        e:start_agro()
        end
    end
  end


  function enemy:choose_next_state(previous_state)
  	if enemy:get_life() < 1 then return
    elseif not enemy.agro then
  		enemy:start_default_state()
  	elseif previous_state == "agro" then
  		enemy:approach_hero()
  	elseif previous_state == "approach" then
  		enemy:choose_attack()
    elseif previous_state == "deagro" then
      enemy:return_to_idle_location()
  	elseif previous_state == "attack" then
  		enemy:recover()
  	elseif previous_state == "recover" then
  		enemy:approach_hero()
  	end
  end


  function enemy:approach_hero()
    sprite:set_animation"walking"
  	local m = sol.movement.create("target")
  	m:set_speed(props.speed or 50)
  	m:start(enemy, function() end)

  	sol.timer.start(enemy, 100, function()
  		--see if close enough
    local dist = enemy:get_distance(hero)
  		if dist <= (props.attack_range or DEFAULT_ATTACK_RANGE) then
  			enemy:stop_movement()
  			enemy:choose_next_state("approach")
      elseif dist >= (props.deagro_threshold or 250) then
        --Deagro
        enemy.agro=false
        enemy:stop_movement()
        enemy:choose_next_state("deagro")
  		else
  			return true
  		end
  	end)
  end


  function enemy:recover()
    if sprite:get_num_directions() == 4 then
      sprite:set_direction(enemy:get_direction4_to(hero))
    end
    --TODO add a check if an enemy overlaps another one and if so, move aside a bit
  	sol.timer.start(enemy, (enemy.recovery_time or 400) + math.random(400), function()
  		enemy:choose_next_state("recover")
  	end)
  end

  function enemy:return_to_idle_location()
    --TODO ...do this. Probably write my own A* pathfinding algorithm since the built-in has limitations
    enemy:choose_next_state()
  end

  function enemy:get_shot()
    --break out of function if enemy is already dying
    if enemy:get_life() <= 0 then
      return
    end
    enemy:get_hit(game:get_value"gun_damage" or 15 + ((game:get_value"skill" or 10) -10) * 20)
    if enemy.stagger_window then
      enemy.stagger_window = false
      enemy:stagger()
    end
  end

  function enemy:stagger()
    --don't create infinite stunlock
    if enemy.staggered then return end
    enemy.staggered = true
    sol.audio.play_sound"visceral_thud"
    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    sprite:set_animation("stopped") --TODO add staggered animations for enemies
    sprite:set_color_modulation{200,200,200} --Grey out color in lieu of staggered animation
    enemy.unstagger_timer = sol.timer.start(enemy, enemy.stagger_duration or 2000, function()
      enemy:unstagger()
    end)
  end

  function enemy:unstagger()
    enemy.staggered = false
    sprite:set_color_modulation{255,255,255}
    enemy:choose_next_state("attack")
  end



end

return souls_enemy