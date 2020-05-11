local enemy = ...
local map = enemy:get_map()

local life = 2
local damage = 1
local state -- States: "stopped", "egg", "going_hero", "hidden", "hiding", "unhiding", "jumping", "prepare_jump", "finish_jump".
local speed = 20
local detection_distance = 100
local jump_duration = 1000 -- Time in milliseconds.
local max_height = 24 -- Height for the jump, in pixels.
local jumping_speed = 60 -- Speed of the movement during the jump.
local needs_put_egg = false -- Do not put eggs by default.
local split_when_hurt = nil -- Split in smaller slimes when hurt. Values: true, false, nil (random).

function enemy:on_created()
  self:set_life(life)
  self:set_damage(damage)
  self:set_size(16, 16)
  self:set_origin(8, 13)
  self:set_pushed_back_when_hurt(true)
  self:set_obstacle_behavior("flying") -- Allow to traverse bad grounds (and fall on them).
  if split_when_hurt == nil then split_when_hurt = (math.random(0,1) == 1) end
  -- Enable shield push.
  if self.set_default_behavior_on_hero_shield then
    self:set_default_behavior_on_hero_shield("normal_shield_push")
  end
  -- This function is called a second time for purple slimes, to make them purple
  -- instead of green. In that case this function applies later to the new sprite (purple one).
  local sprite = self:get_sprite()
  if not sprite then -- Condition used for purple slimes, when calling on_created twice.
    sprite = self:create_sprite("enemies/" .. self:get_breed())
  end
  state = "hidden"
  function sprite:on_animation_finished(animation)
    if animation == "hide" then
      state = "hidden"
      sprite:set_animation("hidden")
      enemy:restart() -- Restart enemy after hiding.
    elseif animation == "unhide" then
      enemy:start_going_hero()
    elseif animation == "prepare_jump" then
      enemy:jump()
    elseif animation == "finish_jump" then
      state = "stopped"
      sprite:set_animation("stopped")
      sol.timer.start(enemy, 200, function()
        enemy:start_going_hero()
      end)
    end
  end
end

-- Update sprites direction.
function enemy:on_movement_changed(movement)
  local dir4 = movement:get_direction4()
  if dir4 then
    for _, s in enemy:get_sprites() do
      s:set_direction(dir4)
    end
  end
end

function enemy:on_restarted()
  -- Destroy shadow sprite, if any.
  local shadow = self:get_sprite("shadow")
  if shadow then self:remove_sprite(shadow) end
  -- Reset the starting animation if necessary (the engine sets the "walking" animation).
  if state == "hidden" then
    self:get_sprite():set_animation("hidden")
  else
    self:start_going_hero()
  end
  -- Check for bad grounds.
  self:start_checking_ground()
  -- Start looking for hero.
  self:start_checking()
end

-- Start checking for hero.
function enemy:start_checking()
  local hero = self:get_map():get_hero()
  -- Start loop for checking.
  sol.timer.start(self, 30, function()
    --print(state)
    local is_close = (self:get_distance(hero) <= detection_distance)
    if is_close then
      -- Unhide and follow hero if hero is close.
      if state == "hidden" then
        self:unhide()
      end
    elseif (not is_close) then
      -- Hide and stop if hero is not close.
      if state == "going_hero" then
        self:hide()
      end
    end
    return true
  end)
end

-- Go to hero.
function enemy:start_going_hero()
  state = "going_hero"
  self:get_sprite():set_animation("walking")
  local m = sol.movement.create("target")
  m:set_speed(speed)
  m:set_target(self:get_map():get_hero())
  m:start(self)
  -- Put egg if necessary.
  if needs_put_egg then
    sol.timer.start(self, 500, function() self:create_egg() end)
  end
  -- Prepare jump.
  sol.timer.start(self, 2000, function()
    self:prepare_jump()
  end)
end

-- Hide.
function enemy:hide()
  state = "hiding"
  self:stop_movement()
  self:get_sprite():set_animation("hide")
end
-- Unhide.
function enemy:unhide()
  state = "unhiding"
  self:get_sprite():set_animation("unhide")
end
-- Prepare jump.
function enemy:prepare_jump()
  state = "prepare_jump"
  self:stop_movement()
  self:get_sprite():set_animation("prepare_jump")
end
-- Finish jump.
function enemy:finish_jump()
  state = "finish_jump"
  self:stop_movement()
  self:get_sprite():set_animation("finish_jump")
  self:set_can_attack(true) -- Allow to attack the hero again.
  -- Finish shield protection.
  if enemy.set_can_be_pushed_by_shield then enemy:set_can_be_pushed_by_shield(true) end
end

