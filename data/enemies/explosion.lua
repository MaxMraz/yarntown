-- Explosion enemy. Just an explosion.

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local sound = "explosion" -- Default explosion sound.

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  enemy:prepare_explosion_sprite()
  enemy:set_invincible() -- Invincible!!!
  enemy:set_life(1)
  enemy:set_damage(12) -- Damage: 3 full hearts!!!
  enemy:set_layer_independent_collisions(true) -- Detect collisions from any layer.
  -- Play explosion sound!!!
  sol.audio.play_sound(sound)
end

-- Prepare sprite. Parameters are optional.
function enemy:prepare_explosion_sprite(sprite_id, sprite_animation, direction)
  -- Remove previous sprite.
  local explosion_sprite = self:get_sprite()
  if explosion_sprite then self:remove_sprite(explosion_sprite) end
  -- Create new sprite.
  local id = sprite_id or "destructibles/vase_purple"
  local animation = sprite_animation or "destroy"
  local dir = direction or 0
  explosion_sprite = self:create_sprite(id)
  explosion_sprite:set_animation(animation)
  explosion_sprite:set_direction(dir)
  -- Remove explosion after explosion animation.
  function explosion_sprite:on_animation_finished()
    enemy:remove()
  end
end
