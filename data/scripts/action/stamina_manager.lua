local menu = {}
local game

function menu:start(game)

  --regen stamina 
  sol.timer.start(game, 200, function()
    if not game:is_suspended() then
      game:add_stamina(10)
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
    if game.stamina <0 then
    	game.stamina = 0
    end    
  end


end


return menu