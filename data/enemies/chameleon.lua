-- Lua script of enemy chameleon.
-- This script is executed every time an enemy with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local life, damage = 1, 1
local sprite, shadow, eye_left, eye_right
local tongue -- Enemy for the tongue.
local appearing_delay, disappearing_delay = 20, 40
local disappearance_rate = 50 -- Percentage.
local attack_rate = 100 -- Percentage.
local is_invisible -- Values: true, "almost", false.
local min_walking_distance, max_walking_distance = 30, 100
local min_waiting_delay, max_waiting_delay = 1000, 3000
local min_walking_speed, max_walking_speed = 30, 60
local tongue_attack_speed, tongue_retreat_speed = 200, 250
local lick_distance = 150
local has_tongue, is_attacking = true, false


-- Event called when the enemy is initialized.
function enemy:on_created()
  -- Create main sprites.
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  shadow = enemy:create_sprite("enemies/" .. enemy:get_breed())
  eye_left = enemy:create_sprite("enemies/" .. enemy:get_breed())
  eye_right = enemy:create_sprite("enemies/" .. enemy:get_breed())
  function shadow:on_animation_changed(anim)
    if anim ~= "shadow" then shadow:set_animation("shadow") end
  end
  function eye_left:on_animation_changed(anim)
    if anim ~= "eye" then eye_left:set_animation("eye"); sprite:update_eyes() end
  end
  function eye_right:on_animation_changed(anim)
    if anim ~= "eye" then eye_right:set_animation("eye"); sprite:update_eyes() end
  end
  shadow:set_animation("shadow")
  eye_left:set_animation("eye")
  eye_right:set_animation("eye")
  self:bring_sprite_to_back(shadow)
  self:bring_sprite_to_front(eye_left)
  self:bring_sprite_to_front(eye_right)
  -- Set properties.
  enemy:set_life(life)
  enemy:set_damage(damage)
  self:set_invincible_sprite(shadow)
  self:set_sprite_damage(shadow, 0)
  self:set_invincible_sprite(eye_left)
  self:set_sprite_damage(eye_left, 0)
  self:set_invincible_sprite(eye_right)
  self:set_sprite_damage(eye_right, 0)
  -- Shield collisions.
  if sprite.set_default_behavior_on_hero_shield then
    sprite:set_default_behavior_on_hero_shield("enemy_weak_to_shield_push")
  end
  function sprite:on_pushed_by_shield(shield) enemy:destroy_tongue() end
  -- Update eye sprites.
  function sprite:update_eyes()
    local anim, dir4 = self:get_animation(), self:get_direction()
    if anim ~= "stopped" then -- Hide eyes.
      eye_left:set_direction(8)
      eye_right:set_direction(8)
      return
    end
    local shift_left = {[0]={5,-10}, [1]={-4,-17}, [2]={-6,-10}, [3]={-4,-5}}
    local shift_right = {[0]={5,-10}, [1]={3,-17}, [2]={-6,-10}, [3]={3,-5}}
    shift_left = shift_left[dir4]; shift_right = shift_right[dir4]
    eye_left:set_xy(shift_left[1], shift_left[2])
    eye_right:set_xy(shift_right[1], shift_right[2])
  end
  function sprite:on_animation_changed(anim) self:update_eyes() end
  function sprite:on_direction_changed(anim, dir) self:update_eyes() end
end

-- Update eyes direction towards hero.
function enemy:start_moving_eyes()
  sol.timer.start(self, 250, function()
    if sprite:get_animation() == "stopped" then
      local dir8 = enemy:get_direction8_to(hero)
      eye_left:set_direction(dir8)
      eye_right:set_direction(dir8)
    end
    return true
  end)
end

-- Event called when the enemy is restarted.
function enemy:on_restarted()
  -- Do nothing while attacking.
  if is_attacking then return end
  -- Restart things.
  self:stop_movement()
  for _, s in self:get_sprites() do
    sprite:set_animation("stopped")
  end
  enemy:start_moving_eyes()
  -- Set visible if necessary.
  if is_invisible == true then self:appear() end
  -- Check hero distance for different behaviors.
  if not is_invisible and self:get_distance(hero) <= lick_distance then
    if self:get_has_tongue() and self:get_direction4_to(hero) == sprite:get_direction()
        and math.random(1, 100) <= attack_rate then
      -- Tongue attack if hero is close and in front of enemy.
      self:tongue_attack(hero)
      return
    elseif math.random(1, 100) <= disappearance_rate then
      -- Disappear with certain probability.
      self:disappear()
    end
  end
  -- Wait a delay before wander.
  local delay = math.random(min_waiting_delay, max_waiting_delay)
  sol.timer.start(map, delay, function()
    self:start_wander()
  end)  
