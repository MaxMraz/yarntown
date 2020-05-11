-- Lua script of enemy skelfos.
-- This script is executed every time an enemy with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

--[[ SKELFOS ENEMY SCRIPT
REMARK: you can initialize these variables as custom properties from the map script:
walking_behavior, watch_behavior, head_behavior, arms_behavior.
The possible values for each variable are given below. Default value is "random".
--]]

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local damage = 2 
local life = 4
local sprite_names = {"shadow", "body", "legs", "arms", "head"}
local sprites = {}
local synchronized_sprite_names = {"shadow", "legs", "arms", "head"} -- Synchronized with body.
local walking_behavior_list = {"go_to_hero", "wander"}
local current_walking_behavior
local arms_behavior_list = {"none", "throw_arms"}
local head_behavior_list = {"none", "carry_head", "throw_head"}
local watch_behavior_list = {"none", "watch_hero", "crazy"}
local detection_distance = 80 -- Used to detect the hero.
local min_walking_speed, max_walking_speed, running_speed = 15, 40, 50
local min_wander_distance, max_wander_distance = 16, 80
local min_wander_delay, max_wander_delay = 500, 1500
local throw_head_distance = 150 
local throw_arms_distance = 80
local unattach_head_distance = 100
local is_carrying_head
-- Behaviors: change these for testing.
local walking_behavior = enemy:get_property("walking_behavior") or "random"
local arms_behavior = enemy:get_property("arms_behavior") or "random"
local head_behavior = enemy:get_property("head_behavior") or "random"
local watch_behavior = enemy:get_property("watch_behavior") or "random"


-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Create sprites, from below to above.
  for _, name in pairs(sprite_names) do
    sprites[name] = self:create_sprite("enemies/" .. enemy:get_breed(), name)
  end
  -- Fix wrong animations if restarted by engine.
  for name, s in self:get_sprites() do
    function s:on_animation_changed(anim)
      if anim == "walking" or anim == "stopped" or anim == "hurt" then
        anim = anim .. "_" .. name
        if s:has_animation(anim) then s:set_animation(anim) end
      end
    end
  end
  -- Synchronize sprites with body: animation, frame and direction.
  local body = sprites.body
  function body:on_animation_changed(anim)
    -- Fix wrong animation if restarted by the engine.
    if anim == "walking" or anim == "stopped" or anim == "hurt" then
      self:set_animation(anim .. "_body")
      return
    end
    -- Update other sprites.
    if anim == "walking_body" then anim = "walking"
    elseif anim == "stopped_body" then anim = "stopped" end
    for _, name in pairs(synchronized_sprite_names) do
      local s = sprites[name]
      if s then
        local animation = anim .. "_" .. name
        if s and s:has_animation(animation) then s:set_animation(animation) end
      end
    end
  end
  function body:on_direction_changed(anim, dir)
    for _, name in pairs(synchronized_sprite_names) do
      local s = sprites[name]
      if s then
        local a = s:get_animation()
        if a == "stopped_" .. name or a == "walking_" .. name
              or is_carrying_head then 
          if s:get_num_directions() > dir then s:set_direction(dir) end
        end
      end
    end
  end
  function body:on_frame_changed(anim, frame)
    for _, name in pairs(synchronized_sprite_names) do
      local s = sprites[name]
      if s then
        local a = s:get_animation()
        if a == "stopped_" .. name or a == "walking_" .. name then 
          if s:get_num_frames() > frame then s:set_frame(frame) end
        end
      end
    end
  end

  -- Initialize the properties (life, damage, shield push, etc).
  self:set_life(life)
  self:set_damage(damage)
  if self.set_default_behavior_on_hero_shield then
    self:set_default_behavior_on_hero_shield("normal_shield_push")
  end
  -- Initialize behavior from the script custom properties. 
  walking_behavior = self:get_property("walking_behavior") or walking_behavior
  watch_behavior = self:get_property("watch_behavior") or watch_behavior
  arms_behavior = self:get_property("arms_behavior") or arms_behavior
  head_behavior = self:get_property("head_behavior") or head_behavior
  self:initialize_behavior()
