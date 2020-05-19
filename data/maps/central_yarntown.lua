local map = ...
local game = map:get_game()

map:register_event("on_started", function()

end)


function south_gate_switch:on_activated()
  map:open_doors"south_gate"
end

function gilbert_gate_switch:on_activated()
  map:open_doors"gilbert_gate"
end