end

-- Update direction.
function enemy:on_movement_changed(movement)
  local dir4 = movement:get_direction4()
  if dir4 then
    for _, s in pairs{shadow, sprite} do
      if dir4 <= s:get_num_directions() then s:set_direction(dir4) end
    end
  end
end

-- Get/set tongue enabled.
function enemy:get_has_tongue() return has_tongue end
function enemy:set_has_tongue(bool) has_tongue = bool end

-- Wander randomly.
function enemy:start_wander()
  if is_attacking then return end
  sprite:set_animation("walking")
  local m = sol.movement.create("straight")
  m:set_smooth(false)
  m:set_angle(math.random(0, 2*math.pi))
  m:set_speed(math.random(min_walking_speed, max_walking_speed))
  m:set_max_distance(math.random(min_walking_distance, max_walking_distance))
  function m:on_obstacle_reached() enemy:restart() end
  function m:on_finished() enemy:restart() end
  m:start(enemy)
end

-- Disappear and start invincibility.
function enemy:disappear()
  is_invisible = "almost"
  self:set_invincible_sprite(sprite)
  self:set_sprite_damage(sprite, 0)
  sprite:fade_out(disappearing_delay, function() is_invisible = true end)
  for _, s in pairs({shadow, eye_left, eye_right}) do
    s:fade_out(disappearing_delay)
  end
  if sprite.set_can_be_pushed_by_shield then
    sprite:set_can_be_pushed_by_shield(false)
  end
end

-- Appear and stop invincibility.
function enemy:appear()
  is_invisible = "almost"
  sprite:fade_in(appearing_delay, function()
    enemy:set_default_attack_consequences_sprite(sprite)
    self:set_sprite_damage(sprite, damage)
    is_invisible = false
  end)
  for _, s in pairs({shadow, eye_left, eye_right}) do
    s:fade_in(appearing_delay)
  end
  if sprite.set_can_be_pushed_by_shield then
    sprite:set_can_be_pushed_by_shield(true)
  end
end

-- Destroy tongue when necessary.
function enemy:destroy_tongue()
  if tongue then
    tongue:remove()
    tongue, is_attacking = nil, false
  end
end
function enemy:on_hurt(attack) self:destroy_tongue() end
function enemy:on_dying() self:destroy_tongue() end

