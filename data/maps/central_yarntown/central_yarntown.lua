local map = ...
local game = map:get_game()
local light_fx
local area_darkness_level = "dusk"
local boss_bar = require"scripts/hud/boss_bar"

map:register_event("on_started", function()
  area_darkness_level = game:get_value"central_yarnham_area_darkness_level" or "dusk"
  light_fx = require"scripts/fx/lighting_effects"
  light_fx:set_darkness_level(area_darkness_level)
  sol.menu.start(map, light_fx)

  if game:get_value"boss_dead_cleric_beast" then
    cleric_beast:set_enabled(false)
    cleric_boss_music_sensor:set_enabled(false)
    great_bridge_lantern:set_enabled(true)
  end

  if game:get_value"boss_dead_gascoigne" then
    gascoigne:set_enabled(false)
    gascoigne_boss_music_sensor:set_enabled(false)
    oedon_tomb_lantern:set_enabled(true)
  end
end)


--Switches-------------------------------------------

function south_gate_switch:on_activated()
  map:open_doors"south_gate"
end

function gilbert_gate_switch:on_activated()
  map:open_doors"gilbert_gate"
end

function musicbox_gate_switch:on_activated()
  map:open_doors"musicbox_gate"
end

function elevator_gate_allow_sensor:on_activated()
 game:set_value("central_yarntown_elevator_gate_right_side", true)
end

--Make the dark house dark---------------------------------
for tele in map:get_entities("to_darkhouse") do
function tele:on_activated()
  sol.timer.start(map, 0, function()
    light_fx:fade_to_darkness_level(3)
  end)
end
end

for tele in map:get_entities("from_darkhouse") do
function tele:on_activated()
  sol.timer.start(map, 0, function()
    light_fx:fade_to_darkness_level(area_darkness_level)
  end)
end
end

--Make other dark places dark
for sensor in map:get_entities("dark_area_sensor") do
function sensor:on_activated()
  light_fx:fade_to_darkness_level(2)
end
end

for sensor in map:get_entities("gascoigne_dark_area_sensor") do
function sensor:on_activated()
  light_fx:fade_to_darkness_level({200,200,200})
end
end

for sensor in map:get_entities("leave_dark_area_sensor") do
function sensor:on_activated()
  light_fx:fade_to_darkness_level(area_darkness_level)
end
end



--Misc----------------------------------------------------------

function eileen_path_sensor:on_activated()
  eileen_path_sensor:remove()
  eileen_path_hider:remove()
end

function eileen:on_interaction()
  if not game:get_value"quest_eileen" then
    game:start_dialog("_npcs.eileen.1", function() hero:start_treasure("blood_vial", 3) end)
    game:set_value("quest_eileen", 0)
  else
    game:start_dialog"_npcs.eileen.2"
  end
end




--Cleric Beast---------------------------------------------------
function cleric_boss_music_sensor:on_activated()
  cleric_boss_music_sensor:remove()
  sol.audio.play_music"cleric_beast"
  for e in map:get_entities"cleric_beast_fog_gate" do
    e:set_enabled(true)
  end
  sol.menu.start(game, boss_bar)
  boss_bar:set_enemy(cleric_beast)
end

cleric_beast:register_event("on_dying", function()
  sol.menu.stop(boss_bar)
  game:set_value("boss_dead_cleric_beast", true)
  for e in map:get_entities"cleric_beast_fog_gate" do
    e:set_enabled(false)
  end
  sol.audio.play_music("cleric_beast_end", function() sol.audio.stop_music() end)
  sol.timer.start(map, 2600, function()
    map:create_poof(great_bridge_lantern:get_position())
    great_bridge_lantern:set_enabled(true)
    great_bridge_lantern:sparkle_effect()
  end)
end)


--Gascoigne---------------------------------------------------------
function gascoigne_boss_music_sensor:on_activated()
  gascoigne_boss_music_sensor:remove()
  sol.audio.play_music"cleric_beast"
  for e in map:get_entities"gascoigne_beast_fog_gate" do
    e:set_enabled(true)
  end
  sol.menu.start(game, boss_bar)
  boss_bar:set_enemy(gascoigne)
end

gascoigne:register_event("on_dying", function()
  sol.menu.stop(boss_bar)
  game:set_value("boss_dead_gascoigne", true)
  for e in map:get_entities"gascoigne_beast_fog_gate" do
    e:set_enabled(false)
  end
  sol.audio.play_music("cleric_beast_end", function() sol.audio.stop_music() end)
  sol.timer.start(map, 2600, function()
    map:focus_on(map:get_camera(), oedon_tomb_lantern, function()
      map:create_poof(oedon_tomb_lantern:get_position())
      oedon_tomb_lantern:set_enabled(true)
      oedon_tomb_lantern:sparkle_effect()
    end)
  end)
  game:set_value("central_yarnham_area_darkness_level", "night")
end)

