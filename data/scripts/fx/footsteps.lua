local footstep_manager = {}

function footstep_manager:start()
  local game = sol.main.get_game()
  local hero = game:get_hero()
  sol.timer.start(game, 360, function()
    if hero:get_sprite():get_animation() == "walking"
    and hero:get_movement() and hero:get_movement():get_speed() > 1 then
      --normal ground
      if hero:get_ground_below() == "traversable" then
        sol.audio.play_sound("footsteps/stone_" .. math.random(1,4))
      --ladder
      elseif hero:get_ground_below() == "ladder" then
        sol.audio.play_sound("footsteps/ladder")
      end
    end
    return true
  end)
end

return footstep_manager