-- Tongue attack towards an entity!
function enemy:tongue_attack(entity)
  if self:get_has_tongue() == false then
    self:restart()
    return
  end
  -- Prepare enemy.
  sol.timer.stop_all(self)
  self:stop_movement()
  is_attacking = true
  sprite:set_animation("attack")
  -- Create tongue enemy.
  local x, y, layer = self:get_position()
  local dir = sprite:get_direction()
  local prop = {x = x, y = y, layer = layer, direction = dir,
      breed = "generic_projectile"}
  tongue = map:create_enemy(prop)
  tongue.enemy = enemy
  tongue:bring_to_back() -- Draw below!
  tongue:set_pushed_back_when_hurt(false)
  tongue:set_damage(damage)
  tongue:set_life(1)
  function tongue:on_hurt(attack)
    local e = tongue.enemy
    if tongue:get_life() <= 0 then e:set_has_tongue(false) end
    e:add_life(1); e:hurt(1) -- Show hurt animation without hurting.
  end
  -- Create tongue main sprite.
  local tongue_sprite = tongue:create_sprite("enemies/" .. enemy:get_breed())
  tongue_sprite:set_animation("tongue")
  tongue_sprite:set_direction(dir)
  function tongue_sprite:on_animation_changed(anim)
    if anim ~= "tongue" then tongue_sprite:set_animation("tongue") end
  end
  tongue.on_movement_changed = nil -- Destroy default function.
  tongue.sprites = {} -- Secondary sprites.
  -- Create tongue movement.
  local m = sol.movement.create("straight")
  m:set_angle(dir * math.pi / 2)
  m:set_speed(tongue_attack_speed)
  m:set_max_distance(lick_distance)
  m:start(tongue)
  m.tongue = tongue
  function m:on_obstacle_reached() m.tongue:go_back() end
  function m:on_finished() m.tongue:go_back() end
  -- Create retreat movement.
  function tongue:go_back()
    if not tongue then return end -- USED TEMPORARILY TO AVOID BUG???
    local m = sol.movement.create("target")
    m:set_target(enemy)
    m:set_speed(tongue_retreat_speed)
    m:set_ignore_obstacles(true)
    m:start(tongue)
    function m:on_finished()
      if tongue then m:stop(); enemy:destroy_tongue() end
      sprite:set_animation("stopped")
      enemy:on_tongue_attack_finished()
    end
  end
  -- Update number of tongue sprites.
  function tongue:on_position_changed()
    -- Add/remove tongue sprites if necessary.
    local d = tongue:get_distance(enemy)
    local list = tongue.sprites
    local num_sprites = #list
    local num_necessary = math.floor(d / 8) + 1
    local dir = tongue_sprite:get_direction()
    while num_necessary ~= num_sprites do
      if num_necessary > num_sprites then -- Add sprite.
        local s = tongue:create_sprite("enemies/" .. enemy:get_breed())
        list[num_sprites + 1] = s
        tongue:bring_sprite_to_back(s)
        s:set_animation("tongue_middle")
        s:set_direction(dir)
        function s:on_animation_changed(anim)
          if anim ~= "tongue_middle" then s:set_animation("tongue_middle") end
        end
      elseif num_necessary < num_sprites then -- Remove sprite.
        local s = list[num_sprites]
        list[num_sprites] = nil
        tongue:remove_sprite(s)
      end
      num_sprites = #list -- Update number.
    end
    -- Update shifts for tongue sprites.
    local a = ((dir + 2) % 4) * math.pi / 2
    local dx, dy = math.cos(a), (-1) * math.sin(a)
    local sf = 8 - (d % 8) -- Final shift.
    for k, s in ipairs(list) do s:set_xy(8 * dx * k, 8 * dy * k) end
    if num_sprites > 0 then -- Fix last shift.
      local s = list[num_sprites]
      local dist = (8 * num_sprites) - sf
      s:set_xy(dx * dist, dy * dist)
    end
    -- Move attached entity, if any, and if possible.
    local attached = tongue.attached_entity
    if attached and attached:exists() then
      if attached:test_obstacles(dx, dy) then
        tongue.attached_entity = nil
      else
        local x, y, layer = attached:get_position()
        attached:set_position(x + dx, y + dy, layer)
      end
    end
  end
  -- Enable tongue main sprite collision with shield.
  if tongue_sprite.set_can_be_pushed_by_shield then
    tongue_sprite:set_can_be_pushed_by_shield(true)
  end
  function tongue_sprite:on_shield_collision(shield)
    enemy:on_tongue_collision_shield(shield)
  end
  -- Add condition for shield collision: opposite direction and sprite collision.
  function tongue_sprite:on_shield_collision_test(shield)
    local sh_dir = shield:get_direction()
    local dir = self:get_direction()
    if (sh_dir + 2) % 4 == dir and shield:overlaps(tongue, "sprite") then
      return true
    end
  end
end
-- Delay before restarting.
function enemy:on_tongue_attack_finished()
  local delay = math.random(min_waiting_delay, max_waiting_delay)
  sol.timer.start(self, delay, function() enemy:restart() end)
end

-- Custom event. Push enemy towards shield.
function enemy:on_tongue_collision_shield(shield)
  -- Do nothing if there is an entity attached.
  if tongue.attached_entity then return end
  -- Attach hero entity.
  tongue:go_back()
  tongue.attached_entity = hero
  -- Play tongue sound once (to avoid noise).
  if not tongue.has_played_sound then
    sol.audio.play_sound("tongue")
    tongue.has_played_sound = true
  end
  -- Unattach hero when shield disappears.
  sol.timer.start(tongue, 1, function()
    if (not shield:exists()) or (not shield:overlaps(tongue, "sprite")) then
      tongue.attached_entity = nil
      return
    end
    return true
  end)
end



-- Attach a custom damage to the sprites of the enemy.
function enemy:get_sprite_damage(sprite)
  return (sprite and sprite.custom_damage) or self:get_damage()
end
function enemy:set_sprite_damage(sprite, damage)
  sprite.custom_damage = damage
end

-- Warning: do not override these functions if you use the "custom shield" script.
function enemy:on_attacking_hero(hero, enemy_sprite)
  local enemy = self
  local hero = enemy:get_map():get_hero()
  -- Do nothing if enemy sprite cannot hurt hero.
  if enemy:get_sprite_damage(enemy_sprite) == 0 then return end
  local collision_mode = enemy:get_attacking_collision_mode()
  if not hero:overlaps(enemy, collision_mode) then return end  
  -- Do nothing when shield is protecting.
  if hero.is_shield_protecting_from_enemy
      and hero:is_shield_protecting_from_enemy(enemy, enemy_sprite) then
    return
  end
  -- Check for a custom attacking collision test.
  if enemy.custom_attacking_collision_test and
      not enemy:custom_attacking_collision_test(enemy_sprite) then
    return
  end
  -- Otherwise, hero is not protected. Use built-in behavior.
  local damage = enemy:get_damage()
  if enemy_sprite then
    hero:start_hurt(enemy, enemy_sprite, damage)
  else
    hero:start_hurt(enemy, damage)
  end
end