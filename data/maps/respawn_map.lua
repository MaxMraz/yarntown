local map = ...
local game = map:get_game()

map:register_event("on_started", function()
print"at respawn map"
end)
