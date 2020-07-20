local switch_meta = sol.main.get_metatable"switch"

switch_meta:register_event("on_created", function(self)
  local switch = self
  local map = switch:get_map()
  local x, y, z = switch:get_position()
  local entity = map:create_custom_entity{
    x = x, y = y, layer = z, width = 16, height = 16, direction = 0,
  }
  entity:set_origin(switch:get_origin())

  function entity:on_interaction()
    if not switch:is_activated() and not switch:is_walkable() and switch.on_activated then
      switch:get_sprite():set_animation"activated"
      sol.audio.play_sound"switch"
      switch:set_activated(true)
      switch:on_activated()

    elseif switch:is_activated() and not switch:is_walkable() and switch.on_inactivated then
      switch:get_sprite():set_animation"inactivated"
      sol.audio.play_sound"switch"
      switch:set_activated(false)
      switch:on_inactivated()
    end

  end

end)

return true