local lighting_effects = {}

local effects = {
  torch = sol.sprite.create"entities/effects/light_l",
  candle = sol.sprite.create"entities/effects/light_s",
  explosion = sol.sprite.create"entities/effects/light_xl",
  hero_aura = sol.sprite.create"entities/effects/light_m",
  lantern = sol.sprite.create"entities/effects/light_l",
}

local shadow_surface
local light_surface
local darkness_color


function lighting_effects:initialize()
  --scale effects to proper size:
--  effects.hero_aura:set_scale(2, 2)
--  effects.torch:set_scale(2, 2)
--  effects.explosion:set_scale(1, 1)

  --add color to effects
  effects.torch:set_color_modulation{255, 230, 150}
  effects.candle:set_color_modulation{255, 230, 130}
  effects.hero_aura:set_color_modulation{255, 230, 180}
  effects.lantern:set_color_modulation{230, 210, 240}
  effects.explosion:set_color_modulation{255, 240, 180}

  --set blend modes
  for i=1, #effects do
    effects[i]:set_blend_mode"blend"
  end

  --create surfaces
  shadow_surface = sol.surface.create()
  shadow_surface:set_blend_mode"multiply"
  light_surface = sol.surface.create()
  light_surface:set_blend_mode"add"

  --set default darkness level
  darkness_color = {70,90,100}
end


function lighting_effects:set_darkness_level(level)
  if level == 1 then
    darkness_color = {150,180,200}
  elseif level == 2 then
    darkness_color = {100,115,135}
  elseif level == 3 then
    darkness_color = {75,85,90}
  elseif level == 4 then
    darkness_color = {20,40,55}
  elseif level == 5 then
    darkness_color = {5, 15, 25}
  elseif level == "dusk" then
    darkness_color = {240,229,210}
  elseif level == "night" then
    darkness_color = {100,115,135}
  else
    darkness_color = level
  end
end

function lighting_effects:fade_to_darkness_level(level)
  if lighting_effects.color_fade_timer then lighting_effects.color_fade_timer:stop() end
  if level == 1 then
    new_darkness_color = {150,180,200}
  elseif level == 2 then
    new_darkness_color = {100,115,135}
  elseif level == 3 then
    new_darkness_color = {75,85,90}
  elseif level == 4 then
    new_darkness_color = {20,40,55}
  elseif level == 5 then
    new_darkness_color = {5, 15, 25}
  elseif level == "dusk" then
    new_darkness_color = {240,229,210}
  elseif level == "night" then
    new_darkness_color = {100,115,135}
  else
    new_darkness_color = level
  end

  local r1, g1, b1 = darkness_color[1], darkness_color[2], darkness_color[3]
  local r2, g2, b2 = new_darkness_color[1], new_darkness_color[2], new_darkness_color[3]

  lighting_effects.color_fade_timer = sol.timer.start(sol.main.get_game(), 10, function()
    local r_step = 1
    local g_step = 1
    local b_step = 1
    if math.abs(r1-r2) > 10 then r_step = 5 end
    if math.abs(g1-g2) > 10 then g_step = 5 end
    if math.abs(b1-b2) > 10 then b_step = 5 end
    if r1 > r2 then r_step = r_step * -1 elseif r1 == r2 then r_step = 0 end
    if r1 > r2 then g_step = g_step * -1 elseif g1 == g2 then g_step = 0 end
    if r1 > r2 then b_step = b_step * -1 elseif b1 == b2 then b_step = 0 end
    r1 = r1 + r_step
    g1 = g1 + g_step
    b1 = b1 + b_step    
    darkness_color = {r1, g1, b1}
    if r1 == r2 and g1 == g2 and b1 == b2 then
    else return true
    end
  end)

end


--name for specific entities:
--^lighting_effect_torch
--^lighting_effect_candle

function lighting_effects:on_draw(dst_surface)
  local game = sol.main.get_game()
  local map = game:get_map()
  local hero = map:get_hero()
  local cam_x, cam_y = map:get_camera():get_position()
  local hx, hy, hz = hero:get_position()

  --clear the surfaces
  light_surface:clear()
  shadow_surface:clear()
  --color surfaces
  shadow_surface:fill_color(darkness_color)


--=========================================================================================--
  --draw different light effects
  --hero aura:
  if hero.torch then
    effects.hero_aura:draw(light_surface, hx - cam_x, hy - cam_y)
  end
  --torches:
  for e in map:get_entities("^lighting_effect_torch") do
    if e:is_enabled() and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.torch:draw(light_surface, x - cam_x, y - cam_y)
    end
  end
  --candles:
  for e in map:get_entities("^lighting_effect_candle") do
    if e:is_enabled() and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.candle:draw(light_surface, x - cam_x, y - cam_y)
    end
  end
  --Lanterns
  for e in map:get_entities_by_type("custom_entity") do
    if e:is_enabled() and e:get_model() == "lantern" and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.lantern:draw(light_surface, x - cam_x, y - cam_y)
    end
  end
  --explosions
  for e in map:get_entities_by_type("explosion") do
    if e:is_enabled() and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.explosion:draw(light_surface, x - cam_x, y - cam_y)
    end
  end
  --fire
  for e in map:get_entities_by_type("fire") do
    if e:is_enabled() and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.torch:draw(light_surface, x - cam_x, y - cam_y)
    end
  end
  for e in map:get_entities_by_type("custom_entity") do
    if e:get_model() == "fire" and e:is_enabled() and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.torch:draw(light_surface, x - cam_x, y - cam_y)
    end
  end

  --fire arrows
  for e in map:get_entities_by_type("custom_entity") do
    if e:is_enabled() and e:get_model() == "arrow_fire" and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.candle:draw(light_surface, x - cam_x, y - cam_y)
    end
  end
  --iron candles
  for e in map:get_entities_by_type("custom_entity") do
    if e:is_enabled() and e:get_name() == "iron_candle_entity" and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.candle:draw(light_surface, x - cam_x, y - cam_y)
    end
  end
  --lightning
  for e in map:get_entities_by_type("custom_entity") do
    if e:is_enabled() and e:get_name() == "lightning_attack" and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      effects.torch:draw(light_surface, x - cam_x, y - cam_y)
    end
  end
  --enemies
  for e in map:get_entities_by_type("enemy") do
    if e:is_enabled() and e.lighting_effect and e:get_distance(hero) <= 450 then
      local x,y = e:get_center_position()
      if e.lighting_effect == 1 then
        effects.candle:draw(light_surface, x - cam_x, y - cam_y)
      end
      if e.lighting_effect == 2 then
        effects.torch:draw(light_surface, x - cam_x, y - cam_y)
      end
    end
  end

  

  light_surface:draw(shadow_surface)
  shadow_surface:draw(dst_surface)
end

return lighting_effects