-- Jump.
function enemy:jump()
  -- Set jumping state, animation and sound.
  state = "jumping"
  local sprite = self:get_sprite()
  sprite:set_animation("jump")
  sol.audio.play_sound("jump")
  self:set_invincible() -- Set invincible.
  self:set_can_attack(false) -- Do not attack hero during jump.
  -- Shield protection.
  if enemy.set_can_be_pushed_by_shield then enemy:set_can_be_pushed_by_shield(false) end
  -- Start shift on sprite.
  local function f(t) -- Shifting function.
    return math.floor(4 * max_height * (t / jump_duration - (t / jump_duration) ^ 2))
  end
  local t = 0
  local refreshing_time = 10
  sol.timer.start(self, refreshing_time, function() -- Update shift each 10 milliseconds.
    sprite:set_xy(0, -f(t))
    t = t + refreshing_time
    if t > jump_duration then return false
      else return true
    end
  end)
  -- Add a shadow sprite.
  local shadow = self:create_sprite("shadows/shadow_big_dynamic", "shadow")
  local new_frame_delay = math.floor(jump_duration/shadow:get_num_frames())
  shadow:set_frame_delay(new_frame_delay)
  -- Add movement towards near the hero during the jump. The jump does not target the hero.
  -- The angle is partially random to avoid too many enemies overlapping.
  local m = sol.movement.create("straight")
  local angle = self:get_angle(self:get_map():get_hero())
  local d = 2*math.random() - 1 -- Random real number in [-1,1].
  angle = angle + d*math.pi/4 -- Alter jumping angle, randomly.
  m:set_speed(jumping_speed)
  m:set_angle(angle)
  m:start(self)
  -- Finish the jump.
  sol.timer.start(self, jump_duration, function()
    self:remove_sprite(shadow) -- Remove shadow sprite.
    sol.timer.start(self, 1, function() -- TODO: remove this after #868 is fixed.
      self:set_default_attack_consequences() -- Stop invincibility after jump.
      self:finish_jump()
    end)
  end)
end

-- Start "break" animation when dying.
function enemy:on_dying()
  self:get_sprite():set_animation("break")
end

-- Check for bad ground (water, hole and lava) and also for empty ground.
function enemy:check_on_ground()
  local map = self:get_map()
  local px, py, layer = self:get_position()
  local x, y, layer = self:get_ground_position()
  local ground = self:get_ground_below()
  if ground == "empty" and layer > 0 then
    -- Fall to lower layer and check ground again.
     self:set_position(px, py, layer-1)
     self:check_on_ground() -- Check again new ground.
  elseif ground == "hole" then
    -- Create falling animation centered correctly on the 8x8 grid.
    x = math.floor(x/8)*8 + 4; if map:get_ground(x, y, layer) ~= "hole" then x = x + 4 end
    y = math.floor(y/8)*8 + 4; if map:get_ground(x, y, layer) ~= "hole" then y = y + 4 end
    local fall_on_hole = map:create_custom_entity({x = x, y = y, layer = layer, direction = 0})
    local sprite = fall_on_hole:create_sprite("ground_effects/fall_on_hole_effect")
    sprite:set_animation("fall_on_hole")
    self:remove()
    function sprite:on_animation_finished() fall_on_hole:remove() end
    sol.audio.play_sound("falling_on_hole")
  elseif ground == "deep_water" then
    -- Sink in water.
    local water_splash = map:create_custom_entity({x = x, y = y, layer = layer, direction = 0})
    local sprite = water_splash:create_sprite("ground_effects/water_splash_effect")
    sprite:set_animation("water_splash")
    self:remove()
    function sprite:on_animation_finished() water_splash:remove() end
    sol.audio.play_sound("splash")
  elseif ground == "lava" then
    -- Sink in lava.
    local lava_splash = map:create_custom_entity({x = x, y = y, layer = layer, direction = 0})
    local sprite = lava_splash:create_sprite("ground_effects/lava_splash_effect")
    sprite:set_animation("lava_splash")
    self:remove()
    function sprite:on_animation_finished() lava_splash:remove() end
    sol.audio.play_sound("splash")
  end
end

-- Start a timer to check ground once per second (useful if the ground moves or changes type!!!).
function enemy:start_checking_ground()
  sol.timer.start(self, 300, function()
    if state == "jumping" then return true end -- Do not check the ground while jumping.
    self:check_on_ground()
    return true
  end)
end

-- Create egg.
function enemy:create_egg()
  state = "egg"
  needs_put_egg = false
  self:stop_movement()
  local sprite = self:get_sprite()
  sprite:set_animation("jump")
  sol.timer.start(self, 250, function() sprite:set_animation("stopped") end)
  local x, y, layer = self:get_position()
  local prop = {x = x, y = y, layer = layer, direction = 0, breed = "slime_egg"}
  local egg = map:create_enemy(prop)
  egg:set_slime_model("slime_green")
  egg:fall() -- Falling animation.
  egg:set_can_procreate(false) -- Do not allow more procreation from the new slime.
  return egg
end

-- Enable/disable putting egg.
function enemy:set_egg_enabled(bool) needs_put_egg = bool end
function enemy:get_egg_enabled() return needs_put_egg end

-- Change default behavior of splitting when hurt.
function enemy:set_split_when_hurt(bool) split_when_hurt = bool end
function enemy:get_split_when_hurt() return split_when_hurt end

function enemy:on_hurt()
  if not split_when_hurt then return end
  -- Create green slimys.
  local x, y, layer = self:get_position()
  local prop = {x = x, y = y, layer = layer, direction = 0, breed = "slimy_green"}
  local s1 = map:create_enemy(prop)
  local s2 = map:create_enemy(prop)
  local s3 = map:create_enemy(prop)
  s1:jump(2 * math.pi / 12)
  s2:jump(10 * math.pi / 12)
  s3:jump(18 * math.pi / 12)
  self:remove()
end
