local enemy = ...
local map = enemy:get_map()
local sprite
local jump_duration = 1000
local max_height = 16
local jumping_speed = 30

function enemy:on_created()
  self:set_size(8, 8)
  self:set_origin(4, 5)
  sprite = self:create_sprite("enemies/" .. enemy:get_breed())
  self:set_life(1)
  self:set_damage(1)
  self:set_pushed_back_when_hurt(false)
  -- Enable shield push.
  if self.set_default_behavior_on_hero_shield then
    self:set_default_behavior_on_hero_shield("enemy_weak_to_shield_push")
  end
end

function enemy:on_restarted()
  local h = map:get_hero()
  local m = sol.movement.create("target")
  m:set_target(h)
  m:set_speed(10)
  m:start(self)
  -- Jump after a certain delay if the hero is close.
  sol.timer.start(self, 5000, function()
   self:jump()
   return true
  end)
  -- Restart sprites to avoid bugs.
  local shadow = self:get_sprite("shadow")
  if shadow then self:remove_sprite(shadow) end
  self:get_sprite():set_xy(0, 0)
end

function enemy:jump(jump_angle)
  local a = jump_angle
  -- Start jump.
  local sprite = self:get_sprite()
  sprite:set_animation("stopped")
  sol.audio.play_sound("jump")
  self:set_invincible() -- Set invincible.
  self:set_can_attack(false) -- Do not attack hero during jump.
  -- Shield protection.
  if enemy.set_can_be_pushed_by_shield then enemy:set_can_be_pushed_by_shield(false) end
  -- Add a shadow sprite.
  local shadow = self:create_sprite("shadows/shadow_small", "shadow")
  -- Add movement towards near the hero during the jump. The jump does not target the hero.
  -- The angle is partially random to avoid too many enemies overlapping.
  -- If there is a jump_angle, use it by default instead of the random angle towards hero.
  local m = sol.movement.create("straight")
  if not a then
    a = self:get_angle(self:get_map():get_hero())
    math.randomseed(os.time()) -- Initialize random seed.
    local d = 2*math.random() - 1 -- Random real number in [-1,1].
    a = a + d*math.pi/4 -- Alter jumping angle, randomly.
  end
  m:set_speed(jumping_speed)
  m:set_angle(a)
  m:start(self)
  -- Start shift on sprite.
  local function f(t) -- Shifting function.
    return math.floor(4 * max_height * (t / jump_duration - (t / jump_duration) ^ 2))
  end
  local t = 0
  local refreshing_time = 10
  sol.timer.start(self, refreshing_time, function() -- Update shift each 10 milliseconds.
    sprite:set_xy(0, -f(t))
    t = t + refreshing_time
    if t <= jump_duration then
      return true
    else
      self:remove_sprite(shadow)
      self:set_can_attack(true) -- Allow to attack after jump.      
      if enemy.set_can_be_pushed_by_shield then 
        enemy:set_can_be_pushed_by_shield(true) -- Finish shield protection.
      end
      self:set_default_attack_consequences() -- Stop invincibility after jump.
      self:restart()
      return false
    end
  end)
end
