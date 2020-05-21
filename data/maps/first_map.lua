local map = ...
local game = map:get_game()

function sign:on_interaction()
  sol.menu.start(game, require"scripts/menus/level_up")
end
