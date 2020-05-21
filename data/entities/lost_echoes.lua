local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local echoes_amount
local sprite

function entity:on_created()
  echoes_amount = game:get_value("lost_echoes_amount")
  sprite = entity:create_sprite("entities/lost_echoes")
  sprite:set_blend_mode"add"

  entity:add_collision_test("sprite", function(entity, other_entity)
    if other_entity:get_type() == "hero" then
      game:add_money(echoes_amount)
      game:set_value("lost_echoes_map", nil)
      game:set_value("lost_echoes_x", nil)
      game:set_value("lost_echoes_y", nil)
      game:set_value("lost_echoes_z", nil)
      game:set_value("lost_echoes_amount", nil)
      entity:remove()
    end
  end)

end
