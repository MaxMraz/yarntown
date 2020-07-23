require("scripts/multi_events")
local dash_manager = require("scripts/action/dash_manager")
local weapon_manager = require"scripts/action/weapon_manager"

local menu = {}

function menu:initialize(game)
  --Debug Mode Toggle:
  local debug_mode = false
  function game:set_debug_mode(mode)
  	debug_mode = mode
  end

  --Default key bindings
  local wasd = false
  local function controls(game)
  	if not wasd then return end
    game:set_command_keyboard_binding("action", "return")
    game:set_command_keyboard_binding("up", "w")
    game:set_command_keyboard_binding("left", "a")
    game:set_command_keyboard_binding("down", "s")
    game:set_command_keyboard_binding("right", "d")
    game:set_command_keyboard_binding("pause", "f")
  end
  game:register_event("on_started", controls)

  function game:on_key_pressed(key, modifiers)
    local hero = game:get_hero()

    if key == "r"  and debug_mode then
      if hero:get_walking_speed() == 300 then
        hero:set_walking_speed(debug.normal_walking_speed)
      else
        debug.normal_walking_speed = hero:get_walking_speed()
        hero:set_walking_speed(300)
      end

    elseif key == "t" and debug_mode then
      if not ignoring_obstacles then
        hero:get_movement():set_ignore_obstacles(true)
        ignoring_obstacles = true
      else
        hero:get_movement():set_ignore_obstacles(false)
        ignoring_obstacles = false
      end

    elseif key == "h" and debug_mode then
      game:set_life(game:get_max_life())

    elseif key == "j" and debug_mode then
--      game:remove_life(10)
      hero:start_hurt(200)

    elseif key == "m" and debug_mode then
      print("You are on map: " .. game:get_map():get_id())
      local x, y, l = hero:get_position()
      print("at coordinates: " .. x .. ", " .. y .. ", " .. l)

    elseif key == "y" and debug_mode then
      --helicopter shot
      if not game.helicopter_cam then
        game:get_map():helicopter_cam()
      else
        game:get_map():exit_helicopter_cam()
        require("scripts/action/hole_drop_landing"):play_landing_animation()
      end

         --end of debug functions
          --]]

    end

  end


  local can_dash = true
  function game:on_command_pressed(action)
    local handled = false

  --Roll / Dash
  local ignoring_obstacles
  local hero = game:get_hero()
    if action == "action" then
      local effect = game:get_command_effect("action")
      local hero_state = hero:get_state()
      local dx = {[0] = 8, [1] = 0, [2] = -8, [3] = 0}
      local dy = {[0] = 0, [1] = -8, [2] = 0, [3] = 8}
      local direction = hero:get_direction()
      local has_space = not hero:test_obstacles(dx[direction], dy[direction])
      if  effect == nil and hero_state == "free" and hero:get_controlling_stream() == nil
      and not game:is_suspended() and can_dash and has_space then
        dash_manager:dash(game)
        can_dash = false
        sol.timer.start(game, 500, function() can_dash = true end)
      end

    --Attack  
    elseif action == "attack" and not game:is_suspended() then
      weapon_manager:process_attack_input()
      handled = true

    end 

    return handled
  end

  function game:on_joypad_button_pressed(btn)
    local handled = false
    if btn == 7 then
      game:simulate_command_pressed"pause"
      handled = true

    elseif btn == 4 then --left bumper
      handled = true
    elseif btn == 5 then --right bumper
      handled = true
    end

    return handled
  end

  function game:on_joypad_hat_moved(hat, direction)
    handled = false
    if hat == 0 then
      if direction == 0 then
        game:simulate_command_released("up")
        game:simulate_command_released("down")
        game:simulate_command_pressed("right")
        handled = true
      elseif direction == 1 then
        game:simulate_command_released("down")
        game:simulate_command_pressed("right")
        game:simulate_command_pressed("up")
        handled = true
      elseif direction == 2 then
        game:simulate_command_released("left")
        game:simulate_command_released("right")
        game:simulate_command_pressed("up")
        handled = true
      elseif direction == 3 then
        game:simulate_command_released("right")
        game:simulate_command_pressed("up")
        game:simulate_command_pressed("left")
        handled = true
      elseif direction == 4 then
        game:simulate_command_released("up")
        game:simulate_command_released("down")
        game:simulate_command_pressed("left")
        handled = true
      elseif direction == 5 then
        game:simulate_command_released("up")
        game:simulate_command_pressed("left")
        game:simulate_command_pressed("down")
        handled = true
      elseif direction == 6 then
        game:simulate_command_released("left")
        game:simulate_command_released("right")
        game:simulate_command_pressed("down")
        handled = true
      elseif direction == 7 then
        game:simulate_command_released("left")
        game:simulate_command_pressed("down")
        game:simulate_command_pressed("right")
        handled = true
      elseif direction == -1 then
        game:simulate_command_released("right")
        game:simulate_command_released("up")
        game:simulate_command_released("left")
        game:simulate_command_released("down")
        handled = true
      end
    end
    return handled
  end
  
end

return menu