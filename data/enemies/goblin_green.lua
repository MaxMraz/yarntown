-- Lua script of enemy Goblin Green.

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite, weapon_sprite, weapon, has_weapon, has_throwable_weapon
local behavior = "passive" -- Values: "passive", "aggressive".
local detection_distance = 64
local throw_axe_distance = 100
local club_attack_distance = 50
local body_damage = 2
local speed_axe, speed_nut = 100, 160
local club_sound_id = "slash"
local throw_axe_sound_id = "slash"
local axe_hit_shield_sound_id = "shield"
local throw_slingshot_sound_id = "throw"
local slingshot_hit_shield_sound_id = "shield"

--[[ CUSTOM PROPERTY "weapon" has values:
"club", "axe", "none" (or nil), "slingshot", "random".
--]]

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Initialize sprites and weapon from custom properties.
  weapon = self:get_property("weapon")
  self:set_weapon(weapon) -- Create sprites depending on the weapon.
  self:set_life(3)
  self:set_damage(body_damage)
  -- General shield properties.
  if self.set_default_behavior_on_hero_shield then
    self:set_default_behavior_on_hero_shield("normal_shield_push")
  end
end

-- Event called when the enemy should start or restart its movements.
function enemy:on_restarted()
  -- Wait a delay when restarted.
  self:stop_movement()
  sprite.on_animation_finished = nil
  sprite.on_frame_changed = nil
  for _, s in self:get_sprites() do
    if s:has_animation("stopped") then s:set_animation("stopped") end
  end
  local delay = math.random(500, 1000)
  sol.timer.start(map, delay, function()
    if behavior == "aggressive" and self:get_distance(hero) <= detection_distance then
      self:start_walking("go_to_hero")
    else
      self:start_walking("wander")
    end
  end)
  -- Check hero for throwing.
  if has_throwable_weapon and self:get_distance(hero) <= throw_axe_distance then
    if has_throwable_weapon then self:throw() end
  end
end

