local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_pistol")
  item:set_assignable(true)
  item:set_variant(1)
  game:set_item_assigned(1, item)
end


function item:on_using()
  local hero = game:get_hero()
  local enemy = item:select_target()


--  item:set_finished()
end

function item:select_target()
  local hero = game:get_hero()
  local map = game:get_map()
  local direction = hero:get_direction()
  local AIM_SPREAD = math.rad(55)
  local RANGE = 128
  local potential_enemies = {}

  hero:freeze()

  --see who's in range
  function normalize(angle)
    return ((angle + math.pi) % (2 * math.pi)) - math.pi
  end
  for enemy in map:get_entities_by_type"enemy" do
    local enemy_angle = math.abs( normalize( hero:get_angle(enemy) - hero:get_direction() * math.pi/2 ) )
    if enemy_angle < AIM_SPREAD and hero:get_distance(enemy) < RANGE then
      potential_enemies[enemy] = true
    end
  end

  --of in-range enemies, shoot closest one
  local distance_to_enemy = 999999999999 --big number, doesn't matter
  local closest_enemy
  for enemy, _ in pairs(potential_enemies) do
    if hero:get_distance(enemy) < distance_to_enemy then
      distance_to_enemy = hero:get_distance(enemy)
      closest_enemy = enemy
    end
  end

  sol.audio.play_sound"hand_cannon"
  hero:set_animation("bow", function()
    if closest_enemy then closest_enemy:get_shot() end
    hero:unfreeze()
    potential_enemies = {}
    item:set_finished()
  end)

end
