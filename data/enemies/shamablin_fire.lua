-- Lua script of enemy Shamablin Fire.

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local body_sprite, growing_fireball
local life, body_damage = 1, 2
local spell_detection_distance = 200
local fireball_speed = 120

-- Event called when the enemy is initialized.
function enemy:on_created()
  body_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  self:set_life(life)
  self:set_damage(body_damage)
  -- General shield properties.
  if self.set_default_behavior_on_hero_shield then
    self:set_default_behavior_on_hero_shield("normal_shield_push")
  end
end

-- Event called when the enemy should start or restart its movements.
function enemy:on_restarted()
  -- Restart things.
  self:stop_movement()
  for _, s in self:get_sprites() do
    if s:has_animation("stopped") then s:set_animation("stopped") end
  end
  if growing_fireball then
    growing_fireball:remove()
    growing_fireball = nil
  end
  -- Check hero for attack.
  if self:get_distance(hero) <= spell_detection_distance then
    -- Throw fireball if hero is close.
    self:throw_fireball_to(hero)
  else -- Random walk if hero is far.
    -- Wait a delay before wander.
    local delay = math.random(500, 1000)
    sol.timer.start(map, delay, function()
      self:start_wander()
    end)
  end
end

-- Throw fireball towards an entity, in the closest 4-direction.
function enemy:throw_fireball_to(entity)
  -- Stop enemy. Set spell animation.
  self:stop_movement()
  sol.timer.stop_all(self)
  body_sprite:set_animation("spell")
  local dir = self:get_direction4_to(entity)
  body_sprite:set_direction(dir)
  -- Create fireball and set creating animation.
  local x, y, layer = self:get_position()
  local angle = dir * math.pi / 2
  local x, y = x + 16 * math.cos(angle), y - 16 * math.sin(angle)
  local fireball = map:create_enemy({x = x, y = y, layer = layer, direction = dir,
    breed = "generic_projectile"})
  growing_fireball = fireball
  local fireball_sprite = fireball:create_sprite(enemy:get_sprite():get_animation_set())
  fireball_sprite:set_animation("create_fireball")
  -- Set fireball custom properties.
  fireball:set_invincible()
  if fireball.set_default_behavior_on_hero_shield then
    fireball:set_default_behavior_on_hero_shield("burn_push")
  end
  -- Start movement on fireball after creating animation.
  function fireball:on_restarted() -- This avoids restart problem.
    fireball_sprite:set_animation("create_fireball")
  end
  function fireball_sprite:on_animation_finished(anim)
    if anim ~= "create_fireball" then
     self:set_animation("create_fireball")
     return
    end
    fireball_sprite:set_animation("fireball")
    local m = sol.movement.create("straight")
    m:set_smooth(false)
    m:set_angle(angle)
    m:set_speed(fireball_speed)
    m:set_max_distance(300)
    function m:on_obstacle_reached() fireball:remove() end
    function m:on_finished() fireball:remove() end
    m:start(fireball)
    -- Play fireball sound.
    sol.audio.play_sound("fire_ball")
    -- Wait a delay before enemy wanders.
    body_sprite:set_animation("stopped")
    local delay = math.random(500, 1000)
    sol.timer.start(map, delay, function()
      enemy:start_wander()
    end)
  end
end

-- Wander randomly.
function enemy:start_wander()
  body_sprite:set_animation("walking")
  local m = sol.movement.create("straight")
  m:set_smooth(false)
  m:set_angle(math.random(0, 3) * math.pi / 2)
  m:set_speed(math.random(35, 50))
  m:set_max_distance(math.random(16, 80))
  function m:on_obstacle_reached() enemy:restart() end
  function m:on_finished() enemy:restart() end
  m:start(enemy)
end

-- Update direction.
function enemy:on_movement_changed(movement)
  local direction4 = movement:get_direction4()
  if direction4 then
    for _, s in enemy:get_sprites() do
      s:set_direction(direction4)
    end
  end
end

function enemy:on_hurt(attack)
  if growing_fireball then
    growing_fireball:remove()
    growing_fireball = nil
  end
end
function enemy:on_dying()
  if growing_fireball then
    growing_fireball:remove()
    growing_fireball = nil
  end
end
