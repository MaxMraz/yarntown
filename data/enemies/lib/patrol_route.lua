local enemy_meta = sol.main.get_metatable("enemy")



function enemy_meta:has_valid_patrol_route()
	local enemy = self
	local patrol_route_name = enemy:get_property("patrol_route_name")
	local valid_route = true
	if not patrol_route_name then
		valid_route = false
		print("enemy location: ", enemy:get_position())
		error("Invalid patrol_route_name property for " .. enemy:get_name())
	end
	if not enemy:get_map():has_entities(patrol_route_name) then
		valid_route = false
		print("enemy location: ", enemy:get_position())
		error("Missing patrol route entities: " .. patrol_route_name)
	end

	return valid_route
end



local function get_closest_partrol_route_node(enemy, patrol_route_name)
  local closest_entity = nil
  local distance_to_entity = nil
  for entity in enemy:get_map():get_entities(patrol_route_name) do
  	--if this is the first entity checked
  	if not distance_to_entity then
  		closest_entity = entity
  		distance_to_entity = enemy:get_distance(entity)
  	else
  		if enemy:get_distance(entity) < distance_to_entity then
  			closest_entity = entity
  			distance_to_entity = enemy:get_distance(entity)
  		end
  	end
  end
  return closest_entity
end



function enemy_meta:move_to_node(node, patrol_route_name)
	local enemy = self
  local m = sol.movement.create"target"
  m:set_speed(20)
  m:set_target(node)
  m:start(enemy)
  sol.timer.start(enemy, 100, function()
  	if enemy:get_distance(node) <= 16 then
  		--Move randomly a little bit to avoid multiple enemies on the same route clustering
  		local previous_angle = m:get_angle()
  		m = sol.movement.create"straight"
  		m:set_angle(previous_angle + math.random(1,2) * math.pi + math.pi/2 + math.random())
  		m:set_max_distance(math.random(0,16))
  		m:start(enemy, function()
	  		--Go to next node
	  		enemy:stop_movement()
	  		enemy:find_next_patrol_route_node(node, patrol_route_name)
    	end)
    	function m:on_obstacle_reached() enemy:stop_movement() enemy:find_next_patrol_route_node(node, patrol_route_name) end
  	else
  		if not enemy.agro then
  			return true
  		end
  	end
  end)
end



function enemy_meta:find_next_patrol_route_node(current_node, patrol_route_name)
	local enemy = self
	local current_node_name = current_node:get_name()
	local current_node_number = current_node_name:match("_(%d+)")
	local map = current_node:get_map()

	local next_node = nil

	--Find next entity
	--Note: enemy.patrol_route_increment always starts as 1
	local next_node
	if map:has_entity(patrol_route_name .. "_" .. current_node_number + enemy.patrol_route_increment) then
		next_node = map:get_entity(patrol_route_name .. "_" .. current_node_number + enemy.patrol_route_increment)
		enemy:move_to_node(next_node, patrol_route_name)
	else
		enemy.patrol_route_increment = enemy.patrol_route_increment * -1
		enemy:find_next_patrol_route_node(current_node, patrol_route_name)
	end

end



function enemy_meta:start_patrol_route()
	local enemy = self
	enemy.patrol_route_increment = 1
	local patrol_route_name = enemy:get_property("patrol_route_name")
  local closest_entity = get_closest_partrol_route_node(enemy, patrol_route_name)
  local m = sol.movement.create"target"
  m:set_speed(20)
  m:set_target(closest_entity)
  m:start(enemy)
  sol.timer.start(enemy, 100, function()
  	if enemy:get_distance(closest_entity) <= 16 then
  		--Go to next node
  		enemy:stop_movement()
  		enemy:find_next_patrol_route_node(closest_entity, patrol_route_name)
  	else
  		return true
  	end
  end)

end


