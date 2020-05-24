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


  item:set_finished()
end

function item:select_target()
  local hero = game:get_hero()
  local map = game:get_map()
  local direction = hero:get_direction()
  local AIM_SPREAD = math.rad(45)
  local RANGE = 128
  local angles = {[0] = 0, [1] = math.pi / 2, [2] = math.pi, [3] = 3* math.pi / 2}
  local potential_enemies = {}

  hero:freeze()

  --see who's in range
  for enemy in map:get_entities_by_type"enemy" do
    if math.abs( hero:get_angle(enemy) - angles[direction] ) < AIM_SPREAD and hero:get_distance(enemy) < RANGE then
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
if not closest_enemy then print"no enemy found" end
    if closest_enemy then closest_enemy:get_shot() end
    hero:unfreeze()
    item:set_finished()
  end)

end
