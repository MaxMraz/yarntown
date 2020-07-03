local menu = {}
local game

function menu:start(game)
  sol.timer.start(game, 100, function()
    if (game.stamina_regain_block_points or 0) > 0 then
      game.stamina_regain_block_points = game.stamina_regain_block_points - 1
    elseif not game:is_suspended() then
      game:add_stamina(25)
    end
    return true
  end)


  function game:add_stamina(amount)
    game.stamina = game.stamina + amount
    if game.stamina >= game:get_value"max_stamina" then
    	game.stamina = game:get_value"max_stamina"
    end
  end

  function game:remove_stamina(amount)
    game.stamina = game.stamina - amount
    if game.stamina <0 then game.stamina = 0 end
    game.stamina_regain_block_points = 10 --block points are 100ms increments before stamina starts refilling again
  end


end


return menu