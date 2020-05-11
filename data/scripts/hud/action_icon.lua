-- The icon that shows what the action command does.

local hud_icon_builder = require("scripts/hud/hud_icon")

local action_icon_builder = {}

function action_icon_builder:new(game, config)

  local action_icon = {}

  -- Creates the hud icon delegate.
  action_icon.hud_icon = hud_icon_builder:new(game, "action", config.x, config.y, config.dialog_x, config.dialog_y)
  action_icon.hud_icon:set_background_sprite(sol.sprite.create("hud/icon_action"))
  
  -- Initializes the icon.
  action_icon.effect_displayed = nil

  -- Draws the icon surface.
  function action_icon:on_draw(dst_surface)
    action_icon.hud_icon:on_draw(dst_surface)
  end

  -- Rebuild the foreground (called only when needed).
  function action_icon:rebuild_foreground()
    if action_icon.effect_displayed == nil or action_icon.effect_displayed == "" then
      -- No foreground if no effect.
      action_icon.hud_icon:set_foreground(nil)
    else
      local text = sol.language.get_string("hud."..action_icon.effect_displayed)
      action_icon.hud_icon:set_foreground_text(text)
    end
  end
    
  -- Returns if the icon is enabled or disabled.
  function action_icon:is_enabled(active)
    return action_icon.hud_icon:is_enabled()
  end

  -- Set if the icon is enabled or disabled.
  function action_icon:set_enabled(enabled)
    if enabled then
      action_icon:update_effect_displayed(false)
    end
    action_icon.hud_icon:set_enabled(enabled)
  end
      
  -- Returns if the icon is active or inactive.
  function action_icon:is_active(active)
    return action_icon.hud_icon:is_active()
  end

  -- Set if the icon is active or inactive.
  function action_icon:set_active(active)
    action_icon.hud_icon:set_active(active)
  end

  -- Returns if the icon is transparent or not.
  function action_icon:is_transparent()
    return action_icon.hud_icon:set_transparent()
  end

  -- Sets if the icon is transparent or not.
  function action_icon:set_transparent(transparent)
    action_icon.hud_icon:set_transparent(transparent)
  end

  -- Gets the position of the icon.
  function action_icon:get_dst_position()
    return action_icon.hud_icon:get_dst_position()
  end

  -- Sets the position of the icon.
  function action_icon:set_dst_position(x, y)
    action_icon.hud_icon:set_dst_position(x, y)
  end

  -- Gets the normal position of the icon.
  function action_icon:get_normal_position()
    return action_icon.hud_icon:get_normal_position()
  end

  -- Gets the dialog position of the icon.
  function action_icon:get_dialog_position()
    return action_icon.hud_icon:get_dialog_position()
  end

  -- Called when the command effect changes.
  function action_icon:on_command_effect_changed(effect)
  end

  -- Checks if the icon needs a refresh.
  function action_icon:update_effect_displayed(flip_icon)
    if not action_icon.hud_icon.animating then
      local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("action") or game:get_command_effect("action")
      action_icon:set_effect_displayed(effect, flip_icon)
    end
  end

  -- Sets the effect to be displayed on the icon.
  function action_icon:set_effect_displayed(effect, flip_icon)
    if effect ~= action_icon.effect_displayed then
      -- Store the current command.
      action_icon.effect_displayed = effect
        
      -- Update the icon foreground.
      action_icon:rebuild_foreground()
      
      -- Flip the icon.
      if flip_icon then
        action_icon.hud_icon:flip_icon()
      end

      -- Update the icon visibility.
      if action_icon.on_command_effect_changed then
        action_icon:on_command_effect_changed(effect)
      end
    end
  end

  function action_icon:on_mouse_pressed(button, x, y)
    return action_icon.hud_icon:on_mouse_pressed(button, x, y)
  end

  function action_icon:on_mouse_released(button, x, y)
    return action_icon.hud_icon:on_mouse_released(button, x, y)
  end

  function action_icon:on_finger_pressed(finger, x, y, pressure)
    return action_icon.hud_icon:on_finger_pressed(finger, x, y, pressure)
  end

  function action_icon:on_finger_released(finger, x, y, pressure)
    return action_icon.hud_icon:on_finger_released(finger, x, y, pressure)
  end

  -- Called when the menu is started.
  function action_icon:on_started()
    action_icon:update_effect_displayed(false)

    -- Check every 50ms if the icon needs a refresh.
    sol.timer.start(action_icon, 50, function()
      action_icon:update_effect_displayed(true)
      return true
    end)
  end

  -- Returns the menu.
  return action_icon
end

return action_icon_builder
