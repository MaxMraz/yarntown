local map = ...
local game = map:get_game()

map:register_event("on_started", function()
  local light_fx = require"scripts/fx/lighting_effects"
  light_fx:initialize()
  light_fx:set_darkness_level("dusk")
  sol.menu.start(map, light_fx)
end)


function south_gate_switch:on_activated()
  map:open_doors"south_gate"
end

function gilbert_gate_switch:on_activated()
  map:open_doors"gilbert_gate"
end

function musicbox_gate_switch:on_activated()
  map:open_doors"musicbox_gate"
end