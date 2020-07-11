local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = game:get_hero()


function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)

  --Touching test
  entity:add_collision_test("touching", function(entity, other_entity)
    if other_entity:get_type() == "enemy" and other_entity.agro then
      entity:destroy()
    end

    if other_entity:get_type() == "hero" and other_entity:get_animation() == "roll" then
      entity:destroy()
    end
  end)

  --Sprite test
  entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
    if other_entity:get_type() == "hero" and other_entity:get_animation() == "roll" then
      entity:destroy()
    end

    if other_entity:get_type() == "enemy" and other_entity.agro then
      entity:destroy()
    end

    if other_sprite:get_animation_set() == hero:get_sword_sprite_id() then
      entity:destroy()
    end
  end)

end

function entity:destroy()
  entity:clear_collision_tests()
  sol.audio.play_sound("breaking_crate_" .. math.random(1,5))
  entity:get_sprite():set_animation("destroy", function()
    entity:set_traversable_by(true)
    entity:remove()
  end)
  --alert nearby enemies
  local ALERT_DISTANCE = 100
  for enemy in map:get_entities_by_type"enemy" do
    if enemy:get_distance(entity) < ALERT_DISTANCE and enemy:get_layer() == hero:get_layer() and not enemy.agro then
      if enemy.agro_cone then enemy.agro_cone:remove() enemy.agro_cone = nil end
      enemy:start_agro()
    end
  end
end
