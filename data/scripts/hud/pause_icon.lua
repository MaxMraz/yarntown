-- The icon that shows what the pause command does.

local hud_icon_builder = require("scripts/hud/hud_icon")

local pause_icon_builder = {}

function pause_icon_builder:new(game, config)

  local pause_icon = {}

  -- Creates the hud icon delegate.
  pause_icon.hud_icon = hud_icon_builder:new(game, "pause", config.x, config.y)
  pause_icon.hud_icon:set_background_sprite(sol.sprite.create("hud/icon_pause"))

  -- Initializes the icon.
  pause_icon.effect_displayed = nil

  -- Draws the icon surface.
  function pause_icon:on_draw(dst_surface)
    pause_icon.hud_icon:on_draw(dst_surface)
  end

  -- Rebuild the foreground (called only when needed).
  function pause_icon:rebuild_foreground()
    if pause_icon.effect_displayed == nil or pause_icon.effect_displayed == "" then
      -- No foreground if no effect.
      pause_icon.hud_icon:set_foreground(nil)
    else
      -- Text.
      local text = sol.language.get_string("hud."..pause_icon.effect_displayed)
      pause_icon.hud_icon:set_foreground_text(text)
    end
  end
  
  -- Returns if the icon is enabled or disabled.
  function pause_icon:is_enabled(active)
    return pause_icon.hud_icon:is_enabled()
  end

  -- Set if the icon is enabled or disabled.
  function pause_icon:set_enabled(enabled)
    pause_icon.hud_icon:set_enabled(enabled)
  end
        
  -- Returns if the icon is active or inactive.
  function pause_icon:is_active(active)
    return pause_icon.hud_icon:is_active()
  end

  -- Set if the icon is active or inactive.
  function pause_icon:set_active(active)
    pause_icon.hud_icon:set_active(active)
  end

  -- Returns if the icon is transparent or not.
  function pause_icon:is_transparent()
    return pause_icon.hud_icon:set_transparent()
  end

  -- Sets if the icon is transparent or not.
  function pause_icon:set_transparent(transparent)
    pause_icon.hud_icon:set_transparent(transparent)
  end

  -- Called when the menu is started.
  function pause_icon:on_started()
    pause_icon:rebuild_foreground()    
  end

  -- Checks if the icon needs a refresh.
  function pause_icon:update_effect_displayed(flip_icon)
    if not pause_icon.hud_icon.animating then
      local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("pause") or game:get_command_effect("pause")
      pause_icon:set_effect_displayed(effect, flip_icon)
    end
  end

  -- Sets the effect to be displayed on the icon.
  function pause_icon:set_effect_displayed(effect, flip_icon)
    if effect ~= pause_icon.effect_displayed then
      -- Store the current command.
      pause_icon.effect_displayed = effect
        
      -- Update the icon foreground.
      pause_icon:rebuild_foreground()
      
      -- Flip the icon.
      if flip_icon then
        pause_icon.hud_icon:flip_icon()
      end

      -- Update the icon visibility.
      if pause_icon.on_command_effect_changed then
        pause_icon:on_command_effect_changed(effect)
      end
    end
  end

  function pause_icon:on_mouse_pressed(button, x, y)
    return pause_icon.hud_icon:on_mouse_pressed(button, x, y)
  end

  function pause_icon:on_mouse_released(button, x, y)
    return pause_icon.hud_icon:on_mouse_released(button, x, y)
  end

  function pause_icon:on_finger_pressed(finger, x, y, pressure)
    return pause_icon.hud_icon:on_finger_pressed(finger, x, y, pressure)
  end

  function pause_icon:on_finger_released(finger, x, y, pressure)
    return pause_icon.hud_icon:on_finger_released(finger, x, y, pressure)
  end

  -- Listens to the on_paused event, to update the text.
  game:register_event("on_paused", function()
    pause_icon:set_effect_displayed("return", true)
  end)
  
  -- Listens to the on_unpaused event, to update the text.
  game:register_event("on_unpaused", function()
    pause_icon:set_effect_displayed("pause", true)
  end)

  pause_icon:set_effect_displayed("pause")

  -- Returns the menu.
  return pause_icon
end

return pause_icon_builder
