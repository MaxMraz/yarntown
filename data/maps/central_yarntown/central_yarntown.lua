local map = ...
local game = map:get_game()
local light_fx
local area_darkness_level = "dusk"

map:register_event("on_started", function()
  light_fx = require"scripts/fx/lighting_effects"
  light_fx:set_darkness_level(area_darkness_level)
  sol.menu.start(map, light_fx)
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
  light_fx:fade_to_darkness_level(1)
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

