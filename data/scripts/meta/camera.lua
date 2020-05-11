-- Provides additional camera features for this quest.

local camera_meta = sol.main.get_metatable("camera")


function camera_meta:shake(config, callback)

  local shaking_count_max = config ~= nil and config.count or 9
  local amplitude = config ~= nil and config.amplitude or 4
  local speed = config ~= nil and config.speed or 60

  local camera = self
  local map = camera:get_map()
  local hero = map:get_hero()

  local shaking_to_right = true
  local shaking_count = 0

  local function shake_step()

    local movement = sol.movement.create("straight")
    movement:set_speed(speed)
    movement:set_smooth(false)
    movement:set_ignore_obstacles(true)

    -- Determine direction.
    if shaking_to_right then
      movement:set_angle(0)  -- Right.
    else
      movement:set_angle(math.pi)  -- Left.
    end

    -- Max distance.
    movement:set_max_distance(amplitude)

    -- Inverse direction for next time.
    shaking_to_right = not shaking_to_right
    shaking_count = shaking_count + 1

    -- Launch the movement and repeat if needed.
    movement:start(camera, function()

      -- Repeat shaking until the count_max is reached.
      if shaking_count <= shaking_count_max then
        -- Repeat shaking.
        shake_step()
      else
        -- Finished.
        camera:scroll_to_hero()
        if callback ~= nil then
          callback()
        end
      end
    end)
  end

  shake_step()

  --in addition, add some zooming:
  local camera_surface = camera:get_surface()
  local cam_wid, cam_hig = camera:get_size()
  camera_surface:set_transformation_origin(cam_wid / 2, cam_hig / 2)
  local zoom_amount = config.zoom_factor or 1.05
  local dx = {[1] = 1, [0] = zoom_amount}
  local dy = {[1] = 1, [0] = zoom_amount}
  local i = 1
  sol.timer.start(camera, 1, function()
    camera_surface:set_scale(dx[i % 2], dy[i % 2])
    if i <= shaking_count_max * 1.5 then
      i = i + 1
      return 15
    end
  end)
end

-- Set the camera to a 4:3 aspect ratio for this map.
-- Useful as a fallback for old maps that need this.
function camera_meta:letterbox()
  self:set_size(320, 240)
  self:set_position_on_screen(48, 0)
end


function camera_meta:scroll_to_hero()
  local camera = self
  local map = camera:get_map()
  local hero = map:get_hero()
  m = sol.movement.create("target")
  m:set_ignore_obstacles(true)
  m:set_target(camera:get_position_to_track(hero))
  m:set_speed(180)
  m:start(camera, function() camera:start_tracking(hero) end)
end

return true
