-- Script that creates a head-up display for a game.

-- Usage:
-- require("scripts/hud/hud")

require("scripts/multi_events")
local hud_config = require("scripts/hud/hud_config")

-- Creates and runs a HUD for the specified game.
local function initialize_hud_features(game)

  if game.set_hud_enabled ~= nil then
    -- If the initialization is already done, just display the HUD.
    game:set_hud_mode("normal")
    game:set_hud_enabled(true)
    return
  end

  -- Sets up the HUD.
  local hud = {
    enabled = false,
    elements = {},
    custom_command_effects = {},
  }

  -- For quicker and direct access to the icons.
  local item_icons = {}
  local action_icon
  local attack_icon
  local pause_icon
  local hearts
  local rupees
  local keys

  function set_menu_enabled(menu, enabled)
    if enabled then
      if not sol.menu.is_started(menu) then
        sol.menu.start(game, menu)
      end
    else
      sol.menu.stop(menu)
    end
  end

  -----------------------------------------------------------------------------
  -- Game functions.
  -----------------------------------------------------------------------------

  -- Returns the game's HUD.
  function game:get_hud()
    return hud
  end

  -- Returns whether the HUD is currently shown.
  function game:is_hud_enabled()
    return hud:is_enabled()
  end

  -- Enables or disables the HUD.
  function game:set_hud_enabled(enabled)
    return hud:set_enabled(enabled)
  end

  -- Returns the custom command effect for the command.
  function game:get_custom_command_effect(command)
    return hud.custom_command_effects[command]
  end

  -- Make the action (or attack) icon of the HUD show something else than the
  -- built-in effect or the action (or attack) command.
  -- You are responsible to override the command if you don't want the built-in
  -- effect to be performed.
  -- Set the effect to nil to show the built-in effect again.
  function game:set_custom_command_effect(command, effect)
    local old_command_effect = hud.custom_command_effects[command]
    hud.custom_command_effects[command] = effect
    if effect ~= old_command_effect then
      hud:adapt_to_curent_mode()
    end
  end

  -- Ensures the HUD is above everything.
  function game:bring_hud_to_front()
    if game.get_hud ~= nil then
      local hud = game:get_hud()
      if hud ~= nil then
        hud:bring_icons_to_front()
      end
    end
  end

  -- Sets the HUD mode.
  function game:set_hud_mode(mode)
    if game.get_hud ~= nil then
      local hud = game:get_hud()
      if hud ~= nil then
        hud:set_mode(mode)
      end
    end
  end

  -- Returns the HUD mode.
  function game:get_hud_mode()
    if game.get_hud ~= nil then
      local hud = game:get_hud()
      if hud ~= nil then
        return hud:get_mode()
      end
    end
    return nil
  end

  -- Enable or disable additionnal HUD info.
  -- Example: during cinematic, extra info should be hidden (hearts, rupees, etc.)
  function game:set_hud_additionnal_info_enabled(enabled)
    if game.get_hud ~= nil then
      local hud = game:get_hud()
      if hud ~= nil then
        hud:set_additionnal_info_enabled(enabled)
      end
    end
  end

 -----------------------------------------------------------------------------
  -- HUD functions.
  -----------------------------------------------------------------------------

  -- Destroys the HUD.
  function hud:quit()
    if hud:is_enabled() then
      -- Stop all HUD elements.
      hud:set_enabled(false)
    end
  end

  -- Call this function to notify the HUD that the current map has changed.
  local function hud_on_map_changed(game, map)
    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_map_changed ~= nil then
          menu:on_map_changed(map)
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just paused.
  local function hud_on_paused(game)
    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_paused ~= nil then
          menu:on_paused()
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just unpaused.
  local function hud_on_unpaused(game)
    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_unpaused ~= nil then
          menu:on_unpaused()
        end
      end
    end
  end

  -- Call this function to notify the HUD that a dialog was just started.
  local function hud_on_dialog_started(game, dialog, info)
    hud.backup_mode = hud:get_mode()
    hud:set_mode("dialog")

    -- if hud:is_enabled() then
    --   for _, menu in ipairs(hud.elements) do
    --     if menu.on_dialog_started ~= nil then
    --       menu:on_dialog_started()
    --     end
    --   end
    -- end
  end

  -- Call this function to notify the HUD that a dialog was just finished.
  local function hud_on_dialog_finished(game, dialog, info)
    local old_mode = hud.backup_mode ~= nil and hud.backup_mode or "normal"
    hud:set_mode(old_mode)
    hud.backup_mode = nil

    -- if hud:is_enabled() then
    --   for _, menu in ipairs(hud.elements) do
    --     if menu.on_dialog_finished ~= nil then
    --       menu:on_dialog_finished()
    --     end
    --   end
    -- end
  end

  local function hud_on_game_finished(game)
    -- Properly disable the HUD, otherwise it still thinks it is enabled
    -- after game over.
    hud:set_enabled(false)
  end

  -- Called periodically to change the transparency or position of icons.
  local function check_hud()
    if not hud:is_enabled() then
      return true
    end

    local map = game:get_map()
    if map ~= nil then
      local top_left_transparent = false
      local top_right_transparent = false

      -- Check if the hero is below the top-left icons, make them semi-transparent.
      if not game:is_suspended() then
        local hero = map:get_entity("hero")
        local hero_x, hero_y = hero:get_position()
        local camera_x, camera_y = map:get_camera():get_position()
        local x, y = hero_x - camera_x, hero_y - camera_y
        top_left_transparent = x < 92 and y < 72
        top_right_transparent = x > 224 and y < 40
      end

      -- Set the transparency on the icons.
      if action_icon then
        action_icon:set_transparent(top_left_transparent)
      end
      if attack_icon then
        attack_icon:set_transparent(top_left_transparent)
      end
      if pause_icon then
        pause_icon:set_transparent(top_left_transparent)
      end
      for _, item_icon in pairs(item_icons) do
        if item_icon then
          item_icon:set_transparent(top_left_transparent)
        end
      end

      -- Set the transparency on the hearts.
      if hearts then
        hearts:set_transparent(top_right_transparent)
      end
    end

    return true  -- Repeat the timer.
  end

  -- Returns the HUD current mode.
  function hud:get_mode()
    return hud.mode
  end

  -- Sets the mode of the HUD ("normal"-by default, "dialog", "pause", or "no_buttons").
  -- The icons adapt themselves to this mode.
  -- Ex: During a dialog, move the action icon and the sword icon, and hides the
  -- item icons.
  function hud:set_mode(mode)
    if mode == "normal" or mode == "dialog" or mode == "pause" or mode == "no_buttons" then
      hud.mode = mode
      hud:adapt_to_curent_mode()
    else
      print("HUD mode is not supported: "..mode)
      hud:set_mode("normal") --fallback
    end
  end

  -- Adapts the icons to the current mode.
  function hud:adapt_to_curent_mode()
    if hud.mode == "dialog" then
      if attack_icon ~= nil then
        attack_icon:set_dst_position(attack_icon:get_dialog_position())
        local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("attack") or game:get_command_effect("attack")
        attack_icon:set_enabled(effect ~= nil)
        attack_icon:set_active(true)
      end

      if action_icon ~= nil then
        action_icon:set_dst_position(action_icon:get_dialog_position())
        local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("action") or game:get_command_effect("action")
        action_icon:set_enabled(effect ~= nil)
        action_icon:set_active(true)
      end

      if pause_icon ~= nil then
        pause_icon:set_enabled(false)
        pause_icon:set_active(false)
      end

      for _, item_icon in ipairs(item_icons) do
        if item_icon ~= nil then
          item_icon:set_enabled(false)
          item_icon:set_active(false)
        end
      end
    elseif hud.mode == "pause" then
      if attack_icon ~= nil then
        attack_icon:set_dst_position(attack_icon:get_normal_position())
        local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("attack") or game:get_command_effect("attack")
        attack_icon:set_enabled(effect ~= nil)
        attack_icon:set_active(true)
      end

      if action_icon ~= nil then
        action_icon:set_dst_position(action_icon:get_normal_position())
        local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("action") or game:get_command_effect("action")
        action_icon:set_enabled(effect ~= nil)
        action_icon:set_active(true)
      end

      if pause_icon ~= nil then
        pause_icon:set_enabled(true)
        pause_icon:set_active(true)
      end

      for _, item_icon in ipairs(item_icons) do
        if item_icon ~= nil then
          item_icon:set_enabled(true)
          item_icon:set_active(false)
        end
      end
    elseif hud.mode == "normal" then
      if attack_icon ~= nil then
        attack_icon:set_dst_position(attack_icon:get_normal_position())
        local attack_icon_enabled = false
        local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("attack") or game:get_command_effect("attack")
        if effect then
          attack_icon_enabled = true
        else
          -- Still display the attack icon when the hero does not have a sword, at the beginning of the game.
          local hero_sword = game:get_ability("sword")
          attack_icon_enabled = hero_sword == nil or hero_sword == 0
        end
        attack_icon:set_enabled(attack_icon_enabled)
        attack_icon:set_active(true)
      end

      if action_icon ~= nil then
        action_icon:set_dst_position(action_icon:get_normal_position())
        local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("action") or game:get_command_effect("action")
        action_icon:set_enabled(effect ~= nil)
        action_icon:set_active(true)
      end

      if pause_icon ~= nil then
        pause_icon:set_enabled(true)
        pause_icon:set_active(true)
      end

      for _, item_icon in ipairs(item_icons) do
        if item_icon ~= nil then
          item_icon:set_enabled(true)
          item_icon:set_active(true)
        end
      end
    elseif hud.mode == "no_buttons" then
      if attack_icon ~= nil then
        attack_icon:set_dst_position(attack_icon:get_normal_position())
        attack_icon:set_enabled(false)
        attack_icon:set_active(false)
      end

      if action_icon ~= nil then
        action_icon:set_dst_position(action_icon:get_normal_position())
        action_icon:set_enabled(false)
        action_icon:set_active(false)
      end

      if pause_icon ~= nil then
        pause_icon:set_enabled(false)
        pause_icon:set_active(false)
      end

      for _, item_icon in ipairs(item_icons) do
        if item_icon ~= nil then
          item_icon:set_enabled(false)
          item_icon:set_active(false)
        end
      end
    end
  end

  -- Returns whether the HUD is currently enabled (i.e. visible).
  function hud:is_enabled()
    return hud.enabled
  end

  -- Enables or disables the HUD.
  function hud:set_enabled(enabled)
    if enabled ~= hud.enabled then
      hud.enabled = enabled

      -- Start or stop each element.
      for _, menu in ipairs(hud.elements) do
        set_menu_enabled(menu, enabled)
      end

      -- Bring to front.
      if enabled then
        hud:bring_to_front()
      end
    end
  end

  -- Changes the opacity of an item icon
  -- Active means full opacity, and not active means half opacity.
  function hud:set_item_icon_active(item_index, is_active)
    item_icons[item_index].set_active(is_active)
  end

  -- Returns the opacity of an item icon
  -- Active means full opacity, and not active means half opacity.
  function hud:is_item_icon_active(item_index)
    return item_icons[item_index].is_active()
  end

  -- Sets if the command icon is active or not.
  function hud:set_command_icon_active(command, is_active)
    if command == "attack" then
      attack_icon:set_active(is_active)
    elseif command == "action" then
      action_icon:set_active(is_active)
    elseif command == "pause" then
      pause_icon:set_active(is_active)
    elseif command == "item_1" then
      hud:set_item_icon_active(1, is_active)
    elseif command == "item_2" then
      hud:set_item_icon_active(2, is_active)
    end
  end

  -- Returns if the command icon is active or not.
  function hud:is_command_icon_active(command)
    if command == "attack" then
      return attack_icon:is_active()
    elseif command == "action" then
      return action_icon:is_active()
    elseif command == "pause" then
      return pause_icon:is_active()
    elseif command == "item_1" then
      return hud:is_item_icon_active(1)
    elseif command == "item_2" then
      return hud:is_item_icon_active(2)
    else
      return false
    end
  end

  -- Sets the additionnal info (hearts, rupees, keys) enabled or not.
  function hud:set_additionnal_info_enabled(enabled)
    hud:set_hearts_enabled(enabled)
    hud:set_rupees_enabled(enabled)
    hud:set_keys_enabled(enabled)
  end

  -- Enables or disables the life counter.
  function hud:set_hearts_enabled(enabled)
    if hearts then
      set_menu_enabled(hearts, enabled)
    end
  end

  -- Enables or disables the life counter.
  function hud:set_rupees_enabled(enabled)
    if rupees then
      set_menu_enabled(rupees, enabled)
    end
  end

  -- Enables or disables the life counter.
  function hud:set_keys_enabled(enabled)
    if keys then
      set_menu_enabled(keys, enabled)
    end
  end

  -- Brings the whole HUD to the front.
  function hud:bring_to_front()
    for _, menu in ipairs(hud.elements) do
      sol.menu.bring_to_front(menu)
    end
  end

  -- Brings only the icons of the HUD to the front.
  function hud:bring_icons_to_front()
    if attack_icon then
      sol.menu.bring_to_front(attack_icon)
    end
    if action_icon then
      sol.menu.bring_to_front(action_icon)
    end
    if pause_icon then
      sol.menu.bring_to_front(pause_icon)
    end
    for _, item_icon in ipairs(item_icons) do
      if item_icon then
        sol.menu.bring_to_front(item_icon)
      end
    end
  end

  -- Retrieves the elements and stores them for quicker access.
  for _, element_config in ipairs(hud_config) do
    local element_builder = require(element_config.menu_script)
    local element = element_builder:new(game, element_config)
    if element.set_dst_position ~= nil then
      -- Compatibility with old HUD element scripts
      -- whose new() method does not take a config parameter.
      element:set_dst_position(element_config.x, element_config.y)
    end
    hud.elements[#hud.elements + 1] = element

    if element_config.menu_script == "scripts/hud/item_icon" then
      item_icons[element_config.slot] = element
    elseif element_config.menu_script == "scripts/hud/action_icon" then
      action_icon = element
      -- Reacts to a change in the effect displayed by the icon.
      function action_icon:on_command_effect_changed(effect)
        action_icon:set_enabled(hud:get_mode() ~= "no_buttons" and effect ~= nil)
      end
    elseif element_config.menu_script == "scripts/hud/attack_icon" then
      attack_icon = element
      -- Reacts to a change in the effect displayed by the icon.
      function attack_icon:on_command_effect_changed(effect)
        attack_icon:set_enabled(hud:get_mode() ~= "no_buttons" and effect ~= nil)
      end
    elseif element_config.menu_script == "scripts/hud/pause_icon" then
      pause_icon = element
    elseif element_config.menu_script == "scripts/hud/hearts" then
      hearts = element
    elseif element_config.menu_script == "scripts/hud/small_keys" then
      keys = element
    elseif element_config.menu_script == "scripts/hud/rupees" then
      rupees = element
    end
  end

  -- Listens to the events on game, and reacts accordingly.
  game:register_event("on_map_changed", hud_on_map_changed)
  game:register_event("on_paused", hud_on_paused)
  game:register_event("on_unpaused", hud_on_unpaused)
  game:register_event("on_finished", hud_on_game_finished)
  --game:register_event("on_dialog_started", hud_on_dialog_started)
  --game:register_event("on_dialog_finished", hud_on_dialog_finished)

  -- Start the HUD.
  hud:set_enabled(true)
  hud:set_mode("normal")
  sol.timer.start(game, 50, check_hud) -- TODO
end

-- Set up the HUD features on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_hud_features)

return true
