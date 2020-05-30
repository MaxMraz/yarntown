--Increases weapon power as collected
local item = ...
local game = item:get_game()

function item:on_started()

end


function item:on_using()

  item:set_finished()
end

