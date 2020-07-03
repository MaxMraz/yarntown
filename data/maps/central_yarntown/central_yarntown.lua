local map = ...
local game = map:get_game()
local light_fx
local area_darkness_level = "dusk"

map:register_event("on_started", function()
  light_fx = require"scripts/fx/lighting_effects"
  light_fx:set_darkness_level(area_darkness_level)
  sol.menu.start(map, light_fx)

  if game:get_value"boss_dead_cleric_beast" then
    cleric_beast:set_enabled(false)
    boss_music_sensor:set_enabled(false)
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

--Cleric Beast---------------------------------------------------
function boss_music_sensor:on_activated()
  boss_music_sensor:remove()
  sol.audio.play_music"cleric_beast"
  for e in map:get_entities"cleric_beast_fog_gate" do
    e:set_enabled(true)
  end
end

cleric_beast:register_event("on_dying", function()
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

