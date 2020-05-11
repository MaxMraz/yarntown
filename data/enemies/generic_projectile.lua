-- Lua script of enemy projectile.
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
local default_damage = 1
local sprite

-- Event called when the enemy is initialized.
function enemy:on_created()
  -- Initialize properties.
  enemy:set_life(1)
  enemy:set_damage(1)
end

-- Event called when the enemy should start or restart its movements.
function enemy:on_restarted()
-- Nothing by default.
end

-- Update direction.
function enemy:on_movement_changed(movement)
  local dir = movement:get_direction4()
  if dir then
    for _, s in enemy:get_sprites() do
      if s:get_num_directions() > dir then s:set_direction(dir) end
    end
  end
end

-- Allow to hurt enemies.
function enemy:allow_hurt_enemies(allow_hurt)
  -- Define event.
  if not allow_hurt then
    enemy.on_collision_enemy = nil
    return
  end
  function enemy:on_collision_enemy(other_enemy, other_sprite, my_sprite)
    local life_points = self:get_damage()
    other_enemy:hurt(life_points)
    -- Call custom event after hurting enemy.
    self:on_hurt_enemy(other_enemy, other_sprite)
  end
end

-- CUSTOM EVENT: called after hurting an enemy. 
function enemy:on_hurt_enemy(other_enemy, other_sprite)
end