-- Weapon names: "club", "axe", "slingshot", "random".
function enemy:get_weapon() return weapon end
function enemy:set_weapon(weapon_name)
  -- Choose random weapon, if necessary.
  local weapon_list = {"club", "axe", "slingshot"}
  if weapon_name == "random" then
    local index = math.random(1, #weapon_list)
    weapon_name = weapon_list[index]
  end
  weapon = weapon_name
  -- Destroy weapons and sprites.
  sprite, weapon_sprite, has_weapon, has_throwable_weapon = nil, nil, nil
  for _, sp in self:get_sprites() do self:remove_sprite(sp) end
  -- Set sprites and properties for each weapon.
  local weapon_damage = 0
  if weapon ~= "slingshot" then
    sprite = self:create_sprite("enemies/goblin_green")
  end
  if weapon_name == "club" then
    has_weapon, weapon_damage = true, 2
    behavior = "aggressive"
  elseif weapon_name == "axe" then
    weapon_damage = 3
    has_weapon, has_throwable_weapon = true, true
  elseif weapon_name == "slingshot" then
    -- Replace main sprite.
    has_weapon, has_throwable_weapon = true, true
    sprite = self:create_sprite("enemies/goblin_green_slingshot")    
  end
  if weapon_name == "club" or weapon_name == "axe" then
    weapon_sprite = enemy:create_sprite("enemies/goblin_" .. weapon)
    self:set_sprite_damage(weapon_sprite, weapon_damage)
    self:set_invincible_sprite(weapon_sprite)
    self:set_attack_consequence_sprite(weapon_sprite, "sword", "custom")
  end
  -- Club collision with shield.
  if weapon_sprite and weapon_sprite.set_default_behavior_on_hero_shield then
    weapon_sprite:set_default_behavior_on_hero_shield("enemy_strong_to_shield_push")
  end
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

-- Walking behaviors: "go_to_hero", "wander".
function enemy:start_walking(behavior)
  -- Prepare sprite animations.
  for _, s in self:get_sprites() do
    if s:has_animation("walking") then s:set_animation("walking") end
  end
  -- Start behavior.
  if behavior == "go_to_hero" then
    local m = sol.movement.create("target")
    m:set_target(hero)
    m:set_speed(math.random(50, 65))
    m:start(enemy)
    sol.timer.start(enemy, 250, function()
      if enemy:get_distance(hero) > detection_distance then
        enemy:restart()
        return
      elseif weapon == "club" and enemy:get_distance(hero) < club_attack_distance then
        -- Choose randomly if there will be a club attack or not.
        if math.random(0, 1) == 0 then
          enemy:club_attack()
          return
        end
      end
      return true
    end)
    -- Throw axe, if any.
    if weapon == "axe" then self:throw() end
  elseif behavior == "wander" then
    local m = sol.movement.create("straight")
    m:set_smooth(false)
    m:set_angle(math.random(0, 3) * math.pi / 2)
    m:set_speed(math.random(35, 50))
    m:set_max_distance(math.random(16, 80))
    function m:on_obstacle_reached() enemy:restart() end
    function m:on_finished() enemy:restart() end
    m:start(enemy)
  end
end

-- Throw weapons: "axe" or "seed" (slingshot).
function enemy:throw()
  -- Do nothing if there is no weapon.
  if not has_throwable_weapon then return end
  -- Disable throwable weapon for a while.
  local proj_sprite_id, speed
  local weapon_name = weapon
  if weapon_name == "axe" then
    proj_sprite_id = "enemies/goblin_axe"
    self:remove_sprite(weapon_sprite)
    weapon_sprite, has_weapon, has_throwable_weapon = nil, nil, nil
    speed = speed_axe
  elseif weapon_name == "slingshot" then
    proj_sprite_id = "enemies/goblin_green_slingshot"
    has_throwable_weapon = nil
    speed = speed_nut
  end
  sprite:set_animation("throw")
  function sprite:on_animation_finished(anim)
    if anim == "throw" then self:set_animation("stopped") end
  end
  sol.timer.start(map, 5000, function()
    self:set_weapon(weapon_name)
  end)
  -- Create thrown entity.
  local x, y, layer = self:get_position()
  local dir = sprite:get_direction()
  local prop = {x=x, y=y, layer=layer, direction=dir, width=16, height=16,
    breed="generic_projectile"}
  local projectile = map:create_enemy(prop)
  local proj_sprite = projectile:create_sprite(proj_sprite_id)
  proj_sprite:set_animation("thrown")
  -- Create movement for projectile.
  projectile:stop_movement()
  local m = sol.movement.create("straight")
  m:set_smooth(false)
  if weapon_name == "slingshot" then
    m:set_angle(dir * math.pi/2)
    m:set_speed(speed_nut)
  elseif weapon_name == "axe" then
    m:set_angle(self:get_angle(hero))
    m:set_speed(speed_axe)
  end
  m:set_max_distance(300)
  function projectile:on_obstacle_reached() projectile:remove() end
  function projectile:on_movement_finished() projectile:remove() end
  m:start(projectile)
  -- Initialize collision properties.
  local behavior
  if weapon_name == "axe" then
    projectile:set_invincible(true)
    behavior = "normal_shield_push"
  elseif weapon_name == "slingshot" then
    behavior = "enemy_weak_to_shield_push"
    function projectile:on_dying()
      self:get_sprite():set_animation("nut_break")
    end
  end
  if projectile.set_default_behavior_on_hero_shield then
    projectile:set_default_behavior_on_hero_shield(behavior)
  end
  -- Start throw sounds.
  if weapon_name == "axe" then
    sol.audio.play_sound(throw_axe_sound_id)
    if projectile.set_pushed_by_shield_property then
      projectile:set_pushed_by_shield_property("sound_id", axe_hit_shield_sound_id)
    end
  elseif weapon_name == "slingshot" then
    sol.audio.play_sound(throw_slingshot_sound_id)
    if projectile.set_pushed_by_shield_property then
      projectile:set_pushed_by_shield_property("sound_id", slingshot_hit_shield_sound_id)
    end
  end
  -- Override normal push function.
  function projectile:on_shield_collision(shield)
    -- Disable push for a while.
    self:set_being_pushed(true)
    sol.timer.start(map, 200, function()
      self:set_being_pushed(false)
    end)
    -- Hurt enemies after bounce on shield.
    self:allow_hurt_enemies(true)
    -- Override movement.
    local m = projectile:get_movement()
    if not m then return end
    m = sol.movement.create("straight")
    local angle = 0
    if weapon_name == "axe" then
      angle = shield:get_angle(projectile)
      m:set_speed(speed_axe)
    elseif weapon_name == "slingshot" then
      angle = shield:get_direction4_to(projectile) * math.pi/2
      m:set_speed(speed_nut)
    end
    m:set_angle(angle)
    m:set_smooth(false)
    m:set_max_distance(300)
    m:start(self)
    -- Disable collisions to avoid problems.
    self.on_shield_collision = nil
    if self.set_default_behavior_on_hero_shield then
      self:set_default_behavior_on_hero_shield(nil)
    end
  end
end

-- Attack with club a random number of times.
function enemy:club_attack()
  if weapon ~= "club" then self:restart(); return end
  self:stop_movement()
  local num_attacks = math.random(1,3)
  function sprite:on_frame_changed(animation, frame)
    if frame == 1 or frame == 3 then
      sol.audio.play_sound(club_sound_id)
    end
  end
  sprite:set_animation("attack")
  weapon_sprite:set_animation("attack")
  function sprite:on_animation_finished()
    num_attacks = num_attacks - 1
    if num_attacks > 0 then
      sprite:set_animation("attack")
      weapon_sprite:set_animation("attack")
    else
      enemy:restart()
    end
  end
end

-- Push hero if sword hits the club.
function enemy:on_custom_attack_received(attack, sprite)
  if not hero.push then return end
  if weapon == "club" and attack == "sword" and sprite == weapon_sprite then
    local p = weapon_sprite:get_push_hero_on_shield_properties()
    p.pushing_entity = self
    hero:push(p)
  end
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