end

-- Update directions and animations.
function enemy:on_movement_changed(movement)
  local dir4 = movement:get_direction4()
  if dir4 then sprites.body:set_direction(dir4) end
end
function enemy:on_movement_started()
  sprites.body:set_animation("walking_body")
end
function enemy:on_movement_finished()
  sprites.body:set_animation("stopped_body")
end

-- Initialize behavior.
function enemy:initialize_behavior()
  local function random_choice(list)
    local index = math.random(1, #list)
    return list[index]
  end
  -- Walking behavior.
  self:stop_movement()
  if walking_behavior == "random" then
    walking_behavior = random_choice(walking_behavior_list)
  end
  -- Watch behavior. Stop head synchronization if necessary.
  if watch_behavior == "random" then
    watch_behavior = random_choice(watch_behavior_list)
    if watch_behavior ~= "none" then
      for k, v in pairs(synchronized_sprite_names) do
        if v == "head" then synchronized_sprite_names[k] = nil end
      end
    end
  end
  -- Head behavior.
  if head_behavior == "random" then
    head_behavior = random_choice(head_behavior_list)
  end
  -- Arms behavior.
  if arms_behavior == "random" then
    arms_behavior = random_choice(arms_behavior_list)
  end
end

-- Event called when the enemy should start or restart its movements.
-- This is called for example after the enemy is created or after
-- it was hurt or immobilized.
function enemy:on_restarted()
  -- Restart sprite animations.
  self:stop_movement()
  current_walking_behavior = nil
  for name, s in pairs(sprites) do
    s:set_animation("stopped_" .. name)
  end
  -- Initialize behaviors.
  self:restart_walking_behavior()
  self:restart_watching_behavior()
  self:restart_head_behavior()
  self:restart_arms_behavior()
end

-- Start walking behavior.
function enemy:restart_walking_behavior()
  if walking_behavior == "go_to_hero" then -- Go to hero if close. Otherwise, wander.
    local function update_walking_behavior()
      local d = self:get_distance(hero)
      if d <= detection_distance and current_walking_behavior ~= "go_to_hero" then
        current_walking_behavior = "go_to_hero"
        self:go_to_hero()
      elseif d > detection_distance and current_walking_behavior ~= "wander" then
        current_walking_behavior = "wander"
        self:wander()
      end
      -- Refresh behavior if necesary.
      sol.timer.start(self, 1000, function()
        update_walking_behavior()
      end)
    end
    update_walking_behavior()
  elseif walking_behavior == "wander" then -- Wander.
    self:wander()
  end
end
-- Go to hero.
function enemy:go_to_hero()
  local m = sol.movement.create("target")
  m:set_target(hero)
  m:set_speed(running_speed)
  m:start(enemy)
end
-- Wander.
function enemy:wander()
  local m = sol.movement.create("straight")
  m:set_smooth(false)
  m:set_angle(math.random(0, 3) * math.pi / 2)
  m:set_speed(math.random(min_walking_speed, max_walking_speed))
  m:set_max_distance(math.random(min_wander_distance, max_wander_distance))
  local function restart_wander()
    local delay = math.random(min_wander_delay, max_wander_delay)
    sol.timer.start(enemy, delay, function() enemy:wander() end)
  end
  function m:on_obstacle_reached()
    enemy:stop_movement()
    restart_wander()
  end
  function m:on_finished() restart_wander() end
  m:start(enemy)
end

-- Watching behavior.
function enemy:restart_watching_behavior()
  if watch_behavior == "none" or sprites.head == nil then
    return
  elseif watch_behavior == "watch_hero" then
    sol.timer.start(self, 100, function()
      if not sprites.head then return end
      sprites.head:set_direction(self:get_direction4_to(hero))
      return true
    end)
  elseif watch_behavior == "crazy" then
    local sh = 2 * math.random(0, 1) - 1 -- Rotation sense: +1 or -1.
    sol.timer.start(self, 125, function()
      if not sprites.head then return end
      local dir4 = (sprites.head:get_direction() + sh) % 4
      sprites.head:set_direction(dir4)
      return true
    end)
  end
end

-- Head behavior.
function enemy:restart_head_behavior() 
  if is_carrying_head then return end
  if sprites.head then
    sprites.head:set_xy(0, 0) -- Restart head shift.
  end
  if sprites.head == nil or sprites.arms == nil
      or head_behavior == "none" then return end
  if head_behavior == "throw_head" then
    local delay = math.random(1000, 3000)
    sol.timer.start(self, delay, function()
      if self:get_distance(hero) <= throw_head_distance then
        self:unattach_head()
        sol.timer.start(self, 500, self.throw_head)
        return
      end
      return true
    end)
  elseif head_behavior == "carry_head" then
    local delay = math.random(1000, 3000)
    sol.timer.start(self, delay, function()
      if self:get_distance(hero) <= unattach_head_distance then
        self:unattach_head()
        sol.timer.start(self, 500, self.carry_head)
        return
      end
      return true
    end)
  end
end

-- Arms behavior.
function enemy:restart_arms_behavior()
  if is_carrying_head then return end
  if sprites.arms == nil or arms_behavior == "none" then return end
  local delay = math.random(1000, 3000)
  sol.timer.start(self, delay, function()
    if self:get_distance(hero) <= throw_arms_distance then
      self:throw_arms()
      return
    end
    return true
  end)
end

-- This is used to remove head or arms.
function enemy:remove_body_part(part_name)
  self:remove_sprite(sprites[part_name])
  sprites[part_name] = nil
  for _, list in pairs({sprite_names, synchronized_sprite_names}) do
    for k, v in pairs(list) do
      if v == part_name then list[k] = nil end
    end
  end
end

-- Unattach head.
function enemy:unattach_head()
  self:stop_movement()
  sprites.body:set_animation("stopped")
  sprites.body:set_direction(3)
  sprites.head:set_xy(0, -8) -- Shift head.
  sol.audio.play_sound("lift")
  sprites.arms:set_animation("lift_arms")
end

-- Carry head.
function enemy:carry_head()
  -- Replace animation and frame synchronization for head and arms.
  local head, arms = sprites.head, sprites.arms
  function head:on_animation_changed(anim)
    if anim == "hurt" then head:set_animation("hurt_head")
    elseif anim ~= "carried_head" then head:set_animation("carried_head") end
  end
  function arms:on_direction_changed(anim, dir)
    local sh = {[0] = {x = 13, y = 6}, [1] = {x = 0, y = -8},
                [2] = {x = -13, y = 6}, [3] = {x = 0, y = 20}}
    sh = sh[dir]
    head:set_xy(sh.x, sh.y) -- Update shifts.
  end
  arms:on_direction_changed(arms:get_animation(), arms:get_direction())
  function arms:on_animation_changed(anim)
    if anim == "hurt" then arms:set_animation("hurt_arms")
    elseif anim ~= "carry_arms" then arms:set_animation("carry_arms") end
  end
  head:set_animation("carried_head")
  arms:set_animation("carry_arms")
  is_carrying_head = true
  head_behavior = "none"
  if enemy:get_movement() == nil then enemy:restart() end
end

-- Throw head.
function enemy:throw_head()
  -- Remove head. Start throw animation.
  enemy:stop_movement()
  enemy:remove_body_part("head")
  sprites.arms:set_animation("carry_arms")
  sol.timer.start(enemy, 500, function() enemy:restart() end)
  head_behavior = "none"
  -- Create head projectile.
  local speed = 80 -- Speed for the movement
  local x, y, layer = enemy:get_position()
  local angle = enemy:get_angle(hero)
  local max_dist = enemy:get_distance(hero)
  local head = map:create_enemy({x = x, y = y, layer = layer, direction = 0,
               breed = "generic_projectile"})
  head:set_invincible()
  head:set_obstacle_behavior("flying")
  head:set_damage(damage)
  local head_sprite = head:create_sprite(enemy:get_sprite():get_animation_set())
  function head:on_attacking_hero(hero, enemy_sprite)
    return -- Do not hurt hero while falling.
  end
  function head_sprite:on_animation_changed(anim)
    if anim ~= "carried_head" then head_sprite:set_animation("carried_head") end
  end
  head_sprite:set_animation("carried_head")
  function head:kill()
    head:stop_movement()
    head.on_attacking_hero = nil
    local shadow = head:get_sprite("shadow")
    if shadow then head:remove_sprite(shadow) end
    head_sprite.on_animation_changed = nil
    head_sprite:set_animation("bone_crush", function()
      sol.audio.play_sound("enemy_killed")
      head:remove()
    end)
  end
  local m = sol.movement.create("straight")
  m:set_smooth(false)
  m:set_angle(angle)
  m:set_speed(speed)
  m:set_max_distance(max_dist)
  function m:on_obstacle_reached() head:kill() end
  function m:on_finished() head:kill() end
  m:start(head)
  -- Shift head sprite for the height.
  local duration = 1000 * max_dist / speed
  local max_height, refreshing_time, t = 40, 10, 0
  local function f(t) -- Shifting function.
    return math.floor(4 * max_height * (t / duration - (t / duration) ^ 2))
  end
  sol.timer.start(head, refreshing_time, function() -- Update shift each 10 milliseconds.
    head_sprite:set_xy(0, -f(t))
    t = t + refreshing_time
    if t > duration then
      head:kill()
      return
    else return true
    end
  end)
  -- Create shadow sprite.
  local shadow = head:create_sprite("shadows/shadow_small", "shadow")
  shadow:set_animation("walking")
  head:bring_sprite_to_back(shadow)
end

-- Throw arms.
function enemy:throw_arms()
  -- Start throw animation.
  self:stop_movement()
  sprites.body:set_animation("stopped_body")
  sprites.arms:set_animation("throw_arms", function()
    -- Create arms projectile.
    local x, y, layer = self:get_position()
    local random_angle = math.random(0, math.pi/2)
    for i = 1,4 do
      local bone = map:create_enemy({x = x, y = y, layer = layer, direction = 0,
                breed = "generic_projectile"})
      bone:set_obstacle_behavior("flying")
      bone:create_sprite(enemy:get_sprite():get_animation_set())
      bone:set_damage(damage)
      function bone:kill()
        bone:stop_movement()
        local x, y, layer = self:get_position()
        local crush = map:create_custom_entity({x=x, y=y, layer=layer, direction=0,
                      width=16, height=16, sprite=self:get_sprite():get_animation_set()})
        local crush_sprite = crush:get_sprite()
        crush_sprite:set_animation("bone_crush")
        function crush_sprite:on_animation_finished() crush:remove() end
        sol.audio.play_sound("enemy_killed")
        bone:remove()
      end
      function bone:on_shield_collision(shield) bone:kill() end -- Break bone on shield.
      function bone:on_hurt() bone:kill() end
      local m = sol.movement.create("straight")
      m:set_smooth(false)
      m:set_angle(random_angle + i*math.pi/2)
      m:set_speed(100)
      m:set_max_distance(300)
      function m:on_obstacle_reached() bone:kill() end
      function m:on_finished() bone:kill() end
      m:start(bone)
      bone:get_sprite():set_animation("bone")
    end
    -- Remove arms. Restart.
    self:remove_body_part("arms")
    enemy:restart()
  end)
end
