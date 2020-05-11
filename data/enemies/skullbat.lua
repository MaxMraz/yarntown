-- Lua script for "skullbat" enemy.

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local state
local detection_distance = 80
local speed = 50
local damage = 1
local life, flying_life = 2, 1
local wings_stopped_animation, wings_walking_animation
local wings_color = "random" -- Possible values: "random", "white", "green", "brown".
local max_height, current_height = 24, 0
local min_distance, max_distance = 10, 40 -- Used for each small movement.
local head_sprite, wings_sprite, shadow_sprite
local height_timer, shadow_timer -- Used to ascend and descend.

-- Event called when the enemy is initialized.
function enemy:on_created()
  -- Create sprites.
  local sprite_id = "enemies/" .. enemy:get_breed()
  shadow_sprite = self:create_sprite("shadows/shadow_big_dynamic", "shadow")
  shadow_sprite:set_xy(0, -6)
  head_sprite = self:create_sprite(sprite_id, "body")
  wings_sprite = self:create_sprite(sprite_id, "wings")
  -- Select wings color.
  local colors = {"white", "green", "brown"}
  if wings_color == "random" then
    local index = math.random(1, #colors)
    wings_color = colors[index]
  end
  wings_stopped_animation = "stopped_wings_" .. wings_color
  wings_walking_animation = "walking_wings_" .. wings_color
  -- Set properties. Shadow and wings are decoration.
  wings_sprite:synchronize(head_sprite)
  self:set_invincible_sprite(shadow_sprite)
  self:set_invincible_sprite(wings_sprite)
  self:set_sprite_damage(shadow_sprite, 0)
  self:set_sprite_damage(wings_sprite, 0)
  if head_sprite.set_default_behavior_on_hero_shield then  
    head_sprite:set_default_behavior_on_hero_shield("enemy_weak_to_shield_push")
  end
  head_sprite.on_shield_collision_test = enemy.custom_attacking_collision_test -- Collision test.
  self:set_damage(damage) -- Head damage.
  self:set_life(life)
  self:set_obstacle_behavior("flying")
  self:set_attack_consequence_sprite(head_sprite, "sword", enemy.on_sword_collision)
  -- Update sprites.
  function head_sprite:on_animation_changed(anim)
    if anim == "stopped" then
      self:set_animation("stopped_head"); return
    elseif anim == "walking" then
      self:set_animation("walking_head"); return
    elseif anim == "hurt" then
      self:set_animation("hurt_head"); return
    elseif wings_sprite then 
      if anim == "stopped_head" then
        wings_sprite:set_animation(wings_stopped_animation)
      elseif anim == "walking_head" then
        wings_sprite:set_animation(wings_walking_animation)
      elseif anim == "hurt_head" then
        wings_sprite:set_animation("hurt_wings")
      end
    end
  end
  function head_sprite:on_frame_changed(anim, frame)
    if wings_sprite and wings_sprite:get_num_frames() > frame then wings_sprite:set_frame(frame) end
  end
  function head_sprite:on_direction_changed(anim, dir)
    if wings_sprite then wings_sprite:set_direction(dir) end
  end
  function wings_sprite:on_animation_changed(anim)
    if anim == "stopped" then
      self:set_animation(wings_stopped_animation)
    elseif anim == "walking" then
      self:set_animation(wings_walking_animation)
    elseif anim == "hurt" then
      self:set_animation("hurt_wings")
    end
  end

  -- TODO: CONVERT IN JUMPING SKULL AFTER HURT! (DRAW AND CODE).

end

-- Event called when the enemy is restarted.
function enemy:on_restarted()
  self:wait_for_hero() -- Update state.
  if wings_sprite then
    self:update_shadow() -- Update shadow frame.
  end
end

-- Event called when the enemy is hurt.
function enemy:on_hurt()
  self:update_shadow() -- Update shadow frame.
end

-- Get/set state values: "waiting", "flying", "ascending", "descending".
function enemy:get_state() return state end
function enemy:set_state(new_state)
  state = new_state -- Update state.
  -- Update sprites.
  local body_animation
  if state == "waiting" and current_height == 0 then
    body_animation = "stopped"
  elseif state == "flying" or current_height > 0 then
    body_animation = "walking"
  end
  head_sprite:set_animation(body_animation)
  -- Update height.
  if state == "waiting" then
    self:update_height(0)
  elseif state == "flying" then
    self:update_height(max_height)
  end
end

-- Check if the hero is close, to start movement.
function enemy:wait_for_hero()
  self:set_state("waiting")
  sol.timer.start(self, 500, function()
    if enemy:get_distance(hero) <= detection_distance then
      if wings_sprite then
        enemy:start_flying()
      else
        enemy:start_jumping()
      end
      return false
    end
    return true
  end)
end

-- Start ascending effect.
function enemy:update_height(new_height)
  -- Stop height timers.
  if height_timer then height_timer:stop() end
  if new_height == current_height then return end
  -- Update height for body and wings sprites. Update shadow frame.
  local dh = ((new_height > current_height) and 1)
          or ((new_height < current_height) and -1)
  height_timer = sol.timer.start(enemy, 50, function()
    current_height = current_height + dh
    head_sprite:set_xy(0, -current_height)
    wings_sprite:set_xy(0, -current_height)
    if new_height == current_height then
      -- Update animations after descending, if necessary.
      if state == "waiting" and current_height == 0 then
        head_sprite:set_animation("stopped")
      end
      return -- Stop timer.
    end
    return true
  end)
end

-- Update shadow frame and animation.
function enemy:update_shadow()
  -- Stop shadow timers.
  if shadow_timer then shadow_timer:stop() end
  -- Update shadow frame while ascending or descending.
  shadow_sprite:set_animation("ascend")
  local num_frames = shadow_sprite:get_num_frames()
  shadow_timer = sol.timer.start(enemy, 10, function()
    local frame = math.floor((current_height / max_height) * num_frames)
    frame = math.min(frame, num_frames - 1)
    shadow_sprite:set_animation("ascend")
    shadow_sprite:set_frame(frame)
    return true
  end)
end

-- Start circular movement, towards the hero if possible.
function enemy:start_flying()
  self:set_state("flying")
  local hx, hy, _ = hero:get_position()
  local x, y, _ = self:get_position()
  local a = sol.main.get_angle(x, y, hx, hy) -- In radians.
  local deviation = (2 * math.random() - 1) * (2 * math.pi / 3)
  a = (a + deviation) % (2 * math.pi)
  local dir4 = math.floor(4 * a / (2 * math.pi)) % 4 
  local distance = math.random(min_distance, max_distance)
  local m = sol.movement.create("straight")
  m:set_speed(speed)
  m:set_angle(a)
  m:set_max_distance(distance)
  function m:on_finished()
    if enemy:get_distance(hero) <= detection_distance then
      enemy:start_flying() -- Start new movement.
    else
      enemy:wait_for_hero() -- Wait for hero.
    end
  end
  function m:on_obstacle_reached()
    enemy:restart()
  end
  -- Update sprite directions.
  for _, s in self:get_sprites() do s:set_direction(dir4) end
  m:start(self) -- Start movement.
end

-- Destroy wings sprite.
function enemy:destroy_wings()
  self:remove_sprite(wings_sprite)
  self:remove_sprite(shadow_sprite)
  shadow_sprite = self:create_sprite("shadows/shadow_big_dynamic", "shadow")
  self:bring_sprite_to_back(shadow_sprite)
  shadow_sprite:set_xy(0, -6)
  self:set_invincible_sprite(shadow_sprite)
  self:set_sprite_damage(shadow_sprite, 0)

  -- TODO: change to jumping behavior.
end

-- Custom test used in enemy_meta script and also in this script.
-- Decide if enemy can hurt hero and viceversa, depending on the flying height.
function enemy:custom_attacking_collision_test()
  if current_height < 24 and not (hero.is_jumping and hero:is_jumping()) then
    return "ground_collision_possible"
  elseif current_height >= 24 and (hero.is_jumping and hero:is_jumping()) then
    return "air_collision_possible"
  end
  return nil -- No possible collision.
end

-- Avoid sword attacks while flying, unless the hero is jumping.
function enemy:on_sword_collision()
  if not enemy:custom_attacking_collision_test() then return end
  enemy:hurt(1)
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