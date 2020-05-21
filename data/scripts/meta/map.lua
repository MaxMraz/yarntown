--Initialize map behavior specific to this quest.

require"scripts/multi_events"

local map_meta = sol.main.get_metatable"map"

--===================================================================================--
map_meta:register_event("on_started", function(self)
	local map = self
  local hero = map:get_hero()
  local game = map:get_game()
  local map_id = map:get_id()
  --Set empty array for saving enemy respawn data if there isn't one yet
  if not game.enemies_killed[map_id] then game.enemies_killed[map_id] = {} end


  --Deal with enemy respawns
  for enemy in map:get_entities_by_type"enemy" do
    local x, y, z = enemy:get_position()
    --create a unique ID for each enemy based on starting position
    --This will fall apart if multiple enemies start in the same location
    local c_id = x .. "," .. y .. "," .. z

    --Save enemies to table when killed
    enemy:register_event("on_dying", function()
      game.enemies_killed[map_id][c_id] = {x=x, y=y, z=z}
    end)

  --Remove enemies that have already been killed
    if game.enemies_killed[map_id][c_id] then
      enemy:set_enabled(false)
    end
  end

  --Create echo retrieval
print("echo map: ", game:get_value"lost_echoes_map")
  if game:get_value("lost_echoes_map") and game:get_value"lost_echoes_map" == map_id then
    map:create_custom_entity{
      x = game:get_value"lost_echoes_x",
      y = game:get_value"lost_echoes_y",
      layer = game:get_value"lost_echoes_z",
      width = 16, height = 16, direction = 0,
      model = "lost_echoes",
    }
  end


  --make invisible stairs invisible
  for stairs in map:get_entities("^invisible_stairs") do
    stairs:set_visible(false)
  end

  --universal layer up sensors move you up a layer
  for sensor in map:get_entities("^layer_up_sensor") do
    function sensor:on_activated()
      hero:set_layer(hero:get_layer() + 1)
    end
  end

  --and down a layer
  for sensor in map:get_entities("^layer_down_sensor") do
    function sensor:on_activated()
      hero:set_layer(hero:get_layer() - 1)
    end
  end

  --generic sensor to save solid ground
  for sensor in map:get_entities("^save_solid_ground_sensor") do
    function sensor:on_activated()
      hero:save_solid_ground()
    end
  end

  --generic sensor to reset solid ground.
  for sensor in map:get_entities("^reset_solid_ground_sensor") do
    function sensor:on_activated()
      hero:reset_solid_ground()
    end
  end

  --Set properties of doors with the "gate" sprite
  for door in map:get_entities_by_type"door" do
    if door:get_sprite():get_animation_set() == "doors/gate" then
      door:set_drawn_in_y_order(true)
      door:set_size(48, 16)
      door:set_origin(24, 0)
    end
  end

end) --end of on_started registered event
--==================================================================================--

function map_meta:create_fire(props)
  --props: name, x, y, layer, enabled_at_start, properties
  local map = self
  local fire = map:create_custom_entity{
    x = props.x, y = props.y, layer = props.layer, width = 16, height = 16, direction = 0,
    sprite = "entities/fire", model = "fire"
  }
  return fire
end


local function calculate_speed(entity1, entity2, duration)
  local x1, y1 = entity1:get_position()
  local x2, y2 = entity2:get_position()
  local distance = math.abs(sol.main.get_distance(x1, y1, x2, y2))
  return (distance / duration)  
end


--BG Music
--Fade In
function map_meta:fade_in_music()
  local map = self
  local game = map:get_game()
  sol.audio.set_music_volume(0)
  sol.audio.play_music(map:get_music())
  local i = 1
  sol.timer.start(map, 100, function()
    sol.audio.set_music_volume(i)
    i = i + 5
    if sol.audio.get_music_volume() < game:get_value"music_volume" then return true end
  end)
end


-----Map Focus-----
function map_meta:focus_on(camera, target_entity, callback, return_delay)
--  if not target_entity then print("error-no target entity for map_meta:focus_on") return end
  assert(target_entity, "target_entity is invalid for map_meta:focus_on")
  local game = sol.main.get_game()
  local hero = game:get_hero()
  hero:freeze()
  game:set_suspended(true)
  local m = sol.movement.create("target")
  m:set_target(camera:get_position_to_track(target_entity))
  local speed = calculate_speed(camera, target_entity, 2000)
  if speed < 140 then speed = 140 end
  m:set_speed(speed)
  m:set_ignore_obstacles(true)
  m:start(camera, function()
    callback()
    sol.timer.start(game, return_delay or 500, function()
      m2 = sol.movement.create("target")
      m2:set_ignore_obstacles(true)
      m2:set_target(camera:get_position_to_track(hero))
      m2:set_speed(speed + 40)
      m2:start(camera, function()
        camera:start_tracking(hero)
        game:set_suspended(false)
        hero:unfreeze()
      end)
      function m2:on_obstacle_reached() hero:unfreeze() end
    end)
  end)
end


-----Make a poof--------
function map_meta:create_poof(x, y, layer)
  local map = self
  map:create_custom_entity({
    model = "ephemeral_effect",
    x = x, y = y+3, layer = layer, direction = 0, height = 16, width = 16,
    sprite = "entities/poof"
  })
end


--==================DEBUG===================--
--Take camera control for filming for trailers
function map_meta:helicopter_cam()
  local map = self
  local hero = map:get_hero()
  local game = map:get_game()
  game.helicopter_cam = true
  game:get_hud():set_enabled(false)
  local state = sol.state.create()
  state:set_can_control_movement(true)
  state:set_visible(false)
  state:set_can_traverse(true)
  state:set_can_traverse_ground("wall", true)
  state:set_can_traverse_ground("low_wall", true)
  state:set_can_traverse_ground("deep_water", true)
  state:set_can_traverse_ground("hole", true)
  state:set_can_traverse_ground("prickles", true)
  state:set_gravity_enabled(false)
  state:set_affected_by_ground("ladder", false)
  state:set_can_be_hurt(false)
  hero:start_state(state)
  hero:set_layer(map:get_max_layer())
end

function map_meta:exit_helicopter_cam()
  local map = self
  local hero = map:get_hero()
  local game = map:get_game()
  game.helicopter_cam = false
  game:get_hud():set_enabled(true)
  hero:unfreeze()
end


return true
