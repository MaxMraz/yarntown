local menu = {}

function menu:initialize(game)
	game:register_event("on_paused", function()
		sol.menu.start(game, menu)
	end)

	game:register_event("on_unpaused", function()
		sol.menu.stop(menu)
	end)
end

function menu:on_started()
	local game = sol.main.get_game()
	game:start_dialog("_game.pause", function(answer)
		if answer == 1 then
			game:save()
			game:set_paused(false)
		elseif answer == 2 then
			sol.main.reset()
		end
	end)
end

function menu:on_command_pressed(cmd)
	local handled = false
  if cmd == "attack" then
  	handled = true
  end

  return handled
end

return menu