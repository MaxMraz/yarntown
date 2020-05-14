local souls_enemy = {}

function souls_enemy:create(enemy, props)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = enemy:get_sprite()

  enemy:set_life(props.life or 100)
  enemy:set_damage(props.damage or 30)
  enemy:set_pushed_back_when_hurt(props.pushed_back_when_hurt or false)
  enemy:set_push_hero_on_sword(props.push_hero_on_sword or false)
  enemy:set_can_attack(props.hurts_to_touch or false)
  enemy:set_traversable(props.traversable or false)


  enemy:set_attack_consequence("sword", function() enemy:get_hit(game:get_value"sword_damage" or 40) end)
  enemy:set_attack_consequence("thrown_item", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("explosion", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("fire", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("arrow", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("hookshot", function() enemy:get_hit(1) end)
  enemy:set_attack_consequence("boomerang", function() enemy:get_hit(1) end)


  --Common functions for map entities
  enemy:register_event("on_position_changed", function()
  	sprite:set_direction(enemy:get_movement():get_direction4())
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

  		sol.audio.play_sound(props.enemy_hurt_sound or "enemy_hurt")
  		enemy:remove_life(damage)
  	end
  end


  function enemy:start_default_state()
  	--Start idle movement
  	if props.initial_movement_type == "random" then
  		local m = sol.movement.create"random_path"
  		m:set_speed(20)
  		m:start(enemy)
  	elseif props.initial_movement_type == "path" then
  		--TODO create a script for enemy to follow a set path
  	else
  		--Enemy just waits in place

  	end

  	--Create a vision cone to check for hero
  	local ex, ey, ez = enemy:get_position()
  	local direction = sprite:get_direction()
  	local cone_size = props.agro_cone_size or "medium"
  	local cone_sprite = "enemies/tools/agro_cone_" .. cone_size
  	local agro_cone = map:create_custom_entity{
  		x=ex, y=ey, layer=ez, width=16, height=16, direction=direction, sprite=cone_sprite
  	}
  	-- agro_cone:set_visible(false)
  	agro_cone:add_collision_test("overlapping", function(cone, other_entity)
  		print(other_entity:get_type())
  		if other_entity:get_type() == "hero" then
  			agro_cone:remove()
  			enemy:start_agro()
  		end
  	end)

  	enemy:register_event("on_position_changed", function()
  		agro_cone:set_position(enemy:get_position())
  		agro_cone:get_sprite():set_direction(sprite:get_direction())
  	end)

  	--Check for hero being noisy
  	sol.timer.start(enemy, 100, function()
  		--TODO check for hero swinging sword or rolling
  	end)
  end


  function enemy:start_agro()
  	--stuff
  	print"agro"
  end







end

return souls_enemy