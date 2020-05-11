-- The icon that shows what the attack command does.

local hud_icon_builder = require("scripts/hud/hud_icon")

local attack_icon_builder = {}

function attack_icon_builder:new(game, config)

  local attack_icon = {}

  -- Creates the hud icon delegate.
  attack_icon.hud_icon = hud_icon_builder:new(game, "attack", config.x, config.y, config.dialog_x, config.dialog_y)
  attack_icon.hud_icon:set_background_sprite(sol.sprite.create("hud/icon_attack"))
  
  -- Initializes the icon.
  attack_icon.effect_displayed = nil
  attack_icon.sword_displayed = nil
  attack_icon.item_sprite = sol.sprite.create("entities/items")
  attack_icon.item_sprite:set_animation("sword")

  -- Draws the icon surface.
  function attack_icon:on_draw(dst_surface)
    attack_icon.hud_icon:on_draw(dst_surface)
  end

  -- Rebuild the foreground (called only when needed).
  function attack_icon:rebuild_foreground()
    if attack_icon.effect_displayed == nil or attack_icon.effect_displayed == "" then
      -- No foreground if no effect.
      attack_icon.hud_icon:set_foreground(nil)
    elseif attack_icon.effect_displayed == "sword" then
      -- Sword icon.
      attack_icon.item_sprite:set_direction(attack_icon.sword_displayed - 1)
      attack_icon.hud_icon:set_foreground(attack_icon.item_sprite)
    else
      -- Text.
      local text = sol.language.get_string("hud."..attack_icon.effect_displayed)
      attack_icon.hud_icon:set_foreground_text(text)
    end
  end
    
  -- Returns if the icon is enabled or disabled.
  function attack_icon:is_enabled(active)
    return attack_icon.hud_icon:is_enabled()
  end

  -- Set if the icon is enabled or disabled.
  function attack_icon:set_enabled(enabled)
    if enabled then
      attack_icon:update_effect_displayed(false)
    end
    attack_icon.hud_icon:set_enabled(enabled)
  end
    
  -- Returns if the icon is active or inactive.
  function attack_icon:is_active(active)
    return attack_icon.hud_icon:is_active()
  end

  -- Set if the icon is active or inactive.
  function attack_icon:set_active(active)
    attack_icon.hud_icon:set_active(active)
  end

  -- Returns if the icon is transparent or not.
  function attack_icon:is_transparent()
    return attack_icon.hud_icon:set_transparent()
  end

  -- Sets if the icon is transparent or not.
  function attack_icon:set_transparent(transparent)
    attack_icon.hud_icon:set_transparent(transparent)
  end

  -- Gets the position of the icon.
  function attack_icon:get_dst_position()
    return attack_icon.hud_icon:get_dst_position()
  end

  -- Sets the position of the icon.
  function attack_icon:set_dst_position(x, y)
    attack_icon.hud_icon:set_dst_position(x, y)
  end

  -- Gets the normal position of the icon.
  function attack_icon:get_normal_position()
    return attack_icon.hud_icon:get_normal_position()
  end

  -- Gets the dialog position of the icon.
  function attack_icon:get_dialog_position()
    return attack_icon.hud_icon:get_dialog_position()
  end

  -- Called when the command effect changes.
  function attack_icon:on_command_effect_changed(effect)
  end

  -- Checks if the icon needs a refresh.
  function attack_icon:update_effect_displayed(flip_icon)
    if not attack_icon.hud_icon.animating then
      local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("attack") or game:get_command_effect("attack")
      local sword = game:get_ability("sword")
      attack_icon:set_effect_displayed(effect, sword, flip_icon)
    end
  end

  -- Sets the effect to be displayed on the icon.
  function attack_icon:set_effect_displayed(effect, sword, flip_icon)
    if effect ~= attack_icon.effect_displayed or sword ~= attack_icon.sword_displayed then
      -- Store the current command.
      attack_icon.effect_displayed = effect
      attack_icon.sword_displayed = sword

      -- Update the icon foreground.
      attack_icon:rebuild_foreground()
      
      -- Flip the icon.
      if flip_icon then
        attack_icon.hud_icon:flip_icon()
      end

      -- Update the icon visibility.
      if attack_icon.on_command_effect_changed then
        attack_icon:on_command_effect_changed(effect)
      end
    end
  end

  function attack_icon:on_mouse_pressed(button, x, y)
    return attack_icon.hud_icon:on_mouse_pressed(button, x, y)
  end

  function attack_icon:on_mouse_released(button, x, y)
    return attack_icon.hud_icon:on_mouse_released(button, x, y)
  end

  function attack_icon:on_finger_pressed(finger, x, y, pressure)
    return attack_icon.hud_icon:on_finger_pressed(finger, x, y, pressure)
  end

  function attack_icon:on_finger_released(finger, x, y, pressure)
    return attack_icon.hud_icon:on_finger_released(finger, x, y, pressure)
  end

  -- Called when the menu is started.
  function attack_icon:on_started()
    attack_icon:update_effect_displayed(false)

    -- Check every 50ms if the icon needs a refresh.
    sol.timer.start(attack_icon, 50, function()
      attack_icon:update_effect_displayed(true)
      return true
    end)
  end

  -- Returns the menu.
  return attack_icon
end

return attack_icon_builder
